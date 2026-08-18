classdef ControlsPanel < handle
    % Controls tab: displacement, error, and control-effort plots stacked
    % full-width. Axes are empty until the controller writes traces after a run.
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
    end
    methods
        function obj = ControlsPanel(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [3, 1]);
            obj.MainLayoutGrid.RowHeight = {'1x', '1x', '1x'};
            obj.MainLayoutGrid.RowSpacing = 5;

            [obj.DisplacementLabel, obj.AxDisplacement] = obj.createPlotCell( ...
                1, "Displacement", "Displacement (m)");
            [obj.ErrorLabel, obj.AxError] = obj.createPlotCell( ...
                2, "Error", "Error (m)");
            [obj.EffortLabel, obj.AxEffort] = obj.createPlotCell( ...
                3, "Control Effort", "Control Effort (N)");
        end
    end

    methods (Access = private)
        function [label, ax] = createPlotCell(obj, row, titleText, yLabel)
            plotGrid = uigridlayout(obj.MainLayoutGrid, [2, 1]);
            plotGrid.Layout.Row = row;
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
