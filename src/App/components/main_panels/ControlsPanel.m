classdef ControlsPanel < handle
    % Controls tab: displacement / error / control-effort plots (column 1)
    % and loop-mode radios plus PID gains (column 2). Axes are empty until
    % the controller writes traces after a run.
    %
    %{
    Example usage:

    >> fig = uifigure("Position", [100, 100, 800, 700]);
    >> panel = ControlsPanel(fig);
    >> plot(panel.AxDisplacement, t, x);
    >> plot(panel.AxError, t, e);
    >> plot(panel.AxEffort, t, u);

    %}

    properties
        MainLayoutGrid
        DisplacementLabel
        AxDisplacement
        ErrorLabel
        AxError
        EffortLabel
        AxEffort

        LoopModeGroup
        OpenLoopRadio
        ClosedLoopRadio

        KpEditField
        KiEditField
        KdEditField
        EnableControlsButton

        fwdEnableControlsCallback
    end
    methods
        function obj = ControlsPanel(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [3, 2]);
            obj.MainLayoutGrid.ColumnWidth = {'1x', 340};
            obj.MainLayoutGrid.RowHeight = {'1x', '1x', '1x'};
            obj.MainLayoutGrid.RowSpacing = 5;
            obj.MainLayoutGrid.ColumnSpacing = 10;

            [obj.DisplacementLabel, obj.AxDisplacement] = obj.createPlotCell( ...
                1, "Displacement", "Displacement (m)");
            [obj.ErrorLabel, obj.AxError] = obj.createPlotCell( ...
                2, "Error", "Error (m)");
            [obj.EffortLabel, obj.AxEffort] = obj.createPlotCell( ...
                3, "Control Effort", "Control Effort (N)");

            infoGrid = uigridlayout(obj.MainLayoutGrid, [3, 1]);
            infoGrid.Layout.Row = [1, 3];
            infoGrid.Layout.Column = 2;
            infoGrid.RowHeight = {40, 200, '1x'};
            infoGrid.RowSpacing = 8;
            infoGrid.Padding = [0, 0, 0, 0];

            obj.LoopModeGroup = uibuttongroup(infoGrid, ...
                "BorderType", "none", ...
                "Title", "");
            obj.LoopModeGroup.Layout.Row = 1;

            loopGrid = uigridlayout(obj.LoopModeGroup, [1, 2]);
            loopGrid.Padding = [0, 0, 0, 0];
            loopGrid.ColumnSpacing = 10;

            obj.OpenLoopRadio = uiradiobutton(loopGrid, ...
                "Text", "Open Loop", ...
                "Value", true);
            obj.OpenLoopRadio.Layout.Column = 1;

            obj.ClosedLoopRadio = uiradiobutton(loopGrid, ...
                "Text", "Closed Loop");
            obj.ClosedLoopRadio.Layout.Column = 2;

            ControlParamPanel = uipanel(infoGrid, ...
                "Title", "Control Parameters", ...
                "FontWeight", "bold");
            ControlParamPanel.Layout.Row = 2;

            ControlParamGrid = uigridlayout(ControlParamPanel, [4, 2]);

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
        end

        function tf = controlsEnabled(obj)
            tf = logical(obj.EnableControlsButton.Value);
        end

        function setActionButtonsEnabled(obj, tf)
            if tf
                enableVal = 'on';
            else
                enableVal = 'off';
            end
            obj.EnableControlsButton.Enable = enableVal;
        end
    end

    methods (Access = private)
        function [label, ax] = createPlotCell(obj, row, titleText, yLabel)
            plotGrid = uigridlayout(obj.MainLayoutGrid, [2, 1]);
            plotGrid.Layout.Row = row;
            plotGrid.Layout.Column = 1;
            plotGrid.RowHeight = {30, '1x'};
            plotGrid.RowSpacing = 5;
            plotGrid.Padding = [0, 0, 0, 0];

            label = uilabel(plotGrid, ...
                "Text", titleText, ...
                "FontWeight", "bold", ...
                "FontSize", 17, ...
                "VerticalAlignment", "bottom");
            label.Layout.Row = 1;

            ax = uiaxes(plotGrid, "XGrid", "on", "YGrid", "on");
            ax.Layout.Row = 2;
            xlabel(ax, 'Time (s)');
            ylabel(ax, yLabel);
        end
    end
end
