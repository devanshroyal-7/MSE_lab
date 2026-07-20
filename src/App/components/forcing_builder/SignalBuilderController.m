classdef SignalBuilderController < handle
    properties
        Model
        View
        
        ModelListeners  = event.listener.empty();
        ViewListeners   = event.listener.empty();
    end

    methods
        function obj = SignalBuilderController(model, view)
            obj.Model = model;
            obj.View = view;

            obj.ModelListeners = addlistener(obj.Model, 'DataUpdated', @(~, ~) obj.handleModelUpdated);
            % obj.ViewListeners = addlistener(obj.View, 'ViewUpdated', @(~, ~) obj.handleViewUpdated);

            obj.View.AddSignalCallbackView = @(value) obj.handleAddCallback(value);
            obj.View.RemoveSignalCallbackView = @(idx) obj.handleRemoveCallback(idx);
            obj.View.SelectAvailableCallbackView = @(value) obj.handleSelectAvailableCallback(value);
            obj.View.SelectOverallCallbackView = @(idx) obj.handleSelectOverallCallback(idx);
        end

        function syncViewToModel(obj)
            signalNames = string.empty;

            for i1 = 1:length(obj.Model.Signals)
                signalNames(i1) = obj.Model.Signals{i1}.Name;
            end

            obj.View.OverallListWidget.OverallListBox.Items = signalNames;
            
            viewMode = obj.View.OverallListWidget.ViewSwitch.Value;

            % re-evaluate total signals and time
            if strcmp(viewMode, 'Single')
                selectedSigIdx = obj.View.OverallListWidget.OverallListBox.ValueIndex;
                [t, y] = obj.Model.evaluateIndividualSignal(selectedSigIdx);
            else
                [t, y] = obj.Model.compileCompositeSignal();
            end

            obj.View.updatePlot(t, y);
        end

        function handleAddCallback(obj, selectedSignal)
            switch selectedSignal
                case 'Custom'
                    equation = obj.View.ActiveSetupPanel.CustomEditField.Value;
                    duration = obj.View.ActiveSetupPanel.DurationEditField.Value;
    
                    obj.Model.addSignal(CustomSignal(equation, duration));
                    
                    % command line version of updating the overallListbox: 
                    % view.OverallListWidget.OverallListBox.Items = [view.OverallListWidget.OverallListBox.Items, view.OverallListWidget.AvailableListBox.Value]
            end

        end

        function handleRemoveCallback(obj, idx)

        end

        function handleSelectAvailableCallback(obj, idx)

        end

        function handleSelectOverallCallback(obj, idx)

        end
    end

    

    methods (Access = private)
        function handleModelUpdated(obj)
            obj.syncViewToModel();
        end
    end
end