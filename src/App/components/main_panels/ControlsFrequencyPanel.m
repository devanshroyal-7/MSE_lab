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

            obj.MagLine = plot(obj.AxMag, NaN, NaN, 'b-', LineWidth=1.5);
            obj.PhaseLine = plot(obj.AxPhase, NaN, NaN, 'b-', LineWidth=1.5);

            title(obj.AxMag, "Bode Magnitude", "FontWeight", "bold", "FontSize", 17);
            title(obj.AxPhase, "Bode Phase", "FontWeight", "bold", "FontSize", 17);
            obj.AxMag.TitleHorizontalAlignment = "left";
            obj.AxPhase.TitleHorizontalAlignment = "left";
        end

        function updateBode(obj, spec)
            if ~isvalid(obj.MagLine) || ~isvalid(obj.PhaseLine)
                return;
            end
            if nargin < 2 || isempty(spec) || spec.n == 0 || isempty(spec.freq)
                set(obj.MagLine, 'XData', NaN, 'YData', NaN);
                set(obj.PhaseLine, 'XData', NaN, 'YData', NaN);
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
                set(obj.MagLine, 'XData', NaN, 'YData', NaN);
                set(obj.PhaseLine, 'XData', NaN, 'YData', NaN);
                return;
            end
            freq = freq(mask);
            magDb = magDb(mask);
            phase = phase(mask);

            set(obj.MagLine, 'XData', freq, 'YData', magDb);
            set(obj.PhaseLine, 'XData', freq, 'YData', phase);
            xLim = [freq(1), freq(end)];
            if xLim(2) <= xLim(1)
                xLim(2) = xLim(1) * 10;
            end
            obj.AxMag.XLim = xLim;
            obj.AxPhase.XLim = xLim;
            obj.AxPhase.YLim = [-180, 180];
        end

        function clearPlots(obj)
            obj.updateBode(FftAnalyzer.emptySpectrum());
        end
    end
end
