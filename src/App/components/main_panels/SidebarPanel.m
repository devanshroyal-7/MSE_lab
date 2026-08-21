classdef SidebarPanel < handle
    % Right-hand controls: SLDRT start/stop, cart plot toggles, k_sim / c_sim,
    % runs-to-average, open/closed loop, PID gains, Create Forcing Function,
    % and Save Outputs. Start and Create Forcing Function forward to AppView;
    % k/c and the simulated-parameter enable forward into AppModel.
    %
    %{
    Example usage:

    >> fig = uifigure("Position", [100, 100, 320, 640]); panel = SidebarPanel(fig);
    >> panel.KSimEditField.Value = 200;
    >> panel.fwdRunSignalCallback = @() disp("start");

    %}

    properties
        MainLayoutGrid
        
        SimStartButton
        SimStopButton
        
        KSimEditField
        BSimEditField
        EnableSimParamButton

        PlotCart1CheckBox
        PlotCart2CheckBox

        RunsToAverageLabel
        RunsToAverageEditField
        EnableAverageRunsButton

        ControlParamPanel
        ControlModePanel
        LoopModeGroup
        OpenLoopRadio
        ClosedLoopRadio
        KpEditField
        KiEditField
        KdEditField
        EnableControlsButton

        CreateFcnButton
        SaveOutputButton
        SimLamp

        % Fwd Callbacks
        fwdRunSignalCallback
        fwdStopSignalCallback

        fwdSignalBuilderCallback
        fwdSaveOutputCallback
        fwdEnableControlsCallback
        fwdSimParamsChangedCallback
        fwdControlParamsChangedCallback
        fwdAverageRunsChangedCallback
        fwdPlotCartsChangedCallback
    end

    methods
        function obj = SidebarPanel(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [22, 4]);
            obj.MainLayoutGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
            obj.MainLayoutGrid.RowHeight = {30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, '1x', 30};

            %%% Real-time Simulation Controls %%%
            SimControlLabel = uilabel(obj.MainLayoutGrid, ...
                "Text", "Simulation Controls", ...
                "FontWeight", "bold", ...
                "FontSize", 15);
            SimControlLabel.Layout.Column = [1, 2];
            SimControlLabel.Layout.Row = 1;

            padSimLamp = uigridlayout(obj.MainLayoutGrid, [1, 4]);
            padSimLamp.Padding = [0, 0, 0, 0];
            padSimLamp.Layout.Row = 1;
            padSimLamp.Layout.Column = [3, 4];
            
            simLable = uilabel(padSimLamp, ...
                "Text", "Simulation Status", ...
                "HorizontalAlignment", 'right');
            simLable.Layout.Column = [1, 3];

            obj.SimLamp = uilamp(padSimLamp, "Color", [0 1 0]);
            obj.SimLamp.Layout.Column = 4;

            % Start Simulation
            obj.SimStartButton = uibutton(obj.MainLayoutGrid, ...
                "Text", "Start Simulation", ...
                "Icon","sim_start.png", ...
                "IconAlignment","top", ...
                "ButtonPushedFcn", @(~,~) obj.runSimCallback);
            obj.SimStartButton.Layout.Column = [1, 2];
            obj.SimStartButton.Layout.Row = [2, 3];

            % Stop Simulation
            obj.SimStopButton = uibutton(obj.MainLayoutGrid, ...
                "Text", "Stop Simulation", ...
                "Icon", "sim_stop.png", ...
                "IconAlignment","top", ...
                "ButtonPushedFcn", @(~,~) obj.stopSimCallback);
            obj.SimStopButton.Layout.Column = [3, 4];
            obj.SimStopButton.Layout.Row = [2, 3];

            %%% Plot Controls %%%
            PlotControlsPanel = uipanel(obj.MainLayoutGrid, ...
                "Title", "Plot Controls", ...
                "FontWeight", "bold");
            PlotControlsPanel.Layout.Column = [1, 4];
            PlotControlsPanel.Layout.Row = [4, 5];

            PlotControlsGrid = uigridlayout(PlotControlsPanel, [1, 2]);

            obj.PlotCart1CheckBox = uicheckbox(PlotControlsGrid, ...
                "Text", "Cart 1", ...
                "Value", true, ...
                "ValueChangedFcn", @(~, ~) obj.plotCartsChanged());
            obj.PlotCart1CheckBox.Layout.Column = 1;

            obj.PlotCart2CheckBox = uicheckbox(PlotControlsGrid, ...
                "Text", "Cart 2", ...
                "Value", false, ...
                "ValueChangedFcn", @(~, ~) obj.plotCartsChanged());
            obj.PlotCart2CheckBox.Layout.Column = 2;

            %%% Simulated Parameters %%%
            SimulatedParamsPanel = uipanel(obj.MainLayoutGrid, ...
                "Title", "Simulated Parameters", ...
                "FontWeight", "bold");
            SimulatedParamsPanel.Layout.Column = [1, 4];
            SimulatedParamsPanel.Layout.Row = [6, 9];

            SimParamGrid = uigridlayout(SimulatedParamsPanel, [3, 2]);

            KSimLabel = uilabel(SimParamGrid, ...
                "Text", "$$\mathbf{k_{simulated}} \ (N/m)$$");
            KSimLabel.Interpreter = 'latex';
            KSimLabel.Layout.Column = 1;
            KSimLabel.Layout.Row = 1;

            obj.KSimEditField = uieditfield(SimParamGrid, 'numeric');
            obj.KSimEditField.Value = 0;
            obj.KSimEditField.ValueChangedFcn = @(~, ~) obj.simParamsChanged();
            obj.KSimEditField.Layout.Column = 2;
            obj.KSimEditField.Layout.Row = 1;

            BSimLabel = uilabel(SimParamGrid, ...
                "Text", "$$\mathbf{c_{simulated}} \ (Ns/m)");
            BSimLabel.Interpreter = 'latex';
            BSimLabel.Layout.Column = 1;
            BSimLabel.Layout.Row = 2;

            obj.BSimEditField = uieditfield(SimParamGrid, 'numeric');
            obj.BSimEditField.Value = 0;
            obj.BSimEditField.ValueChangedFcn = @(~, ~) obj.simParamsChanged();
            obj.BSimEditField.Layout.Column = 2;
            obj.BSimEditField.Layout.Row = 2;

            EnableSimParamLabel = uilabel(SimParamGrid, ...
                "Text", "Enable Simulated Paramters", ...
                "FontWeight", "bold");
            EnableSimParamLabel.Layout.Column = 1;
            EnableSimParamLabel.Layout.Row = 3;

            obj.EnableSimParamButton = uibutton(SimParamGrid, 'state', ...
                "Text", "DISABLED", ...
                "BackgroundColor","red", ...
                "FontWeight", 'bold', ...
                "FontSize", 15, ...
                "ValueChangedFcn", @(src, event) obj.enableSimParamCallback(event));
            obj.EnableSimParamButton.Layout.Column = 2;
            obj.EnableSimParamButton.Layout.Row = 3;

            %%% Average Runs %%%
            AverageRunsPanel = uipanel(obj.MainLayoutGrid, ...
                "Title", "Average Runs", ...
                "FontWeight", "bold");
            AverageRunsPanel.Layout.Column = [1, 4];
            AverageRunsPanel.Layout.Row = [10, 13];

            AverageRunsGrid = uigridlayout(AverageRunsPanel, [3, 2]);

            obj.RunsToAverageLabel = uilabel(AverageRunsGrid, ...
                "Text", "Runs to Average");
            obj.RunsToAverageLabel.Layout.Column = 1;
            obj.RunsToAverageLabel.Layout.Row = 1;

            obj.RunsToAverageEditField = uieditfield(AverageRunsGrid, 'numeric');
            obj.RunsToAverageEditField.Limits = [1, Inf];
            obj.RunsToAverageEditField.RoundFractionalValues = true;
            obj.RunsToAverageEditField.Value = 1;
            obj.RunsToAverageEditField.Layout.Column = 2;
            obj.RunsToAverageEditField.Layout.Row = 1;

            EnableAverageRunsLabel = uilabel(AverageRunsGrid, ...
                "Text", "Enable Average Runs", ...
                "FontWeight", "bold");
            EnableAverageRunsLabel.Layout.Column = 1;
            EnableAverageRunsLabel.Layout.Row = 2;

            obj.EnableAverageRunsButton = uibutton(AverageRunsGrid, 'state', ...
                "Text", "DISABLED", ...
                "BackgroundColor","red", ...
                "FontWeight", 'bold', ...
                "FontSize", 15, ...
                "ValueChangedFcn", @(src, event) obj.enableAverageRunsCallback(event));
            obj.EnableAverageRunsButton.Layout.Column = 2;
            obj.EnableAverageRunsButton.Layout.Row = 2;

            AveragingHelp = uilabel(AverageRunsGrid, ...
                "Text", "*Repeats the current forcing function N times and plots the running average after each run. Coherence is shown when N is at least 2.", ...
                "WordWrap", "on", ...
                "FontSize", 11, ...
                "FontAngle", "italic");
            AveragingHelp.Layout.Column = [1, 2];
            AveragingHelp.Layout.Row = 3;

            %%% Control Parameters %%%
            obj.ControlParamPanel = uipanel(obj.MainLayoutGrid, ...
                "Title", "Control Parameters", ...
                "FontWeight", "bold");
            obj.ControlParamPanel.Layout.Column = [1, 4];
            obj.ControlParamPanel.Layout.Row = [14, 18];

            ControlParamGrid = uigridlayout(obj.ControlParamPanel, [4, 2]);

            KpLabel = uilabel(ControlParamGrid, "Text", "$$\mathbf{K_p}$$");
            KpLabel.Interpreter = 'latex';
            KpLabel.Layout.Column = 1;
            KpLabel.Layout.Row = 1;

            obj.KpEditField = uieditfield(ControlParamGrid, 'numeric');
            obj.KpEditField.Value = 1;
            obj.KpEditField.ValueChangedFcn = @(~, ~) obj.controlParamsChanged();
            obj.KpEditField.Layout.Column = 2;
            obj.KpEditField.Layout.Row = 1;

            KiLabel = uilabel(ControlParamGrid, "Text", "$$\mathbf{K_i}$$");
            KiLabel.Interpreter = 'latex';
            KiLabel.Layout.Column = 1;
            KiLabel.Layout.Row = 2;

            obj.KiEditField = uieditfield(ControlParamGrid, 'numeric');
            obj.KiEditField.Value = 0;
            obj.KiEditField.ValueChangedFcn = @(~, ~) obj.controlParamsChanged();
            obj.KiEditField.Layout.Column = 2;
            obj.KiEditField.Layout.Row = 2;

            KdLabel = uilabel(ControlParamGrid, "Text", "$$\mathbf{K_d}$$");
            KdLabel.Interpreter = 'latex';
            KdLabel.Layout.Column = 1;
            KdLabel.Layout.Row = 3;

            obj.KdEditField = uieditfield(ControlParamGrid, 'numeric');
            obj.KdEditField.Value = 0;
            obj.KdEditField.ValueChangedFcn = @(~, ~) obj.controlParamsChanged();
            obj.KdEditField.Layout.Column = 2;
            obj.KdEditField.Layout.Row = 3;

            EnableControlsLabel = uilabel(ControlParamGrid, ...
                "Text", "Enable Controller", ...
                "FontWeight", 'bold');
            EnableControlsLabel.Layout.Column = 1;
            EnableControlsLabel.Layout.Row = 4;

            obj.EnableControlsButton = uibutton(ControlParamGrid, 'state', ...
                "Text", "DISABLED", ...
                "BackgroundColor","red", ...
                "FontWeight", 'bold', ...
                "FontSize", 15, ...
                "ValueChangedFcn", @(src, event) obj.enableControlCallback(event));
            obj.EnableControlsButton.Layout.Column = 2;
            obj.EnableControlsButton.Layout.Row = 4;

            %%% Control Mode %%%
            obj.ControlModePanel = uipanel(obj.MainLayoutGrid, ...
                "Title", "Control Mode", ...
                "FontWeight", "bold");
            obj.ControlModePanel.Layout.Column = [1, 4];
            obj.ControlModePanel.Layout.Row = [19, 20];

            ControlModeGrid = uigridlayout(obj.ControlModePanel, [1, 1]);

            obj.LoopModeGroup = uibuttongroup(ControlModeGrid, ...
                "BorderType", "none", ...
                "Title", "", ...
                "SelectionChangedFcn", @(~, ~) obj.controlParamsChanged());
            obj.LoopModeGroup.Layout.Column = 1;
            obj.LoopModeGroup.Layout.Row = 1;

            obj.OpenLoopRadio = uiradiobutton(obj.LoopModeGroup, ...
                "Text", " Open Loop", ...
                "Value", true, ...
                "FontWeight", "bold", ...
                "Position", [1, 4, 120, 22]);

            obj.ClosedLoopRadio = uiradiobutton(obj.LoopModeGroup, ...
                "Text", " Closed Loop", ...
                "FontWeight", "bold", ...
                "Position", [245, 4, 140, 22]);

            obj.setControlPanelsVisible(false, false);

            %%% Forcing Function Button %%%
            obj.CreateFcnButton = uibutton(obj.MainLayoutGrid, ...
                "Text","Create Forcing Function", ...
                "ButtonPushedFcn", @(src, event) obj.createFcnCallback());
            obj.CreateFcnButton.Layout.Column = [1, 2];
            obj.CreateFcnButton.Layout.Row = 22;

            %%% Save Output Button %%%
            obj.SaveOutputButton = uibutton(obj.MainLayoutGrid, ...
                "Text","Save Outputs", ...
                "ButtonPushedFcn", @(src, event) obj.saveOutputCallback());
            obj.SaveOutputButton.Layout.Column = [3, 4];
            obj.SaveOutputButton.Layout.Row = 22;
        end

        function tf = plotCart1(obj)
            tf = logical(obj.PlotCart1CheckBox.Value);
        end

        function tf = plotCart2(obj)
            tf = logical(obj.PlotCart2CheckBox.Value);
        end

        function plotCartsChanged(obj)
            if ~isempty(obj.fwdPlotCartsChangedCallback)
                obj.fwdPlotCartsChangedCallback(obj.plotCart1(), obj.plotCart2());
            end
        end

        function enableSimParamCallback(obj, event)
            state = event.Value;
            if state
                obj.EnableSimParamButton.Text = "ENABLED";
                obj.EnableSimParamButton.BackgroundColor = "green";
            else
                obj.EnableSimParamButton.Text = "DISABLED";
                obj.EnableSimParamButton.BackgroundColor = "red";
            end
            obj.simParamsChanged();
        end

        function simParamsChanged(obj)
            if ~isempty(obj.fwdSimParamsChangedCallback)
                obj.fwdSimParamsChangedCallback( ...
                    obj.KSimEditField.Value, ...
                    obj.BSimEditField.Value, ...
                    logical(obj.EnableSimParamButton.Value));
            end
        end

        function enableAverageRunsCallback(obj, event)
            state = event.Value;
            if state
                obj.EnableAverageRunsButton.Text = "ENABLED";
                obj.EnableAverageRunsButton.BackgroundColor = "green";
            else
                obj.EnableAverageRunsButton.Text = "DISABLED";
                obj.EnableAverageRunsButton.BackgroundColor = "red";
            end
            if ~isempty(obj.fwdAverageRunsChangedCallback)
                obj.fwdAverageRunsChangedCallback(logical(state));
            end
        end

        function n = runsToAverage(obj)
            n = max(1, round(obj.RunsToAverageEditField.Value));
        end

        function tf = averageRunsEnabled(obj)
            tf = logical(obj.EnableAverageRunsButton.Value);
        end

        function setAverageRunProgress(obj, currentRun, nRuns)
            if nargin < 3 || isempty(currentRun) || currentRun < 1
                obj.clearAverageRunProgress();
                return;
            end
            obj.RunsToAverageEditField.Visible = 'off';
            obj.RunsToAverageLabel.Text = sprintf('Simulation %d/%d', currentRun, nRuns);
            obj.RunsToAverageLabel.FontWeight = 'bold';
            obj.RunsToAverageLabel.Layout.Column = [1, 2];
        end

        function clearAverageRunProgress(obj)
            obj.RunsToAverageLabel.Layout.Column = 1;
            obj.RunsToAverageLabel.Text = "Runs to Average";
            obj.RunsToAverageLabel.FontWeight = 'normal';
            obj.RunsToAverageEditField.Visible = 'on';
        end

        function enableControlCallback(obj, event)
            state = event.Value;
            if state
                obj.EnableControlsButton.Text = "ENABLED";
                obj.EnableControlsButton.BackgroundColor = "green";
            else
                obj.EnableControlsButton.Text = "DISABLED";
                obj.EnableControlsButton.BackgroundColor = "red";
            end

            if ~isempty(obj.fwdEnableControlsCallback)
                obj.fwdEnableControlsCallback(logical(state));
            end
            obj.controlParamsChanged();
        end

        function controlParamsChanged(obj)
            if ~isempty(obj.fwdControlParamsChangedCallback)
                obj.fwdControlParamsChangedCallback( ...
                    obj.KpEditField.Value, ...
                    obj.KiEditField.Value, ...
                    obj.KdEditField.Value, ...
                    logical(obj.ClosedLoopRadio.Value), ...
                    logical(obj.EnableControlsButton.Value));
            end
        end

        function runSimCallback(obj)
            if ~isempty(obj.fwdRunSignalCallback)
                obj.fwdRunSignalCallback();
            end
        end

        function stopSimCallback(obj)
            if ~isempty(obj.fwdStopSignalCallback)
                obj.fwdStopSignalCallback();
            end
        end

        function createFcnCallback(obj)
            if ~isempty(obj.fwdSignalBuilderCallback)
                obj.fwdSignalBuilderCallback();
            end
        end

        function saveOutputCallback(obj)
            if ~isempty(obj.fwdSaveOutputCallback)
                obj.fwdSaveOutputCallback();
            end
        end

        function setSimLampRunning(obj, isRunning)
            if isRunning
                obj.SimLamp.Color = [1 0 0];
            else
                obj.SimLamp.Color = [0 1 0];
            end
        end

        function setSignalBuilderButtonText(obj, text)
            obj.CreateFcnButton.Text = text;
        end

        function tf = controlsEnabled(obj)
            tf = logical(obj.EnableControlsButton.Value);
        end

        function setControlPanelsVisible(obj, showParams, showMode)
            obj.ControlParamPanel.Visible = obj.onOff(showParams);
            obj.ControlModePanel.Visible = obj.onOff(showMode);
            obj.setRowsHeight(14:18, showParams);
            obj.setRowsHeight(19:20, showMode);
        end

        function setActionButtonsEnabled(obj, tf)
            if tf
                enableVal = 'on';
            else
                enableVal = 'off';
            end

            obj.SimStartButton.Enable = enableVal;
            obj.SimStopButton.Enable = 'on';
            obj.CreateFcnButton.Enable = enableVal;
            obj.SaveOutputButton.Enable = enableVal;
            obj.EnableSimParamButton.Enable = enableVal;
            obj.EnableAverageRunsButton.Enable = enableVal;
            obj.EnableControlsButton.Enable = enableVal;
        end
    end

    methods (Access = private)
        function setRowsHeight(obj, rows, isVisible)
            if isVisible
                height = 30;
            else
                height = 0;
            end
            rowHeight = obj.MainLayoutGrid.RowHeight;
            for r = rows
                rowHeight{r} = height;
            end
            obj.MainLayoutGrid.RowHeight = rowHeight;
        end

        function val = onOff(~, tf)
            if tf
                val = 'on';
            else
                val = 'off';
            end
        end
    end
end