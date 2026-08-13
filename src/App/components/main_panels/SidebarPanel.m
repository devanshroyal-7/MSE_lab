classdef SidebarPanel < handle
    % Right-hand controls: SLDRT start/stop, k_sim / c_sim, PID gains,
    % Create Forcing Function, and Save Outputs. Start and Create Forcing
    % Function forward to AppView; enable toggles only change their own color.
    %
    %{
    Example usage:

    >> fig = uifigure("Position", [100, 100, 320, 640]);
    >> panel = SidebarPanel(fig);
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

        KpEditField
        KiEditField
        KdEditField
        EnableControlsButton

        CreateFcnButton
        SaveOutputButton
        SimLamp

        % Fwd Callbacks
        fwdRunSignalCallback

        fwdSignalBuilderCallback
        fwdSaveOutputCallback
    end

    methods
        function obj = SidebarPanel(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [14, 4]);
            obj.MainLayoutGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
            obj.MainLayoutGrid.RowHeight = {30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, '1x', 30};

            %%% Real-time Simulation Controls %%%
            SimControlLabel = uilabel(obj.MainLayoutGrid, ...
                "Text", "Simulation Controls", ...
                "FontWeight", "bold", ...
                "FontSize", 15);
            SimControlLabel.Layout.Column = [1, 2];
            SimControlLabel.Layout.Row = 1;

            obj.SimLamp = uilamp(obj.MainLayoutGrid, "Color", [0 1 0]);
            obj.SimLamp.Layout.Column = [3, 4];
            obj.SimLamp.Layout.Row = 1;

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
                "IconAlignment","top");
            obj.SimStopButton.Layout.Column = [3, 4];
            obj.SimStopButton.Layout.Row = [2, 3];
            % obj.SimStopButton.ButtonPushedFcn = @(~,~) obj.stopSimCallback;

            %%% Simulated Parameters %%%
            SimulatedParamsPanel = uipanel(obj.MainLayoutGrid, ...
                "Title", "Simulated Parameters", ...
                "FontWeight", "bold");
            SimulatedParamsPanel.Layout.Column = [1, 4];
            SimulatedParamsPanel.Layout.Row = [4,7];

            SimParamGrid = uigridlayout(SimulatedParamsPanel, [3, 2]);

            KSimLabel = uilabel(SimParamGrid, ...
                "Text", "$$\mathbf{k_{simulated}} \ (N/m)$$");
            KSimLabel.Interpreter = 'latex';
            KSimLabel.Layout.Column = 1;
            KSimLabel.Layout.Row = 1;

            obj.KSimEditField = uieditfield(SimParamGrid, 'numeric');
            obj.KSimEditField.Layout.Column = 2;
            obj.KSimEditField.Layout.Row = 1;

            BSimLabel = uilabel(SimParamGrid, ...
                "Text", "$$\mathbf{c_{simulated}} \ (Ns/m)");
            BSimLabel.Interpreter = 'latex';
            BSimLabel.Layout.Column = 1;
            BSimLabel.Layout.Row = 2;

            obj.BSimEditField = uieditfield(SimParamGrid, 'numeric');
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

            ControlParamPanels = uipanel(obj.MainLayoutGrid, ...
                "Title", "Control Parameters", ...
                "FontWeight", "bold");
            ControlParamPanels.Layout.Column = [1, 4];
            ControlParamPanels.Layout.Row = [8, 12];

            ControlParamGrid = uigridlayout(ControlParamPanels, [4, 2]);

            KpLabel = uilabel(ControlParamGrid, "Text", "$$\mathbf{K_p}$$");
            KpLabel.Interpreter = 'latex';
            KpLabel.Layout.Column = 1;
            KpLabel.Layout.Row = 1;

            obj.KpEditField = uieditfield(ControlParamGrid, 'numeric');
            obj.KpEditField.Layout.Column = 2;
            obj.KpEditField.Layout.Row = 1;

            KiLabel = uilabel(ControlParamGrid, "Text", "$$\mathbf{K_i}$$");
            KiLabel.Interpreter = 'latex';
            KiLabel.Layout.Column = 1;
            KiLabel.Layout.Row = 2;

            obj.KiEditField = uieditfield(ControlParamGrid, 'numeric');
            obj.KiEditField.Layout.Column = 2;
            obj.KiEditField.Layout.Row = 2;

            KdLabel = uilabel(ControlParamGrid, "Text", "$$\mathbf{K_d}$$");
            KdLabel.Interpreter = 'latex';
            KdLabel.Layout.Column = 1;
            KdLabel.Layout.Row = 3;

            obj.KdEditField = uieditfield(ControlParamGrid, 'numeric');
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

            %%% Forcing Function Button %%%
            obj.CreateFcnButton = uibutton(obj.MainLayoutGrid, ...
                "Text","Create Forcing Function", ...
                "ButtonPushedFcn", @(src, event) obj.createFcnCallback());
            obj.CreateFcnButton.Layout.Column = [1, 2];
            obj.CreateFcnButton.Layout.Row = 14;

            %%% Save Output Button %%%
            obj.SaveOutputButton = uibutton(obj.MainLayoutGrid, ...
                "Text","Save Outputs", ...
                "ButtonPushedFcn", @(src, event) obj.saveOutputCallback());
            obj.SaveOutputButton.Layout.Column = [3, 4];
            obj.SaveOutputButton.Layout.Row = 14;
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
        end
        
        function runSimCallback(obj)
            if ~isempty(obj.fwdRunSignalCallback)
                obj.fwdRunSignalCallback();
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
    end
end