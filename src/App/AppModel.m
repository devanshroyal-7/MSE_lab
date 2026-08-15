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
        RunTimeout (1,1) double = 30;   % [s] connect/start hang cap (not run length)
        
        S   (1,1) double {mustBeNumeric} = 10;  % simulation time   [s]
        TimeBuffer      (1,:) double = [];
        PositionBuffer  (1,:) double = [];
        VelocityBuffer  (1,:) double = [];
        ForcingSignal           % timeseries object from SignalBuilder

        % External-mode upload buffer (samples). At T=0.001 this is 0.05 s.
        LiveBufferSamples (1,1) double = 50;
    end

    properties (Access = private)
        LiveArmed (1,1) logical = false
        StaleSdiRunId = []
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
<<<<<<< HEAD
        end

        function prepareLiveStreaming(obj)
            % SLDRT Run in Kernel uploads Duration-sized buffers. By default
            % only the last buffer is written to the workspace, which is why
            % the response plot showed a blip at t=end. Write every buffer,
            % rearm, and apply this AFTER slbuild so the .slx Duration (20480)
            % does not win.
            modelName = char(obj.SimulationModelName);
            if ~bdIsLoaded(modelName)
                load_system(modelName);
            end

            set_param(modelName, 'ExtModeArmWhenConnect', 'on');
            set_param(modelName, 'ExtModeTrigType', 'manual');
            set_param(modelName, 'ExtModeTrigMode', 'normal');
            set_param(modelName, 'ExtModeTrigDuration', ...
                num2str(obj.LiveBufferSamples));
            set_param(modelName, 'ExtModeLogAll', 'on');
            set_param(modelName, 'ExtModeWriteAllDataToWs', 'on');

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
            obj.captureLiveCart1Chunk();
            t = obj.TimeBuffer(:);
            y = obj.PositionBuffer(:);
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
            catch
                rtwbuild(modelName);
            end

            obj.prepareLiveStreaming();
            set_param(modelName, 'SimulationCommand', 'connect');
=======
>>>>>>> origin/main
        end

        function startSimulation(obj)
            obj.TimeBuffer = [];
            obj.PositionBuffer = [];
            obj.VelocityBuffer = [];
<<<<<<< HEAD
            obj.LiveArmed = false;
            obj.StaleSdiRunId = obj.currentSdiRunId();

            set_param(obj.SimulationModelName, 'SimulationCommand', 'start');
            try
                set_param(char(obj.SimulationModelName), ...
                    'ExtModeCommand', 'armWired');
            catch
            end
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
=======
            
            % Desktop Real-Time / external mode; plant reads sim_input from base
            set_param(obj.SimulationModelName, 'SimulationMode', 'external');
            
            set_param(obj.SimulationModelName, 'SimulationCommand', 'start');
>>>>>>> origin/main
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
<<<<<<< HEAD
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

        function captureLiveCart1Chunk(obj)
            [t, y] = obj.readWorkspaceCart1();
            obj.appendLiveChunk(t, y);
            [t, y] = obj.readSdiCart1();
            obj.appendLiveChunk(t, y);
        end

        function [t, y] = readWorkspaceCart1(obj)
            t = [];
            y = [];
            try
                if ~evalin('base', "exist('cart1_position', 'var')")
                    return;
                end
                raw = evalin('base', 'cart1_position');
                [t, y] = AppModel.signalValuesToXY(raw);
                if isempty(t) && evalin('base', "exist('rt_time', 'var')")
                    t = squeeze(evalin('base', 'rt_time'));
                    t = t(:);
                    y = y(:);
                    n = min(numel(t), numel(y));
                    t = t(1:n);
                    y = y(1:n);
                end
            catch
            end
        end

        function id = currentSdiRunId(obj)
            id = [];
            try
                runObj = Simulink.sdi.getCurrentSimulationRun( ...
                    char(obj.SimulationModelName));
                if ~isempty(runObj)
                    id = runObj.id;
                end
            catch
            end
        end

        function [t, y] = readSdiCart1(obj)
            t = [];
            y = [];
            try
                runObj = Simulink.sdi.getCurrentSimulationRun( ...
                    char(obj.SimulationModelName));
                if isempty(runObj)
                    return;
                end
                if ~isempty(obj.StaleSdiRunId) && isequal(runObj.id, obj.StaleSdiRunId)
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

        function appendLiveChunk(obj, t, y)
            if isempty(t) || isempty(y)
                return;
            end
            t = t(:)';
            y = y(:)';
            n = min(numel(t), numel(y));
            t = t(1:n);
            y = y(1:n);

            % Workspace/SDI still hold the previous run's last buffer, whose
            % timestamps are near the old StopTime. If we accept that as the
            % start of this run, new samples at t≈0 are dropped until they
            % catch up. Wait for a buffer that starts near t=0.
            if ~obj.LiveArmed
                maxStart = max(1.0, 4 * obj.LiveBufferSamples * obj.T);
                if t(1) <= maxStart
                    obj.LiveArmed = true;
                    obj.TimeBuffer = t;
                    obj.PositionBuffer = y;
                end
                return;
            end

            mask = t > obj.TimeBuffer(end) + (obj.T / 2);
            if any(mask)
                obj.TimeBuffer = [obj.TimeBuffer, t(mask)];
                obj.PositionBuffer = [obj.PositionBuffer, y(mask)];
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
            elseif isstruct(vals) && isfield(vals, 'time') && isfield(vals, 'signals')
                t = vals.time(:);
                y = squeeze(vals.signals(1).values);
                y = y(:);
            elseif isnumeric(vals)
                y = squeeze(vals);
                y = y(:);
            end
            if ~isempty(t) && ~isempty(y)
                n = min(numel(t), numel(y));
                t = t(1:n);
                y = y(1:n);
            end
=======
>>>>>>> origin/main
        end
    end
end