classdef ControlsPanel < handle
    % Controls-Time tab: 2x2 grid of displacement, reference input (f_input),
    % error, and control effort. Axes are empty until the controller writes
    % traces during or after a run.
    %
    %{
    Example usage:

    >> fig = uifigure("Position", [100, 100, 800, 700]);
    >> panel = ControlsPanel(fig);
    >> panel.updateDisplacement(t, x);
    >> panel.updateReferenceInput(t, f);

    %}

    properties
        MainLayoutGrid
        DisplacementLabel
        AxDisplacement
        ReferenceInputLabel
        AxReferenceInput
        ErrorLabel
        AxError
        EffortLabel
        AxEffort

        DisplacementLine
        ReferenceInputLine
        ErrorLine
        EffortLine
    end
    methods
        function obj = ControlsPanel(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [4, 2]);
            obj.MainLayoutGrid.ColumnWidth = {'1x', '1x'};
            obj.MainLayoutGrid.RowHeight = {30, '1x', 30, '1x'};
            obj.MainLayoutGrid.RowSpacing = 5;

            [obj.DisplacementLabel, obj.AxDisplacement] = obj.createPlotCell( ...
                1, 2, 1, "Displacement", "Displacement (m)");
            [obj.ReferenceInputLabel, obj.AxReferenceInput] = obj.createPlotCell( ...
                1, 2, 2, "Reference Input", "Force (N)");
            [obj.ErrorLabel, obj.AxError] = obj.createPlotCell( ...
                3, 4, 1, "Error", "Error (m)");
            [obj.EffortLabel, obj.AxEffort] = obj.createPlotCell( ...
                3, 4, 2, "Control Effort", "Control Effort (N)");

            obj.DisplacementLine = plot(obj.AxDisplacement, NaN, NaN, 'r-', LineWidth=1.5);
            obj.ReferenceInputLine = plot(obj.AxReferenceInput, NaN, NaN, 'b-', LineWidth=1.5);
            obj.ErrorLine = plot(obj.AxError, NaN, NaN, 'r-', LineWidth=1.5);
            obj.EffortLine = plot(obj.AxEffort, NaN, NaN, 'b-', LineWidth=1.5);
        end

        function updateDisplacement(obj, t, y)
            obj.setTimeLine(obj.AxDisplacement, obj.DisplacementLine, t, y);
        end

        function updateReferenceInput(obj, t, y)
            obj.setTimeLine(obj.AxReferenceInput, obj.ReferenceInputLine, t, y);
        end

        function updateError(obj, t, y)
            obj.setTimeLine(obj.AxError, obj.ErrorLine, t, y);
        end

        function updateEffort(obj, t, y)
            obj.setTimeLine(obj.AxEffort, obj.EffortLine, t, y);
        end

        function setReferenceQuantity(obj, quantity)
            ylabel(obj.AxReferenceInput, quantity.PlotYLabel);
        end

        function clearPlots(obj)
            obj.updateDisplacement([], []);
            obj.updateReferenceInput([], []);
            obj.updateError([], []);
            obj.updateEffort([], []);
        end
    end

    methods (Access = private)
        function [label, ax] = createPlotCell(obj, labelRow, axesRow, col, titleText, yLabel)
            label = uilabel(obj.MainLayoutGrid, ...
                "Text", titleText, ...
                "FontWeight", "bold", ...
                "FontSize", 17, ...
                "VerticalAlignment", "bottom");
            label.Layout.Row = labelRow;
            label.Layout.Column = col;

            ax = uiaxes(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            ax.Layout.Row = axesRow;
            ax.Layout.Column = col;
            xlabel(ax, 'Time (s)');
            ylabel(ax, yLabel);
        end

        function setTimeLine(~, ax, lineHandle, t, y)
            if nargin < 5 || isempty(t) || isempty(y)
                set(lineHandle, 'XData', NaN, 'YData', NaN);
                return;
            end
            t = t(:);
            y = y(:);
            n = min(numel(t), numel(y));
            set(lineHandle, 'XData', t(1:n), 'YData', y(1:n));
            xEnd = max(0.1, t(n));
            xlim(ax, [0, xEnd]);
        end
    end
end
