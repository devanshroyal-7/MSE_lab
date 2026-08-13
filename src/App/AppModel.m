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
        end

        function setForcingInput(obj, tsInput)
            obj.ForcingSignal = tsInput;
            obj.S = tsInput.Time(end);

            % MSE_PLANT From Workspace / Gain blocks read these from 'base'
            assignin('base', 'sim_input', tsInput);
            assignin('base', 'k_sim', obj.k_sim);
            assignin('base', 'b_sim', obj.b_sim);

            set_param(obj.SimulationModelName, 'StopTime', num2str(obj.S));
        end

        function startSimulation(obj)
            % clear up buffer
            obj.TimeBuffer = [];
            obj.PositionBuffer = [];
            obj.VelocityBuffer = [];
            
            % Desktop Real-Time / external mode; plant reads sim_input from base
            set_param(obj.SimulationModelName, 'SimulationMode', 'external');
            
            set_param(obj.SimulationModelName, 'SimulaitonCommand', 'start');
        end
    end
end