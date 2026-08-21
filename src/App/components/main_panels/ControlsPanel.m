classdef ControlsPanel < handle
    % Controls-Time tab: 2x2 grid of displacement, reference (sim_input),
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
        AxDisplacement
        AxReferenceInput
        AxError
        AxEffort

        DisplacementLine
        DisplacementLine2
        ReferenceInputLine
        ErrorLine
        EffortLine
        ShowCart1 (1,1) logical = true
        ShowCart2 (1,1) logical = false
    end
    methods
        function obj = ControlsPanel(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [2, 2]);
            obj.MainLayoutGrid.ColumnWidth = {'1x', '1x'};
            obj.MainLayoutGrid.RowHeight = {'1x', '1x'};
            obj.MainLayoutGrid.RowSpacing = 5;

            obj.AxDisplacement = obj.createPlotCell(1, 1, "Displacement (mm)");
            obj.AxReferenceInput = obj.createPlotCell(1, 2, "Force (N)");
            obj.AxError = obj.createPlotCell(2, 1, "Error (mm)");
            obj.AxEffort = obj.createPlotCell(2, 2, "Control Effort (N)");

            hold(obj.AxDisplacement, "on");
            obj.DisplacementLine = plot(obj.AxDisplacement, NaN, NaN, '-', ...
                'Color', CartPlotStyle.color(1), 'LineWidth', 1.5, ...
                'DisplayName', CartPlotStyle.label(1));
            obj.DisplacementLine2 = plot(obj.AxDisplacement, NaN, NaN, '-', ...
                'Color', CartPlotStyle.color(2), 'LineWidth', 1.5, ...
                'DisplayName', CartPlotStyle.label(2));
            obj.DisplacementLine2.Visible = 'off';
            obj.ReferenceInputLine = plot(obj.AxReferenceInput, NaN, NaN, 'b-', LineWidth=1.5);
            obj.ErrorLine = plot(obj.AxError, NaN, NaN, 'r-', LineWidth=1.5);
            obj.EffortLine = plot(obj.AxEffort, NaN, NaN, 'b-', LineWidth=1.5);

            title(obj.AxDisplacement, "Displacement", "FontWeight", "bold", "FontSize", 17);
            title(obj.AxReferenceInput, "Reference Input", "FontWeight", "bold", "FontSize", 17);
            title(obj.AxError, "Error", "FontWeight", "bold", "FontSize", 17);
            title(obj.AxEffort, "Control Effort", "FontWeight", "bold", "FontSize", 17);
            obj.AxDisplacement.TitleHorizontalAlignment = "left";
            obj.AxReferenceInput.TitleHorizontalAlignment = "left";
            obj.AxError.TitleHorizontalAlignment = "left";
            obj.AxEffort.TitleHorizontalAlignment = "left";
        end

        function updateDisplacement(obj, t, y, cart)
            if nargin < 4 || isempty(cart)
                cart = 1;
            end
            if cart == 2
                h = obj.DisplacementLine2;
            else
                h = obj.DisplacementLine;
            end
            obj.setTimeLine(obj.AxDisplacement, h, t, y);
            obj.applyCartVisibility();
        end

        function setCartVisible(obj, showCart1, showCart2)
            obj.ShowCart1 = logical(showCart1);
            obj.ShowCart2 = logical(showCart2);
            obj.applyCartVisibility();
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
            ylabel(obj.AxError, sprintf('Error (%s)', quantity.Unit));
        end

        function clearPlots(obj)
            obj.updateDisplacement([], [], 1);
            obj.updateDisplacement([], [], 2);
            obj.updateReferenceInput([], []);
            obj.updateError([], []);
            obj.updateEffort([], []);
        end
    end

    methods (Access = private)
        function ax = createPlotCell(obj, row, col, yLabel)
            ax = uiaxes(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            ax.Layout.Row = row;
            ax.Layout.Column = col;
            xlabel(ax, 'Time (s)');
            ylabel(ax, yLabel);
        end

        function setTimeLine(~, ax, lineHandle, t, y)
            if ~isvalid(lineHandle)
                return;
            end
            if nargin < 5 || isempty(t) || isempty(y)
                set(lineHandle, 'XData', NaN, 'YData', NaN);
                return;
            end
            t = t(:);
            y = y(:);
            n = min(numel(t), numel(y));
            set(lineHandle, 'XData', t(1:n), 'YData', y(1:n));
            xEnd = max(0.1, t(n));
            cur = ax.XLim;
            if abs(cur(1)) > 1e-9 || abs(cur(2) - xEnd) > 1e-9
                ax.XLim = [0, xEnd];
            end
        end

        function applyCartVisibility(obj)
            if ~isempty(obj.DisplacementLine) && isvalid(obj.DisplacementLine)
                obj.DisplacementLine.Visible = CartPlotStyle.onOff(obj.ShowCart1);
            end
            if ~isempty(obj.DisplacementLine2) && isvalid(obj.DisplacementLine2)
                obj.DisplacementLine2.Visible = CartPlotStyle.onOff(obj.ShowCart2);
            end
            CartPlotStyle.applyLegend(obj.AxDisplacement, ...
                obj.DisplacementLine, obj.DisplacementLine2, ...
                obj.ShowCart1, obj.ShowCart2);
        end
    end
end
