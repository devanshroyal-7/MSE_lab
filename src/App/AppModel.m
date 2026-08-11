classdef AppModel < handle

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
            assignin('base', "T", obj.T);
            assignin('base', "r", obj.r);
            assignin('base', "Kt", obj.Kt);
            assignin('base', "motor_eff", obj.motor_eff);
        end

        function setForcingInput(obj, tsInput)
            obj.ForcingSignal = tsInput;
            obj.S = tsInput.Time(end);

            % push to base workspace
            assignin('base', 'sim_input', tsInput);
            assignin('base', 'k_sim', obj.k_sim);
            assignin('base', 'b_sim', obj.b_sim);

            set_param(obj.SimulationModelName, 'StopTime', num2str(obj.S));

            drawnow;
        end

        function startSimulation(obj)
            % clear up buffer
            obj.TimeBuffer = [];
            obj.PositionBuffer = [];
            obj.VelocityBuffer = [];
            
            % set simulation mode to slrdt
            set_param(obj.SimulationModelName, 'SimulationMode', 'external');
            
            set_param(obj.SimulationModelName, 'SimulationCommand', 'start');
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
end