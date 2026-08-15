classdef TimePanel < handle
    % Time-domain tab: measured response axes above, reference/forcing axes below.
    % OverlayCheckBox is meant to draw the reference on the response plot.
    % updateReferencePlot / updateResponsePlot write cached line handles.
    %
    %{
    Example usage:

<<<<<<< HEAD
    >> fig = uifigure("Position", [100, 100, 800, 700]); panel = TimePanel(fig);
=======
    >> fig = uifigure("Position", [100, 100, 800, 700]);
    >> panel = TimePanel(fig);
>>>>>>> origin/main
    >> panel.updateReferencePlot(t, f);
    >> panel.updateResponsePlot(t, x);

    %}

    properties
        MainLayoutGrid
        ResponseLabel
        ResponsePlot
        ReferenceLabel
        ReferencePlot
        OverlayCheckBox
<<<<<<< HEAD
        AutoscaleCheckBox
=======
>>>>>>> origin/main
        SignalButton          % reserved; not created in the constructor yet

        % Cached line handles so streaming can set XData/YData without new plot()
        RefLineHandle
        RespLineHandle
<<<<<<< HEAD
        OverlayLineHandle
        SimDuration (1,1) double = 0.1
=======
>>>>>>> origin/main
    end
    methods
        function obj = TimePanel(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [6, 2]);
            obj.MainLayoutGrid.ColumnWidth = {'1x', '1x'};
            obj.MainLayoutGrid.RowHeight = {30, '1x', 35, 30, '1x', 30};
            obj.MainLayoutGrid.RowSpacing = 5;

            % Response Section (Top)
            obj.ResponseLabel = uilabel(obj.MainLayoutGrid, ...
                "Text", "Response Plot", ...
                "FontWeight", "bold", ...
                "FontSize", 17, ...
                "VerticalAlignment", "bottom");
            obj.ResponseLabel.Layout.Column = [1 2];
            obj.ResponseLabel.Layout.Row = 1;
            
            obj.ResponsePlot = uiaxes(obj.MainLayoutGrid, ...
                "XGrid", "on", ...
                "YGrid", "on");
            obj.ResponsePlot.Layout.Column = [1 2];
            obj.ResponsePlot.Layout.Row = 2;
            
            padCheckbox = uigridlayout(obj.MainLayoutGrid, [1, 4]);
            padCheckbox.Padding = [0, 0, 0, 10];
            padCheckbox.Layout.Column = [1 2];
            padCheckbox.Layout.Row = 3;
            padCheckbox.ColumnWidth = {'1x', '1x', 150, 140};

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
            obj.ReferenceLabel = uilabel(obj.MainLayoutGrid, ...
                "Text", "Reference Plot", ...
                "FontWeight", "bold", ...
                "FontSize", 17, ...
                "VerticalAlignment", "bottom");
            obj.ReferenceLabel.Layout.Column = [1 2];
            obj.ReferenceLabel.Layout.Row = 4; 
            
            obj.ReferencePlot = uiaxes(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            obj.ReferencePlot.Layout.Column = [1 2];
            obj.ReferencePlot.Layout.Row = 5; 

            % Handle to manipulate plots
            obj.RefLineHandle = plot(obj.ReferencePlot, NaN, NaN, 'b-', LineWidth=1.5);
            xlabel(obj.ReferencePlot, 'Time (s)');
<<<<<<< HEAD
            ylabel(obj.ReferencePlot, 'Force (N)');

            yyaxis(obj.ResponsePlot, 'left');
            obj.RespLineHandle = plot(obj.ResponsePlot, NaN, NaN, 'r-', LineWidth=1.5);
            xlabel(obj.ResponsePlot, 'Time (s)');
            ylabel(obj.ResponsePlot, 'Displacement (m)');

            yyaxis(obj.ResponsePlot, 'right');
            obj.OverlayLineHandle = plot(obj.ResponsePlot, NaN, NaN, 'b--', LineWidth=1.2);
            ylabel(obj.ResponsePlot, 'Force (N)');
            obj.OverlayLineHandle.Visible = 'off';
            obj.ResponsePlot.YAxis(2).Visible = 'off';
            yyaxis(obj.ResponsePlot, 'left');
=======
            ylabel(obj.ReferencePlot, 'Displacement (m)');

            obj.RespLineHandle = plot(obj.ResponsePlot, NaN, NaN, 'r-', LineWidth=1.5);
            xlabel(obj.ResponsePlot, 'Time (s)');
            ylabel(obj.ResponsePlot, 'Displacement (m)');
>>>>>>> origin/main
        end

        function updateReferencePlot(obj, t, y)
            if isempty(t) || isempty(y)
                set(obj.RefLineHandle, 'XData', NaN, 'YData', NaN);
<<<<<<< HEAD
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
=======
                return;
            end
            set(obj.RefLineHandle, 'XData', t, 'YData', y);
            xlim(obj.ReferencePlot, [0, max(0.1, t(end))]);
        end

        function updateResponsePlot(obj, t, y)
            if isempty(t) || isempty(y)
                set(obj.RespLineHandle, 'XData', NaN, 'YData', NaN);
                return;
            end
            set(obj.RespLineHandle, 'XData', t, 'YData', y);
            xlim(obj.ResponsePlot, [0, max(0.1, t(end))]);
>>>>>>> origin/main
        end
    end
end