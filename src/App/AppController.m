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
            obj.View.fwdRunSimCallbackView = @() obj.handleRunSimCallback();
            obj.View.fwdSignalBuilderCallbackView = @() obj.handleSignalBuilderCallback();
            obj.View.fwdSaveOutputCallback = @() obj.handleSaveOutputCallback();
        end

        function handleRunSimCallback(obj)
            obj.Model.startSimulation();
        end

        function handleSignalBuilderCallback(obj)
            sim_input  = SignalBuilderApp();

            % if ~isempty(sim_input)
            
        end
    end
end