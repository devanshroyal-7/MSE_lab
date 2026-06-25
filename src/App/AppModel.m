classdef AppModel < handle

    % Public properties that correspond to the Simulink model
    properties (Access = public, Transient)
        Simulation simulink.Simulation
    end

    methods (Access = public)

        % Associate the Simulink Model
        app.Simulation = simulation('MSE_PLANT');
    end

end