classdef TimePanel < handle
    % Time-domain tab: measured response axes above, reference/forcing axes below.
    % OverlayCheckBox is meant to draw the reference on the response plot.
    % updateReferencePlot / updateResponsePlot write cached line handles.
    %
    %{
    Example usage:

    >> fig = uifigure("Position", [100, 100, 800, 700]); panel = TimePanel(fig);
    >> panel.updateReferencePlot(t, f);
    >> panel.updateResponsePlot(t, x);

    %}

    properties
        MainLayoutGrid
        ResponsePlot
        ReferencePlot
        OverlayCheckBox
        AutoscaleCheckBox
        YLimCheckBox
        SignalButton          % reserved; not created in the constructor yet

        % Cached line handles so streaming can set XData/YData without new plot()
        RefLineHandle
        RespLineHandle
        OverlayLineHandle
        SimDuration (1,1) double = 0.1
        ResponseYLimits (1,2) double = [-0.03, 0.03]
    end
    methods
        function obj = TimePanel(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [3, 2]);
            obj.MainLayoutGrid.ColumnWidth = {'1x', '1x'};
            obj.MainLayoutGrid.RowHeight = {'1x', 35, '1x'};
            obj.MainLayoutGrid.RowSpacing = 5;

            % Response Section (Top)
            obj.ResponsePlot = uiaxes(obj.MainLayoutGrid, ...
                "XGrid", "on", ...
                "YGrid", "on");
            obj.ResponsePlot.Layout.Column = [1 2];
            obj.ResponsePlot.Layout.Row = 1;
            
            padCheckbox = uigridlayout(obj.MainLayoutGrid, [1, 4]);
            padCheckbox.Padding = [0, 0, 0, 10];
            padCheckbox.Layout.Column = [1 2];
            padCheckbox.Layout.Row = 2;
            padCheckbox.ColumnWidth = {'1x', 140, 160, 140};

            obj.YLimCheckBox = uicheckbox(padCheckbox, ...
                "Text", "Lock Y-axis Limits", ...
                "Value", true, ...
                "ValueChangedFcn", @(~,~) obj.applyResponseYLim());
            obj.YLimCheckBox.Layout.Column = 2;

            obj.AutoscaleCheckBox = uicheckbox(padCheckbox, ...
                "Text", "Lock X-axis to Duration", ...
                "Value", true, ...
                "ValueChangedFcn", @(~,~) obj.applyResponseXLim());
            obj.AutoscaleCheckBox.Layout.Column = 3;

            obj.OverlayCheckBox = uicheckbox(padCheckbox, ...
                "Text", "Overlay Reference", ...
                "Value", false, ...
                "ValueChangedFcn", @(~,~) obj.applyOverlay());
            obj.OverlayCheckBox.Layout.Column = 4;

            % Reference Section (Bottom)
            obj.ReferencePlot = uiaxes(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            obj.ReferencePlot.Layout.Column = [1 2];
            obj.ReferencePlot.Layout.Row = 3; 

            % Handle to manipulate plots
            obj.RefLineHandle = plot(obj.ReferencePlot, NaN, NaN, 'b-', LineWidth=1.5);
            xlabel(obj.ReferencePlot, 'Time (s)');
            ylabel(obj.ReferencePlot, 'Force (N)');

            yyaxis(obj.ResponsePlot, 'left');
            obj.RespLineHandle = plot(obj.ResponsePlot, NaN, NaN, 'r-', LineWidth=1.5);
            xlabel(obj.ResponsePlot, 'Time (s)');
            ylabel(obj.ResponsePlot, 'Displacement (m)');
            obj.applyResponseYLim();

            yyaxis(obj.ResponsePlot, 'right');
            obj.OverlayLineHandle = plot(obj.ResponsePlot, NaN, NaN, 'b--', LineWidth=1.2);
            ylabel(obj.ResponsePlot, 'Force (N)');
            obj.OverlayLineHandle.Visible = 'off';
            obj.ResponsePlot.YAxis(2).Visible = 'off';
            yyaxis(obj.ResponsePlot, 'left');

            title(obj.ResponsePlot, "Response Plot", "FontWeight", "bold", "FontSize", 17);
            title(obj.ReferencePlot, "Reference Plot", "FontWeight", "bold", "FontSize", 17);
        end

        function setReferenceQuantity(obj, quantity)
            ylabel(obj.ReferencePlot, quantity.PlotYLabel);
        end

        function setResponseYLimits(obj, limits)
            obj.ResponseYLimits = limits;
            obj.applyResponseYLim();
        end

        function updateReferencePlot(obj, t, y)
            if isempty(t) || isempty(y)
                set(obj.RefLineHandle, 'XData', NaN, 'YData', NaN);
                obj.applyOverlay();
                return;
            end
            set(obj.RefLineHandle, 'XData', t, 'YData', y);
            obj.SimDuration = max(0.1, t(end));
            xlim(obj.ReferencePlot, [0, obj.SimDuration]);
            obj.applyResponseXLim();
            obj.applyOverlay();
        end

        function updateResponsePlot(obj, t, y)
            yyaxis(obj.ResponsePlot, 'left');
            if isempty(t) || isempty(y)
                set(obj.RespLineHandle, 'XData', NaN, 'YData', NaN);
                obj.applyResponseXLim();
                return;
            end
            set(obj.RespLineHandle, 'XData', t, 'YData', y);
            obj.applyResponseXLim(t);
        end
    end

    methods (Access = private)
        function applyResponseYLim(obj)
            yyaxis(obj.ResponsePlot, 'left');
            if obj.YLimCheckBox.Value
                ylim(obj.ResponsePlot, obj.ResponseYLimits);
            else
                ylim(obj.ResponsePlot, 'auto');
            end
        end
        function applyOverlay(obj)
            yyaxis(obj.ResponsePlot, 'right');
            if obj.OverlayCheckBox.Value
                t = obj.RefLineHandle.XData;
                y = obj.RefLineHandle.YData;
                set(obj.OverlayLineHandle, 'XData', t, 'YData', y, 'Visible', 'on');
                obj.ResponsePlot.YAxis(2).Visible = 'on';
            else
                set(obj.OverlayLineHandle, 'Visible', 'off');
                obj.ResponsePlot.YAxis(2).Visible = 'off';
            end
            yyaxis(obj.ResponsePlot, 'left');
            obj.applyResponseXLim();
        end
        function applyResponseXLim(obj, t)
            if obj.AutoscaleCheckBox.Value
                xlim(obj.ResponsePlot, [0, obj.SimDuration]);
                return;
            end

            if nargin < 2 || isempty(t)
                t = obj.RespLineHandle.XData;
            end
            if isempty(t) || all(isnan(t))
                xEnd = obj.SimDuration;
            else
                xEnd = max(0.1, t(end));
            end
            xlim(obj.ResponsePlot, [0, xEnd]);
        end
    end
end
