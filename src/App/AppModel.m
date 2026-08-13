classdef AppModel < handle
    % Application model: loads MSE_PLANT and feeds forcing / sim parameters
    % into the MATLAB base workspace so Desktop Real-Time can read them.
    %
    %{
    Example usage:

    >> ts = SignalBuilderApp;             % or timeseries(y, t) from a model
    >> model = AppModel;                  % load_system('MSE_PLANT')
    >> model.setForcingInput(ts);         % also sets StopTime and sim_input
    >> model.startSimulation;             % external (SLDRT) mode

    %}

    % Public properties that correspond to the Simulink model
    properties (Access = public, Transient)
        Simulation 
        T (1,1) double {mustBeFloat} = 0.001;

    end

    properties (Constant, Access = protected)
        % Hardware parameters
        r           (1,1) double = 0.01;  % pinion gear radius [m]
        Kt          (1,1) double = 0.028; % torque constant [Nm/A]
        motor_eff   (1,1) double = 1.0;   % system efficiency       
    end

    properties (Access = public)
        % Simulation parameters
        k_sim       (1,1) double = 0;   % simulated stiffness   [N/m]
        b_sim       (1,1) double = 0;   % simulated damping     [Ns/m]

        % Simulation control and configuration
        SimulationModelName (1,1) string = "MSE_PLANT";
        RunTimeout (1,1) double = 30;   % [s] hard cap so the UI cannot deadlock
        
        S   (1,1) double {mustBeNumeric} = 10;  % simulation time   [s]
        TimeBuffer      (1,:) double = [];
        PositionBuffer  (1,:) double = [];
        VelocityBuffer  (1,:) double = [];
        ForcingSignal           % timeseries object from SignalBuilder

        % External-mode upload buffer (samples). At T=0.001 this is 0.25 s.
        % Keep this much smaller than the run so Scopes/SDI update during
        % the run. To Workspace still dumps the full record at stop.
        LiveBufferSamples (1,1) double = 250;
    end

    events 
        DataUpdated
    end
        

    methods (Access = public)
        function obj = AppModel()
            % Load "MSE_Plant" simulink model
            if ~bdIsLoaded(obj.SimulationModelName)
                load_system(obj.SimulationModelName)
            end
            % MSE_PLANT reads hardware conversion constants from 'base'
            assignin('base', "T", obj.T);
            assignin('base', "r", obj.r);
            assignin('base', "Kt", obj.Kt);
            assignin('base', "motor_eff", obj.motor_eff);
        end

        function setForcingInput(obj, tsInput)
            obj.ForcingSignal = tsInput;
            obj.S = tsInput.Time(end);

            % MSE_PLANT From Workspace / Gain blocks read these from 'base'
            assignin('base', 'sim_input', tsInput);
            assignin('base', 'k_sim', obj.k_sim);
            assignin('base', 'b_sim', obj.b_sim);

            set_param(obj.SimulationModelName, 'StopTime', num2str(obj.S));

            drawnow;
        end

        function prepareLiveStreaming(obj)
            % SLDRT Run in Kernel does not write To Workspace until stop.
            % Live traces come from external-mode buffers (sldrtext) into
            % Scope / Simulation Data Inspector. Duration is the buffer
            % length; Mode normal rearms so buffers keep uploading.
            % Changing these does not require a rebuild.
            modelName = char(obj.SimulationModelName);
            if ~bdIsLoaded(modelName)
                load_system(modelName);
            end

            set_param(modelName, 'ExtModeArmWhenConnect', 'on');
            set_param(modelName, 'ExtModeTrigMode', 'normal');
            set_param(modelName, 'ExtModeTrigDuration', ...
                num2str(obj.LiveBufferSamples));

            daqBlk = find_system(modelName, 'SearchDepth', 1, ...
                'Regexp', 'on', 'Name', '^EMB');
            if ~isempty(daqBlk)
                if iscell(daqBlk)
                    daqBlk = daqBlk{1};
                end
                Simulink.sdi.markSignalForStreaming(daqBlk, 3, 'on');
            end
        end

        function [t, y] = getLiveCart1Position(obj)
            % Latest Cart 1 position streamed to SDI. Empty until the first
            % external-mode buffer has been uploaded.
            t = [];
            y = [];
            try
                runObj = Simulink.sdi.getCurrentSimulationRun( ...
                    char(obj.SimulationModelName));
                if isempty(runObj)
                    return;
                end

                sigs = runObj.getAllSignals();
                for i = 1:numel(sigs)
                    name = char(sigs(i).Name);
                    if contains(name, 'Cart1-Position', 'IgnoreCase', true)
                        [t, y] = AppModel.signalValuesToXY(sigs(i).Values);
                        return;
                    end
                end
            catch
            end
        end

        function connectTarget(obj)
            % Stop any leftover kernel app, rebuild so checksums match, then
            % connect without starting the run.
            modelName = char(obj.SimulationModelName);
            % 
            % if bdIsLoaded(modelName)
            %     try
            %         set_param(modelName, 'SimulationCommand', 'stop');
            %     catch
            %     end
            % end

            set_param(modelName, 'SimulationMode', 'external');

            try
                slbuild(modelName);
                % set_param(modelName, 'SimulationCommand', 'connect');
            catch
                rtwbuild(modelName);
                % obj.rebuildTarget(modelName);
                % set_param(modelName, 'SimulationCommand', 'connect');
            end

            set_param(modelName, 'SimulationCommand', 'connect');
        end

        function startSimulation(obj)
            % clear up buffer
            obj.TimeBuffer = [];
            obj.PositionBuffer = [];
            obj.VelocityBuffer = [];

            set_param(obj.SimulationModelName, 'SimulationCommand', 'start');
        end

        function stopSimulation(obj)
            if bdIsLoaded(obj.SimulationModelName)
                set_param(obj.SimulationModelName, 'SimulationCommand', 'stop');
            end
        end

        function run = collectRunData(obj)
            names = [ ...
                "rt_time", "f_input", ...
                "cart1_position", "cart2_position", ...
                "cart1_velocity", "cart2_velocity", ...
                "sim_input", "k_sim", "b_sim", ...
                "T", "r", "Kt", "motor_eff"];

            run = struct();
            run.saved_at = datetime("now");

            for i = 1:numel(names)
                name = char(names(i));
                if evalin('base', ['exist(''' name ''', ''var'')'])
                    run.(name) = evalin('base', name);
                end
            end
        end

        function status = getSimulationStatus(obj)
            if bdIsLoaded(obj.SimulationModelName)
                status = get_param(obj.SimulationModelName, 'SimulationStatus');
            else
                status = 'stopped';
            end
        end

        function isRunning = isSimulationRunning(obj)
            status = obj.getSimulationStatus();
            isRunning = strcmp(status, 'running') || strcmp(status, 'external');
        end
    end

    methods (Access = private)
        function rebuildTarget(~, modelName)
            try
                slbuild(modelName);
            catch
                rtwbuild(modelName);
            end
        end
    end

    methods (Static, Access = private)
        function [t, y] = signalValuesToXY(vals)
            t = [];
            y = [];
            if isa(vals, 'timeseries')
                t = vals.Time(:);
                y = squeeze(vals.Data);
                y = y(:);
            elseif istimetable(vals)
                t = seconds(vals.Time);
                t = t(:);
                y = vals{:, 1};
                y = y(:);
            end
            n = min(numel(t), numel(y));
            t = t(1:n);
            y = y(1:n);
        end
    end
end