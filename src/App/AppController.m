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
            obj.View.fwdSaveOutputCallbackView = @() obj.handleSaveOutputCallback();
        end

        function handleRunSimCallback(obj)
            obj.Model.startSimulation();
        end

        function handleSignalBuilderCallback(obj)
            sim_input  = SignalBuilderApp();

            if ~isempty(sim_input) && isa(sim_input, 'timeseries') && sim_input.Length > 0
                obj.Model.setForcingInput(sim_input);
                stopTime = sim_input.Time(end);
                
                obj.View.updateReferencePlot(sim_input)

                fprintf('Forcing signal successfully set. Duration %.2f seconds.\n', stopTime);
            else
                fprintf('Signal Builder closed without saving changes.\n');
            end
            
        end

        function handleSaveOutputCallback(obj)
            % obj
        end
    end
end