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
        MagLabel
        AxMag
        PhaseLabel
        AxPhase
        CoherenceLabel
        AxCoherence

        MagLine
        PhaseLine
        CoherenceLine
    end
    methods
        function obj = FRFPanel(parentContainer)
            % 6-row grid: alternating labels (30px) and axes (1x)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [6, 1]);
            obj.MainLayoutGrid.RowHeight = {30, '1x', 30, '1x', 30, '1x'};
            obj.MainLayoutGrid.RowSpacing = 5;

            obj.MagLabel = uilabel(obj.MainLayoutGrid, ...
                "Text", "FRF Magnitude", ...
                "FontWeight", "bold", ...
                "FontSize", 17, ...
                "VerticalAlignment", "bottom");
            obj.MagLabel.Layout.Row = 1;

            obj.AxMag = uiaxes(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            obj.AxMag.Layout.Row = 2;
            xlabel(obj.AxMag, 'Frequency (Hz)');
            ylabel(obj.AxMag, 'Magnitude (m/N)');

            obj.PhaseLabel = uilabel(obj.MainLayoutGrid, ...
                "Text", "FRF Phase", ...
                "FontWeight", "bold", ...
                "FontSize", 17, ...
                "VerticalAlignment", "bottom");
            obj.PhaseLabel.Layout.Row = 3;

            obj.AxPhase = uiaxes(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            obj.AxPhase.Layout.Row = 4;
            xlabel(obj.AxPhase, 'Frequency (Hz)');
            ylabel(obj.AxPhase, 'Phase (deg)');
            ylim(obj.AxPhase, [-180, 180]);

            obj.CoherenceLabel = uilabel(obj.MainLayoutGrid, ...
                "Text", "Coherence", ...
                "FontWeight", "bold", ...
                "FontSize", 17, ...
                "VerticalAlignment", "bottom");
            obj.CoherenceLabel.Layout.Row = 5;

            obj.AxCoherence = uiaxes(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            obj.AxCoherence.Layout.Row = 6;
            xlabel(obj.AxCoherence, 'Frequency (Hz)');
            ylabel(obj.AxCoherence, 'Coherence');
            ylim(obj.AxCoherence, [0, 1]);

            obj.MagLine = plot(obj.AxMag, NaN, NaN, 'b-', LineWidth=1.5);
            obj.PhaseLine = plot(obj.AxPhase, NaN, NaN, 'b-', LineWidth=1.5);
            obj.CoherenceLine = plot(obj.AxCoherence, NaN, NaN, 'b-', LineWidth=1.5);
        end

        function update(obj, result)
            if nargin < 2 || isempty(result) || result.n == 0 || isempty(result.freq)
                obj.clearPlots();
                return;
            end
            mag = result.mag;
            mag(~isfinite(mag)) = NaN;
            phase = result.phase;
            phase(~isfinite(phase)) = NaN;
            coh = result.coherence;
            coh(~isfinite(coh)) = NaN;

            set(obj.MagLine, 'XData', result.freq, 'YData', mag);
            set(obj.PhaseLine, 'XData', result.freq, 'YData', phase);
            set(obj.CoherenceLine, 'XData', result.freq, 'YData', coh);
            xLim = [result.freq(1), result.freq(end)];
            if xLim(2) <= xLim(1)
                xLim(2) = xLim(1) + 1;
            end
            xlim(obj.AxMag, xLim);
            xlim(obj.AxPhase, xLim);
            xlim(obj.AxCoherence, xLim);

            finiteMag = mag(isfinite(mag));
            if isempty(finiteMag)
                ylim(obj.AxMag, 'auto');
            else
                yTop = max(finiteMag);
                if ~(yTop > 0)
                    yTop = 1;
                end
                ylim(obj.AxMag, [0, yTop * 1.1]);
            end
            ylim(obj.AxPhase, [-180, 180]);
            ylim(obj.AxCoherence, [0, 1]);
        end

        function clearPlots(obj)
            set(obj.MagLine, 'XData', NaN, 'YData', NaN);
            set(obj.PhaseLine, 'XData', NaN, 'YData', NaN);
            set(obj.CoherenceLine, 'XData', NaN, 'YData', NaN);
        end
    end
end
