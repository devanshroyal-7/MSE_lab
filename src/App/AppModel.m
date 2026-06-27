classdef AppModel < handle

    % Public properties that correspond to the Simulink model
    properties (Access = public, Transient)
        Simulation simulink.Simulation
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
    end

    properties (Access = protected)
        S   (1,1) double {mustBeNumeric} = 10;  % simulation time   [s]
        t   (1,:) double {mustBeFloat} = [];    % time vector       [s]
    end
        

    methods (Access = public)

        % Associate the Simulink Model
        app.Simulation = simulation('MSE_PLANT');
        
    end

end