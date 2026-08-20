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

            obj.MagLine = plot(obj.AxMag, NaN, NaN, 'b-', LineWidth=1.5);
            obj.PhaseLine = plot(obj.AxPhase, NaN, NaN, 'b-', LineWidth=1.5);
            obj.CoherenceLine = plot(obj.AxCoherence, NaN, NaN, 'b-', LineWidth=1.5);
            obj.setCoherenceVisible(false);
        end

        function update(obj, result, showCoherence)
            if nargin < 3
                showCoherence = false;
            end
            obj.setCoherenceVisible(showCoherence);
            if nargin < 2 || isempty(result) || result.n == 0 || isempty(result.freq)
                obj.clearPlots();
                obj.setCoherenceVisible(showCoherence);
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
            if showCoherence
                set(obj.CoherenceLine, 'XData', result.freq, 'YData', coh);
            else
                set(obj.CoherenceLine, 'XData', NaN, 'YData', NaN);
            end

            if isfield(result, 'xLim') && numel(result.xLim) == 2 && result.xLim(2) > result.xLim(1)
                xLim = result.xLim;
            else
                xLim = FftAnalyzer.displayXLim();
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
            if showCoherence
                ylim(obj.AxCoherence, [0, 1]);
            end
        end

        function clearPlots(obj)
            set(obj.MagLine, 'XData', NaN, 'YData', NaN);
            set(obj.PhaseLine, 'XData', NaN, 'YData', NaN);
            set(obj.CoherenceLine, 'XData', NaN, 'YData', NaN);
            xLim = FftAnalyzer.displayXLim();
            xlim(obj.AxMag, xLim);
            xlim(obj.AxPhase, xLim);
            xlim(obj.AxCoherence, xLim);
        end

        function clearCoherence(obj)
            set(obj.CoherenceLine, 'XData', NaN, 'YData', NaN);
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
end
