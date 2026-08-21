classdef FRFPanel < handle
    % FRF tab: magnitude, phase, then coherence, stacked full-width.
    % Axes are empty until the controller writes spectra after a run.
    %
    %{
    Example usage:

    >> fig = uifigure("Position", [100, 100, 800, 700]);
    >> panel = FRFPanel(fig);
    >> result = FrfAnalyzer.compute(tF, f, tX, x);
    >> panel.update(result);

    %}

    properties
        MainLayoutGrid
        AxMag
        AxPhase
        AxCoherence

        MagLine
        PhaseLine
        CoherenceLine
        MagLine2
        PhaseLine2
        CoherenceLine2
        ShowCart1 (1,1) logical = true
        ShowCart2 (1,1) logical = false
    end
    methods
        function obj = FRFPanel(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [3, 1]);
            obj.MainLayoutGrid.RowHeight = {'1x', '1x', '1x'};
            obj.MainLayoutGrid.RowSpacing = 5;

            obj.AxMag = uiaxes(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            obj.AxMag.Layout.Row = 1;
            title(obj.AxMag, "FRF Magnitude", "FontWeight", "bold", "FontSize", 17);
            obj.AxMag.TitleHorizontalAlignment = "left";
            xlabel(obj.AxMag, 'Frequency (Hz)');
            ylabel(obj.AxMag, 'Magnitude (mm/N)');
            obj.AxMag.XLim = FftAnalyzer.displayXLim();
            hold(obj.AxMag, "on");

            obj.AxPhase = uiaxes(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            obj.AxPhase.Layout.Row = 2;
            title(obj.AxPhase, "FRF Phase", "FontWeight", "bold", "FontSize", 17);
            obj.AxPhase.TitleHorizontalAlignment = "left";
            xlabel(obj.AxPhase, 'Frequency (Hz)');
            ylabel(obj.AxPhase, 'Phase (deg)');
            ylim(obj.AxPhase, [-180, 180]);
            obj.AxPhase.XLim = FftAnalyzer.displayXLim();
            hold(obj.AxPhase, "on");

            obj.AxCoherence = uiaxes(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            obj.AxCoherence.Layout.Row = 3;
            title(obj.AxCoherence, "Coherence", "FontWeight", "bold", "FontSize", 17);
            obj.AxCoherence.TitleHorizontalAlignment = "left";
            xlabel(obj.AxCoherence, 'Frequency (Hz)');
            ylabel(obj.AxCoherence, 'Coherence');
            ylim(obj.AxCoherence, [0, 1]);
            obj.AxCoherence.XLim = FftAnalyzer.displayXLim();
            hold(obj.AxCoherence, "on");

            obj.MagLine = plot(obj.AxMag, NaN, NaN, '-', ...
                'Color', CartPlotStyle.color(1), 'LineWidth', 1.5, ...
                'DisplayName', CartPlotStyle.label(1));
            obj.PhaseLine = plot(obj.AxPhase, NaN, NaN, '-', ...
                'Color', CartPlotStyle.color(1), 'LineWidth', 1.5, ...
                'DisplayName', CartPlotStyle.label(1));
            obj.CoherenceLine = plot(obj.AxCoherence, NaN, NaN, '-', ...
                'Color', CartPlotStyle.color(1), 'LineWidth', 1.5, ...
                'DisplayName', CartPlotStyle.label(1));
            obj.MagLine2 = plot(obj.AxMag, NaN, NaN, '-', ...
                'Color', CartPlotStyle.color(2), 'LineWidth', 1.5, ...
                'DisplayName', CartPlotStyle.label(2));
            obj.PhaseLine2 = plot(obj.AxPhase, NaN, NaN, '-', ...
                'Color', CartPlotStyle.color(2), 'LineWidth', 1.5, ...
                'DisplayName', CartPlotStyle.label(2));
            obj.CoherenceLine2 = plot(obj.AxCoherence, NaN, NaN, '-', ...
                'Color', CartPlotStyle.color(2), 'LineWidth', 1.5, ...
                'DisplayName', CartPlotStyle.label(2));
            obj.MagLine2.Visible = 'off';
            obj.PhaseLine2.Visible = 'off';
            obj.CoherenceLine2.Visible = 'off';
            obj.setCoherenceVisible(false);
        end

        function update(obj, result, showCoherence, cart)
            if nargin < 3
                showCoherence = false;
            end
            if nargin < 4 || isempty(cart)
                cart = 1;
            end
            obj.setCoherenceVisible(showCoherence);
            [magLine, phaseLine, cohLine] = obj.cartLines(cart);
            if nargin < 2 || isempty(result) || result.n == 0 || isempty(result.freq)
                set(magLine, 'XData', NaN, 'YData', NaN);
                set(phaseLine, 'XData', NaN, 'YData', NaN);
                set(cohLine, 'XData', NaN, 'YData', NaN);
                obj.applyMagYLim();
                obj.applyCartVisibility();
                return;
            end
            mag = result.mag;
            mag(~isfinite(mag)) = NaN;
            phase = result.phase;
            phase(~isfinite(phase)) = NaN;
            coh = result.coherence;
            coh(~isfinite(coh)) = NaN;

            set(magLine, 'XData', result.freq, 'YData', mag);
            set(phaseLine, 'XData', result.freq, 'YData', phase);
            if showCoherence
                set(cohLine, 'XData', result.freq, 'YData', coh);
            else
                set(cohLine, 'XData', NaN, 'YData', NaN);
            end

            if isfield(result, 'xLim') && numel(result.xLim) == 2 && result.xLim(2) > result.xLim(1)
                xLim = result.xLim;
            else
                xLim = FftAnalyzer.displayXLim();
            end
            xlim(obj.AxMag, xLim);
            xlim(obj.AxPhase, xLim);
            xlim(obj.AxCoherence, xLim);

            obj.applyMagYLim();
            ylim(obj.AxPhase, [-180, 180]);
            if showCoherence
                ylim(obj.AxCoherence, [0, 1]);
            end
            obj.applyCartVisibility();
        end

        function setCartVisible(obj, showCart1, showCart2)
            obj.ShowCart1 = logical(showCart1);
            obj.ShowCart2 = logical(showCart2);
            obj.applyCartVisibility();
            obj.applyMagYLim();
        end

        function clearPlots(obj)
            set(obj.MagLine, 'XData', NaN, 'YData', NaN);
            set(obj.PhaseLine, 'XData', NaN, 'YData', NaN);
            set(obj.CoherenceLine, 'XData', NaN, 'YData', NaN);
            set(obj.MagLine2, 'XData', NaN, 'YData', NaN);
            set(obj.PhaseLine2, 'XData', NaN, 'YData', NaN);
            set(obj.CoherenceLine2, 'XData', NaN, 'YData', NaN);
            xLim = FftAnalyzer.displayXLim();
            xlim(obj.AxMag, xLim);
            xlim(obj.AxPhase, xLim);
            xlim(obj.AxCoherence, xLim);
            obj.applyCartVisibility();
        end

        function clearCoherence(obj)
            set(obj.CoherenceLine, 'XData', NaN, 'YData', NaN);
            set(obj.CoherenceLine2, 'XData', NaN, 'YData', NaN);
            obj.setCoherenceVisible(false);
        end

        function setCoherenceVisible(obj, tf)
            if tf
                vis = 'on';
                obj.MainLayoutGrid.RowHeight = {'1x', '1x', '1x'};
            else
                vis = 'off';
                obj.MainLayoutGrid.RowHeight = {'1x', '1x', 0};
            end
            obj.AxCoherence.Visible = vis;
        end
    end

    methods (Access = private)
        function [magLine, phaseLine, cohLine] = cartLines(obj, cart)
            if cart == 2
                magLine = obj.MagLine2;
                phaseLine = obj.PhaseLine2;
                cohLine = obj.CoherenceLine2;
            else
                magLine = obj.MagLine;
                phaseLine = obj.PhaseLine;
                cohLine = obj.CoherenceLine;
            end
        end

        function applyCartVisibility(obj)
            if ~isempty(obj.MagLine) && isvalid(obj.MagLine)
                vis1 = CartPlotStyle.onOff(obj.ShowCart1);
                obj.MagLine.Visible = vis1;
                obj.PhaseLine.Visible = vis1;
                obj.CoherenceLine.Visible = vis1;
            end
            if ~isempty(obj.MagLine2) && isvalid(obj.MagLine2)
                vis2 = CartPlotStyle.onOff(obj.ShowCart2);
                obj.MagLine2.Visible = vis2;
                obj.PhaseLine2.Visible = vis2;
                obj.CoherenceLine2.Visible = vis2;
            end
            CartPlotStyle.applyLegend(obj.AxMag, obj.MagLine, obj.MagLine2, ...
                obj.ShowCart1, obj.ShowCart2);
            CartPlotStyle.applyLegend(obj.AxPhase, obj.PhaseLine, obj.PhaseLine2, ...
                obj.ShowCart1, obj.ShowCart2);
            CartPlotStyle.applyLegend(obj.AxCoherence, obj.CoherenceLine, obj.CoherenceLine2, ...
                obj.ShowCart1, obj.ShowCart2);
        end

        function applyMagYLim(obj)
            mags = [];
            if obj.ShowCart1 && CartPlotStyle.lineHasData(obj.MagLine)
                mags = [mags; obj.MagLine.YData(:)];
            end
            if obj.ShowCart2 && CartPlotStyle.lineHasData(obj.MagLine2)
                mags = [mags; obj.MagLine2.YData(:)];
            end
            finiteMag = mags(isfinite(mags));
            if isempty(finiteMag)
                ylim(obj.AxMag, 'auto');
            else
                yTop = max(finiteMag);
                if ~(yTop > 0)
                    yTop = 1;
                end
                ylim(obj.AxMag, [0, yTop * 1.1]);
            end
        end
    end
end
