classdef ControlsFrequencyPanel < handle
    % Controls-Frequency tab: Bode magnitude and phase stacked in one column.
    % Axes are empty until the controller writes spectra after a run.
    %
    %{
    Example usage:

    >> fig = uifigure("Position", [100, 100, 800, 700]);
    >> panel = ControlsFrequencyPanel(fig);
    >> plot(panel.AxMag, freq, magDb);
    >> plot(panel.AxPhase, freq, phaseDeg);

    %}

    properties
        MainLayoutGrid
        AxMag
        AxPhase

        MagLine
        PhaseLine
        MagLine2
        PhaseLine2
        ShowCart1 (1,1) logical = true
        ShowCart2 (1,1) logical = false
    end
    methods
        function obj = ControlsFrequencyPanel(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [2, 1]);
            obj.MainLayoutGrid.RowHeight = {'1x', '1x'};
            obj.MainLayoutGrid.RowSpacing = 5;

            obj.AxMag = uiaxes(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            obj.AxMag.Layout.Row = 1;
            obj.AxMag.XScale = 'log';
            xlabel(obj.AxMag, 'Frequency (Hz)');
            ylabel(obj.AxMag, 'Magnitude (dB)');

            obj.AxPhase = uiaxes(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            obj.AxPhase.Layout.Row = 2;
            obj.AxPhase.XScale = 'log';
            xlabel(obj.AxPhase, 'Frequency (Hz)');
            ylabel(obj.AxPhase, 'Phase (deg)');
            ylim(obj.AxPhase, [-180, 180]);

            hold(obj.AxMag, "on");
            hold(obj.AxPhase, "on");
            obj.MagLine = plot(obj.AxMag, NaN, NaN, '-', ...
                'Color', CartPlotStyle.color(1), LineWidth=1.5, ...
                'DisplayName', CartPlotStyle.label(1));
            obj.PhaseLine = plot(obj.AxPhase, NaN, NaN, '-', ...
                'Color', CartPlotStyle.color(1), LineWidth=1.5, ...
                'DisplayName', CartPlotStyle.label(1));
            obj.MagLine2 = plot(obj.AxMag, NaN, NaN, '-', ...
                'Color', CartPlotStyle.color(2), LineWidth=1.5, ...
                'DisplayName', CartPlotStyle.label(2));
            obj.PhaseLine2 = plot(obj.AxPhase, NaN, NaN, '-', ...
                'Color', CartPlotStyle.color(2), LineWidth=1.5, ...
                'DisplayName', CartPlotStyle.label(2));
            obj.MagLine2.Visible = 'off';
            obj.PhaseLine2.Visible = 'off';

            title(obj.AxMag, "Bode Magnitude", "FontWeight", "bold", "FontSize", 17);
            title(obj.AxPhase, "Bode Phase", "FontWeight", "bold", "FontSize", 17);
            obj.AxMag.TitleHorizontalAlignment = "left";
            obj.AxPhase.TitleHorizontalAlignment = "left";
        end

        function updateBode(obj, spec, cart)
            if nargin < 3 || isempty(cart)
                cart = 1;
            end
            if cart == 2
                magLine = obj.MagLine2;
                phaseLine = obj.PhaseLine2;
            else
                magLine = obj.MagLine;
                phaseLine = obj.PhaseLine;
            end
            if ~isvalid(magLine) || ~isvalid(phaseLine)
                return;
            end
            if nargin < 2 || isempty(spec) || spec.n == 0 || isempty(spec.freq)
                set(magLine, 'XData', NaN, 'YData', NaN);
                set(phaseLine, 'XData', NaN, 'YData', NaN);
                obj.applyCartVisibility();
                return;
            end

            freq = spec.freq(:);
            if isfield(spec, 'magDb') && ~isempty(spec.magDb)
                magDb = spec.magDb(:);
            else
                magDb = 20 * log10(spec.mag(:));
            end
            phase = spec.phase(:);
            mask = freq > 0 & isfinite(magDb) & isfinite(phase);
            if ~any(mask)
                set(magLine, 'XData', NaN, 'YData', NaN);
                set(phaseLine, 'XData', NaN, 'YData', NaN);
                obj.applyCartVisibility();
                return;
            end
            freq = freq(mask);
            magDb = magDb(mask);
            phase = phase(mask);

            set(magLine, 'XData', freq, 'YData', magDb);
            set(phaseLine, 'XData', freq, 'YData', phase);
            xLim = [freq(1), freq(end)];
            if xLim(2) <= xLim(1)
                xLim(2) = xLim(1) * 10;
            end
            obj.AxMag.XLim = xLim;
            obj.AxPhase.XLim = xLim;
            obj.AxPhase.YLim = [-180, 180];
            obj.applyCartVisibility();
        end

        function setCartVisible(obj, showCart1, showCart2)
            obj.ShowCart1 = logical(showCart1);
            obj.ShowCart2 = logical(showCart2);
            obj.applyCartVisibility();
        end

        function clearPlots(obj)
            obj.updateBode(FftAnalyzer.emptySpectrum(), 1);
            obj.updateBode(FftAnalyzer.emptySpectrum(), 2);
        end
    end

    methods (Access = private)
        function applyCartVisibility(obj)
            if ~isempty(obj.MagLine) && isvalid(obj.MagLine)
                vis1 = CartPlotStyle.onOff(obj.ShowCart1);
                obj.MagLine.Visible = vis1;
                obj.PhaseLine.Visible = vis1;
            end
            if ~isempty(obj.MagLine2) && isvalid(obj.MagLine2)
                vis2 = CartPlotStyle.onOff(obj.ShowCart2);
                obj.MagLine2.Visible = vis2;
                obj.PhaseLine2.Visible = vis2;
            end
            CartPlotStyle.applyLegend(obj.AxMag, obj.MagLine, obj.MagLine2, ...
                obj.ShowCart1, obj.ShowCart2);
            CartPlotStyle.applyLegend(obj.AxPhase, obj.PhaseLine, obj.PhaseLine2, ...
                obj.ShowCart1, obj.ShowCart2);
        end
    end
end
