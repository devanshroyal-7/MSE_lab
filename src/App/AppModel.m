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
        function rebuildTarget(obj, modelName)
            try
                slbuild(modelName);
            catch
                rtwbuild(modelName);
            end
        end
    end
end