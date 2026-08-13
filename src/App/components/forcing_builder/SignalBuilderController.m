classdef SignalBuilderController < handle
    % Wires SignalBuilderView events to SignalBuilderModel and keeps the plot
    % in sync (single signal vs superimposed overall).
    %
    %{
    Example usage:

    >> fig = uifigure("Name", "Forcing Function Builder", "Position", [500, 500, 940, 630]);
    >> model = SignalBuilderModel;
    >> view = SignalBuilderView(fig);
    >> controller = SignalBuilderController(model, view);
    >> uiwait(fig);                   % or call SignalBuilderApp instead

    %}

    properties
        Model
        View
        
        ModelListeners  = event.listener.empty();
        ViewListeners   = event.listener.empty();

        IsFinished = false;     % tracks if signal building is finished
    end

    methods
        function obj = SignalBuilderController(model, view)
            obj.Model = model;
            obj.View = view;

            obj.ModelListeners = addlistener(obj.Model, 'DataUpdated', @(~, ~) obj.handleModelUpdated);
            % obj.ViewListeners = addlistener(obj.View, 'ViewUpdated', @(~, ~) obj.handleViewUpdated);

            obj.View.AddCallbackView = @(value) obj.handleAddCallback(value);
            obj.View.RemoveCallbackView = @(idx) obj.handleRemoveCallback(idx);
            obj.View.SelectAvailableCallbackView = @(value) obj.handleSelectAvailableCallback(value);
            obj.View.SelectOverallCallbackView = @(idx, swapFlag) obj.handleSelectOverallCallback(idx, swapFlag);
            obj.View.ValueChangedCallbackView = @() obj.handleValueChangedCallback();
            obj.View.ViewSwitchCallbackView = @() obj.handleViewSwitchChangedCallback();
            obj.View.FinishCallbackView = @() obj.handleFinishCallback();
            obj.syncViewToModel();
        end

        function syncViewToModel(obj)
            signalNames = string.empty;

            for i1 = 1:length(obj.Model.Signals)
                signalNames(i1) = obj.Model.Signals{i1}.Name;
            end

            obj.View.OverallListWidget.OverallListBox.Items = signalNames;
            
            viewMode = obj.View.OverallListWidget.ViewSwitch.Value;
            overallMode = obj.View.OverallListWidget.OverallMode;

            if strcmp(overallMode, 'available')
                tempSignal = obj.View.getActiveSignal();
                [t, y] = obj.Model.evaluateSignal(tempSignal);
                obj.View.updatePlot(t, y);
                return;
            end

            if isempty(obj.Model.Signals)
                obj.View.updatePlot([], []);
                return;
            end

            % re-evaluate total signals and time
            if strcmp(viewMode, 'Single')
                selectedSigIdx = obj.View.OverallListWidget.OverallListBox.ValueIndex;

                if isempty(selectedSigIdx) || selectedSigIdx < 1 || selectedSigIdx > length(obj.Model.Signals)
                    selectedSigIdx = 1;
                    obj.View.OverallListWidget.OverallListBox.ValueIndex = 1;
                end

                [t, y] = obj.Model.evaluateIndividualSignal(selectedSigIdx);
            else
                [t, y] = obj.Model.compileCompositeSignal();
            end


            obj.View.updatePlot(t, y);
        end

        function handleAddCallback(obj, selectedSignal)
            if obj.View.ActivePanelName ~= string(selectedSignal)
                obj.View.swapActivePanel(selectedSignal)
            end

            newSignal = obj.View.getActiveSignal();

            if ~isempty(newSignal)
                obj.Model.addSignal(newSignal);
            end
        end

        function handleRemoveCallback(obj, idx)
            obj.Model.removeSignal(idx)

            if ~isempty(obj.Model.Signals)
                selectedSignal = obj.Model.Signals{1}.Name;

                if obj.View.ActivePanelName ~= string(selectedSignal)
                    obj.View.swapActivePanel(selectedSignal);
                end

                obj.View.populateActivePanel(obj.Model.Signals{1});
                obj.syncViewToModel();
            else
                obj.resetToInitState();
            end
            
        end

        function handleSelectAvailableCallback(obj, signalName)
            obj.View.swapActivePanel(signalName);

            obj.syncViewToModel();
        end

        function handleSelectOverallCallback(obj, idx, swapFlag)
            signalName = obj.Model.Signals{idx}.Name;
            if swapFlag
                obj.View.swapActivePanel(signalName);
            end

            obj.View.populateActivePanel(obj.Model.Signals{idx})
            
            obj.syncViewToModel();
        end

        function handleValueChangedCallback(obj)
            % Live-edit: replace the selected stacked signal with the panel's current values.
            if strcmp(obj.View.OverallListWidget.OverallMode, 'overall')
                updatedSignal = obj.View.getActiveSignal();
                
                selectedIdx = obj.View.OverallListWidget.OverallListBox.ValueIndex;

                obj.Model.Signals{selectedIdx} = updatedSignal;
            end

            obj.syncViewToModel();
        end

        function handleViewSwitchChangedCallback(obj)
            obj.syncViewToModel();
        end

        function handleFinishCallback(obj)
            obj.IsFinished = true;

            uiresume(obj.View.UIFigure)   % unblocks SignalBuilderApp's uiwait
        end

        function resetToInitState(obj)
            obj.Model.resetModel();

            obj.View.resetView();

            obj.syncViewToModel();
        end
    end

    methods (Access = private)
        function handleModelUpdated(obj)
            obj.syncViewToModel();
        end
    end
end