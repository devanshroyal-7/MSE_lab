classdef FrequencyPanel < handle
    % Frequency-domain tab: 2x2 FFT grid (forcing | response) x (magnitude / phase).
    % Axes are empty until the controller writes spectra after a run.
    % FRF lives on FRFPanel.
    %
    %{
    Example usage:

    >> fig = uifigure("Position", [100, 100, 800, 700]);
    >> panel = FrequencyPanel(fig);
    >> specF = FftAnalyzer.compute(t, f);
    >> specX = FftAnalyzer.compute(t, x);
    >> panel.updateForcing(specF);
    >> panel.updateResponse(specX);

    %}

    properties
        MainLayoutGrid
        AxForcingMag
        AxForcingPhase
        AxResponseMag
        AxResponsePhase

        ForcingMagLine
        ForcingPhaseLine
        ResponseMagLine
        ResponsePhaseLine
    end
    methods
        function obj = FrequencyPanel(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [2, 2]);
            obj.MainLayoutGrid.ColumnWidth = {'1x', '1x'};
            obj.MainLayoutGrid.RowHeight = {'1x', '1x'};
            obj.MainLayoutGrid.RowSpacing = 5;

            obj.AxForcingMag = obj.createPlotCell(1, 1, "Magnitude (N)");
            obj.AxResponseMag = obj.createPlotCell(1, 2, "Magnitude (m)");
            obj.AxForcingPhase = obj.createPlotCell(2, 1, "Phase (deg)");
            obj.AxResponsePhase = obj.createPlotCell(2, 2, "Phase (deg)");

            ylim(obj.AxForcingPhase, [-180, 180]);
            ylim(obj.AxResponsePhase, [-180, 180]);

            obj.ForcingMagLine = plot(obj.AxForcingMag, NaN, NaN, 'b-', LineWidth=1.5);
            obj.ForcingPhaseLine = plot(obj.AxForcingPhase, NaN, NaN, 'b-', LineWidth=1.5);
            obj.ResponseMagLine = plot(obj.AxResponseMag, NaN, NaN, 'r-', LineWidth=1.5);
            obj.ResponsePhaseLine = plot(obj.AxResponsePhase, NaN, NaN, 'r-', LineWidth=1.5);

            title(obj.AxForcingMag, "Forcing FFT Magnitude", "FontWeight", "bold", "FontSize", 17);
            title(obj.AxResponseMag, "Response FFT Magnitude", "FontWeight", "bold", "FontSize", 17);
            title(obj.AxForcingPhase, "Forcing FFT Phase", "FontWeight", "bold", "FontSize", 17);
            title(obj.AxResponsePhase, "Response FFT Phase", "FontWeight", "bold", "FontSize", 17);
            obj.AxForcingMag.TitleHorizontalAlignment = "left";
            obj.AxResponseMag.TitleHorizontalAlignment = "left";
            obj.AxForcingPhase.TitleHorizontalAlignment = "left";
            obj.AxResponsePhase.TitleHorizontalAlignment = "left";
        end

        function updateForcing(obj, spec)
            obj.setSpectrumLines(obj.AxForcingMag, obj.ForcingMagLine, ...
                obj.AxForcingPhase, obj.ForcingPhaseLine, spec);
        end

        function updateResponse(obj, spec)
            obj.setSpectrumLines(obj.AxResponseMag, obj.ResponseMagLine, ...
                obj.AxResponsePhase, obj.ResponsePhaseLine, spec);
        end

        function clearPlots(obj)
            empty = FftAnalyzer.emptySpectrum();
            obj.updateForcing(empty);
            obj.updateResponse(empty);
        end
    end

    methods (Access = private)
        function ax = createPlotCell(obj, row, col, yLabel)
            ax = uiaxes(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            ax.Layout.Row = row;
            ax.Layout.Column = col;
            xlabel(ax, 'Frequency (Hz)');
            ylabel(ax, yLabel);
        end

        function setSpectrumLines(~, magAx, magLine, phaseAx, phaseLine, spec)
            if nargin < 6 || isempty(spec) || spec.n == 0 || isempty(spec.freq)
                set(magLine, 'XData', NaN, 'YData', NaN);
                set(phaseLine, 'XData', NaN, 'YData', NaN);
                return;
            end
            set(magLine, 'XData', spec.freq, 'YData', spec.mag);
            set(phaseLine, 'XData', spec.freq, 'YData', spec.phase);
            xLim = [spec.freq(1), spec.freq(end)];
            if xLim(2) <= xLim(1)
                xLim(2) = xLim(1) + 1;
            end
            xlim(magAx, xLim);
            xlim(phaseAx, xLim);
            ylim(phaseAx, [-180, 180]);
        end
    end
end
