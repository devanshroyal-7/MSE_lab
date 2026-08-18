classdef SidebarPanel < handle
    % Right-hand controls: SLDRT start/stop, k_sim / c_sim,
    % Create Forcing Function, and Save Outputs. Start and Create Forcing
    % Function forward to AppView; the sim-param enable toggle only changes color.
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
            obj.MainLayoutGrid = uigridlayout(parentContainer, [9, 4]);
            obj.MainLayoutGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
            obj.MainLayoutGrid.RowHeight = {30, 30, 30, 30, 30, 30, 30, '1x', 30};

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

            %%% Forcing Function Button %%%
            obj.CreateFcnButton = uibutton(obj.MainLayoutGrid, ...
                "Text","Create Forcing Function", ...
                "ButtonPushedFcn", @(src, event) obj.createFcnCallback());
            obj.CreateFcnButton.Layout.Column = [1, 2];
            obj.CreateFcnButton.Layout.Row = 9;

            %%% Save Output Button %%%
            obj.SaveOutputButton = uibutton(obj.MainLayoutGrid, ...
                "Text","Save Outputs", ...
                "ButtonPushedFcn", @(src, event) obj.saveOutputCallback());
            obj.SaveOutputButton.Layout.Column = [3, 4];
            obj.SaveOutputButton.Layout.Row = 9;
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

        function setSignalBuilderButtonText(obj, text)
            obj.CreateFcnButton.Text = text;
        end

        function setActionButtonsEnabled(obj, tf)
            if tf
                enableVal = 'on';
            else
                enableVal = 'off';
            end

            obj.SimStartButton.Enable = enableVal;
            obj.CreateFcnButton.Enable = enableVal;
            obj.SaveOutputButton.Enable = enableVal;
            obj.EnableSimParamButton.Enable = enableVal;
        end
    end
end