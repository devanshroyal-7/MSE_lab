classdef AppController < handle
    properties
        Model
        View

    end

    methods 
        function obj = AppController(model, view)
            obj.Model = model;
            obj.View = view;

            % Callback
            obj.View.fwdRunSimCallback = @() handleRunSimCallback();
        end

        function handleRunSimCallback();
            
        end
    end
end