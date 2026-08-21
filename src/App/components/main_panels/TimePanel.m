classdef TimePanel < handle
    % Time-domain tab: measured response axes above, reference/forcing axes below.
    % OverlayCheckBox is meant to draw the reference on the response plot.
    % updateReferencePlot / updateResponsePlot write cached line handles.
    %
    % While a run is live, ResponsePlot (uiaxes) is hidden and a uitimescope
    % occupies the same grid cell. Overlay / lock-X / lock-Y apply only to
    % the post-run uiaxes. uitimescope requires MATLAB R2024a+.
    %
    %{
    Example usage:

    >> fig = uifigure("Position", [100, 100, 800, 700]); panel = TimePanel(fig);
    >> panel.updateReferencePlot(t, f);
    >> panel.updateResponsePlot(t, x);

    %}

    properties
        MainLayoutGrid
        ResponseHost          % 1x1 grid so live timescope and uiaxes share a cell
        ResponsePlot
        ResponseTimeScope     % uitimescope during a run; empty afterward
        ReferencePlot
        OverlayCheckBox
        AutoscaleCheckBox
        YLimCheckBox
        SignalButton          % reserved; not created in the constructor yet

        % Cached line handles so streaming can set XData/YData without new plot()
        RefLineHandle
        RespLineHandle
        RespLine2Handle
        OverlaySameAxisHandle
        OverlayDualAxisHandle
        ReferenceQuantity
        SimDuration (1,1) double = 0.1
        ResponseYLimits (1,2) double = [-20, 20]
        ShowCart1 (1,1) logical = true
        ShowCart2 (1,1) logical = false
    end
    methods
        function obj = TimePanel(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [3, 2]);
            obj.MainLayoutGrid.ColumnWidth = {'1x', '1x'};
            obj.MainLayoutGrid.RowHeight = {'1x', 35, '1x'};
            obj.MainLayoutGrid.RowSpacing = 5;

            % Response Section (Top): host grid holds either uiaxes or uitimescope
            obj.ResponseHost = uigridlayout(obj.MainLayoutGrid, [1, 1]);
            obj.ResponseHost.Layout.Column = [1 2];
            obj.ResponseHost.Layout.Row = 1;
            obj.ResponseHost.Padding = [0 0 0 0];
            obj.ResponseHost.RowHeight = {'1x'};
            obj.ResponseHost.ColumnWidth = {'1x'};

            obj.ResponsePlot = uiaxes(obj.ResponseHost, ...
                "XGrid", "on", ...
                "YGrid", "on");
            obj.ResponsePlot.Layout.Column = 1;
            obj.ResponsePlot.Layout.Row = 1;
            
            padCheckbox = uigridlayout(obj.MainLayoutGrid, [1, 4]);
            padCheckbox.Padding = [0, 0, 0, 10];
            padCheckbox.Layout.Column = [1 2];
            padCheckbox.Layout.Row = 2;
            padCheckbox.ColumnWidth = {'1x', 140, 160, 140};

            obj.YLimCheckBox = uicheckbox(padCheckbox, ...
                "Text", "Lock Y-axis Limits", ...
                "Value", false, ...
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
            obj.ReferenceQuantity = SignalQuantity.force();
            obj.RefLineHandle = plot(obj.ReferencePlot, NaN, NaN, 'b-', LineWidth=1.5);
            xlabel(obj.ReferencePlot, 'Time (s)');
            ylabel(obj.ReferencePlot, 'Force (N)');

            yyaxis(obj.ResponsePlot, 'left');
            hold(obj.ResponsePlot, 'on');
            obj.OverlaySameAxisHandle = plot(obj.ResponsePlot, NaN, NaN, 'b--', LineWidth=1.2);
            obj.OverlaySameAxisHandle.Visible = 'off';
            obj.RespLineHandle = plot(obj.ResponsePlot, NaN, NaN, '-', ...
                'Color', CartPlotStyle.color(1), LineWidth=1.5, ...
                'DisplayName', CartPlotStyle.label(1));
            obj.RespLine2Handle = plot(obj.ResponsePlot, NaN, NaN, '-', ...
                'Color', CartPlotStyle.color(2), LineWidth=1.5, ...
                'DisplayName', CartPlotStyle.label(2));
            obj.RespLine2Handle.Visible = 'off';
            xlabel(obj.ResponsePlot, 'Time (s)');
            obj.ResponsePlot.YAxis(1).Label.String = 'Displacement (mm)';
            obj.ResponsePlot.YAxis(1).Color = [0 0 0];
            obj.ResponsePlot.XColor = [0 0 0];
            obj.applyResponseYLim();

            yyaxis(obj.ResponsePlot, 'right');
            hold(obj.ResponsePlot, 'on');
            obj.OverlayDualAxisHandle = plot(obj.ResponsePlot, NaN, NaN, 'b--', LineWidth=1.2);
            obj.OverlayDualAxisHandle.Visible = 'off';
            obj.ResponsePlot.YAxis(2).Label.String = 'Force (N)';
            obj.ResponsePlot.YAxis(2).Color = [0 0 1];
            obj.ResponsePlot.YAxis(2).Visible = 'off';
            yyaxis(obj.ResponsePlot, 'left');
            try
                disableDefaultInteractivity(obj.ResponsePlot);
                disableDefaultInteractivity(obj.ReferencePlot);
            catch
            end

            title(obj.ResponsePlot, "Response Plot", "FontWeight", "bold", "FontSize", 17);
            title(obj.ReferencePlot, "Reference Plot", "FontWeight", "bold", "FontSize", 17);
            obj.ResponsePlot.TitleHorizontalAlignment = "left";
            obj.ReferencePlot.TitleHorizontalAlignment = "left";
            obj.ResponseTimeScope = [];
        end

        function setReferenceQuantity(obj, quantity)
            obj.ReferenceQuantity = quantity;
            ylabel(obj.ReferencePlot, quantity.PlotYLabel);
            obj.applyOverlay();
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
            obj.setXLimIfChanged(obj.ReferencePlot, [0, obj.SimDuration]);
            obj.applyResponseXLim();
            obj.applyOverlay();
        end

        function updateResponsePlot(obj, t, y, cart)
            if nargin < 4 || isempty(cart)
                cart = 1;
            end
            yyaxis(obj.ResponsePlot, 'left');
            h = obj.responseLine(cart);
            if isempty(h) || ~isvalid(h)
                return;
            end
            if isempty(t) || isempty(y)
                set(h, 'XData', NaN, 'YData', NaN);
                obj.applyCartVisibility();
                obj.applyResponseXLim();
                return;
            end
            set(h, 'XData', t, 'YData', y);
            obj.applyCartVisibility();
            obj.applyResponseXLim(t);
        end

        function setCartVisible(obj, showCart1, showCart2)
            obj.ShowCart1 = logical(showCart1);
            obj.ShowCart2 = logical(showCart2);
            obj.applyCartVisibility();
        end

        function showLiveTimeScope(obj, sampleRate, cart)
            % Hide Response uiaxes and put a fresh uitimescope in the same
            % grid cell. AppModel.connectLiveTimeScope binds the selected cart.
            if nargin < 2 || isempty(sampleRate) || ~(sampleRate > 0)
                sampleRate = 1000;
            end
            if nargin < 3 || isempty(cart)
                cart = 1;
            end
            obj.teardownTimeScope();
            obj.ResponsePlot.Visible = 'off';

            if exist('uitimescope', 'file') ~= 2
                % uitimescope is R2024a+ (matlab.ui.scope.TimeScope in a
                % uigridlayout). timescope (DSP System object) opens its own
                % figure and cannot replace this uiaxes. Leave ResponsePlot on.
                obj.ResponsePlot.Visible = 'on';
                warning('TimePanel:NoUITimeScope', ...
                    ['uitimescope is not available. Live Response view ', ...
                     'needs MATLAB R2024a or newer.']);
                return;
            end

            try
                scope = uitimescope(obj.ResponseHost);
            catch ME
                obj.ResponsePlot.Visible = 'on';
                warning('TimePanel:NoUITimeScope', ...
                    'Could not create uitimescope: %s', ME.message);
                return;
            end
            scope.Layout.Row = 1;
            scope.Layout.Column = 1;
            try
                scope.Title = sprintf('Response (live) — Cart %d', cart);
                scope.XLabel = 'Time (s)';
                scope.YLabel = 'Displacement (m)';
                scope.XTimeSpan = max(0.1, obj.SimDuration);
                scope.PlotType = 'line';
            catch
            end
            try
                scope.SampleRate = sampleRate;
            catch
            end
            try
                nBuf = max(5000, round(obj.SimDuration * sampleRate) + 100);
                scope.BufferLength = nBuf;
            catch
            end
            obj.applyTimeScopeLineColor(scope, cart);
            obj.ResponseTimeScope = scope;
        end

        function restoreResponseAxes(obj)
            obj.teardownTimeScope();
            if ~isempty(obj.ResponsePlot) && isvalid(obj.ResponsePlot)
                obj.ResponsePlot.Visible = 'on';
            end
        end

        function setResponseStatus(obj, message)
            if isempty(obj.ResponsePlot) || ~isvalid(obj.ResponsePlot)
                return;
            end
            if nargin < 2 || strlength(string(message)) == 0
                title(obj.ResponsePlot, "Response Plot", ...
                    "FontWeight", "bold", "FontSize", 17);
            else
                title(obj.ResponsePlot, string(message), ...
                    "FontWeight", "bold", "FontSize", 14);
            end
        end

        function scope = getResponseTimeScope(obj)
            scope = obj.ResponseTimeScope;
        end

        function applyOverlay(obj)
            obj.ensureOverlayLines();

            overlayOn = logical(obj.OverlayCheckBox.Value);
            dual = overlayOn && obj.usesDualOverlay();
            t = obj.RefLineHandle.XData;
            y = obj.RefLineHandle.YData;

            yyaxis(obj.ResponsePlot, 'left');
            obj.ResponsePlot.YAxis(1).Label.String = 'Displacement (mm)';
            obj.ResponsePlot.XColor = [0 0 0];
            if overlayOn && ~dual
                set(obj.OverlaySameAxisHandle, 'XData', t, 'YData', y, 'Visible', 'on');
                obj.ResponsePlot.YAxis(1).Color = [0 0 0];
            else
                set(obj.OverlaySameAxisHandle, 'Visible', 'off');
                if dual
                    obj.ResponsePlot.YAxis(1).Color = [1 0 0];
                else
                    obj.ResponsePlot.YAxis(1).Color = [0 0 0];
                end
            end

            yyaxis(obj.ResponsePlot, 'right');
            if dual
                set(obj.OverlayDualAxisHandle, 'XData', t, 'YData', y, 'Visible', 'on');
                obj.ResponsePlot.YAxis(2).Color = [0 0 1];
                obj.ResponsePlot.YAxis(2).Label.String = obj.ReferenceQuantity.PlotYLabel;
                obj.ResponsePlot.YAxis(2).Visible = 'on';
            else
                set(obj.OverlayDualAxisHandle, 'Visible', 'off');
                obj.ResponsePlot.YAxis(2).Visible = 'off';
            end

            yyaxis(obj.ResponsePlot, 'left');
            obj.applyResponseXLim();
            obj.applyCartVisibility();
        end
    end

    methods (Access = private)
        function applyResponseYLim(obj)
            if obj.YLimCheckBox.Value
                obj.ResponsePlot.YAxis(1).Limits = obj.ResponseYLimits;
            else
                obj.ResponsePlot.YAxis(1).LimitsMode = 'auto';
            end
        end

        function ensureOverlayLines(obj)
            yyaxis(obj.ResponsePlot, 'left');
            hold(obj.ResponsePlot, 'on');
            if isempty(obj.OverlaySameAxisHandle) || ~isvalid(obj.OverlaySameAxisHandle)
                obj.OverlaySameAxisHandle = plot(obj.ResponsePlot, NaN, NaN, 'b--', LineWidth=1.2);
            end
            yyaxis(obj.ResponsePlot, 'right');
            hold(obj.ResponsePlot, 'on');
            if isempty(obj.OverlayDualAxisHandle) || ~isvalid(obj.OverlayDualAxisHandle)
                obj.OverlayDualAxisHandle = plot(obj.ResponsePlot, NaN, NaN, 'b--', LineWidth=1.2);
            end
            yyaxis(obj.ResponsePlot, 'left');
        end

        function tf = usesDualOverlay(obj)
            tf = isempty(obj.ReferenceQuantity) || obj.ReferenceQuantity.Mode == "force";
        end

        function applyCartVisibility(obj)
            if ~isempty(obj.RespLineHandle) && isvalid(obj.RespLineHandle)
                obj.RespLineHandle.Visible = CartPlotStyle.onOff(obj.ShowCart1);
            end
            if ~isempty(obj.RespLine2Handle) && isvalid(obj.RespLine2Handle)
                obj.RespLine2Handle.Visible = CartPlotStyle.onOff(obj.ShowCart2);
            end
            if ~isempty(obj.ResponsePlot) && isvalid(obj.ResponsePlot)
                CartPlotStyle.applyLegend(obj.ResponsePlot, ...
                    obj.RespLineHandle, obj.RespLine2Handle, ...
                    obj.ShowCart1, obj.ShowCart2);
            end
        end

        function h = responseLine(obj, cart)
            if cart == 2
                h = obj.RespLine2Handle;
            else
                h = obj.RespLineHandle;
            end
        end

        function t = responseTimeForXLim(obj)
            t = [];
            if obj.ShowCart1 && CartPlotStyle.lineHasData(obj.RespLineHandle)
                t = obj.RespLineHandle.XData;
            elseif obj.ShowCart2 && CartPlotStyle.lineHasData(obj.RespLine2Handle)
                t = obj.RespLine2Handle.XData;
            elseif CartPlotStyle.lineHasData(obj.RespLineHandle)
                t = obj.RespLineHandle.XData;
            elseif CartPlotStyle.lineHasData(obj.RespLine2Handle)
                t = obj.RespLine2Handle.XData;
            end
        end

        function applyResponseXLim(obj, t)
            if obj.AutoscaleCheckBox.Value
                obj.setXLimIfChanged(obj.ResponsePlot, [0, obj.SimDuration]);
                return;
            end

            if nargin < 2 || isempty(t)
                t = obj.responseTimeForXLim();
            end
            if isempty(t) || all(isnan(t))
                xEnd = obj.SimDuration;
            else
                xEnd = max(0.1, t(end));
            end
            obj.setXLimIfChanged(obj.ResponsePlot, [0, xEnd]);
        end

        function setXLimIfChanged(~, ax, newLim)
            cur = ax.XLim;
            if abs(cur(1) - newLim(1)) < 1e-9 && abs(cur(2) - newLim(2)) < 1e-9
                return;
            end
            ax.XLim = newLim;
        end

        function teardownTimeScope(obj)
            scope = obj.ResponseTimeScope;
            obj.ResponseTimeScope = [];
            if isempty(scope)
                return;
            end
            try
                if isvalid(scope)
                    delete(scope);
                end
            catch
            end
        end

        function applyTimeScopeLineColor(~, scope, cart)
            % Match the post-run Response line for the live cart.
            if nargin < 3 || isempty(cart)
                cart = 1;
            end
            rgb = CartPlotStyle.color(cart);
            names = {'LineColor', 'PlotColor', 'ChannelColor', 'SignalColor'};
            for i = 1:numel(names)
                try
                    scope.(names{i}) = rgb;
                catch
                end
            end
            try
                scope.ColorOrder = rgb;
            catch
                try
                    scope.ColorOrder = [rgb; 0 0.45 0.74];
                catch
                end
            end
            try
                scope.Style.LineColor = rgb;
            catch
            end
        end
    end
end
