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
        ResponseMagLine2
        ResponsePhaseLine2
        ShowCart1 (1,1) logical = true
        ShowCart2 (1,1) logical = false
    end
    methods
        function obj = FrequencyPanel(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [2, 2]);
            obj.MainLayoutGrid.ColumnWidth = {'1x', '1x'};
            obj.MainLayoutGrid.RowHeight = {'1x', '1x'};
            obj.MainLayoutGrid.RowSpacing = 5;

            obj.AxForcingMag = obj.createPlotCell(1, 1, "Magnitude (N)");
            obj.AxResponseMag = obj.createPlotCell(1, 2, "Magnitude (mm)");
            obj.AxForcingPhase = obj.createPlotCell(2, 1, "Phase (deg)");
            obj.AxResponsePhase = obj.createPlotCell(2, 2, "Phase (deg)");

            ylim(obj.AxForcingPhase, [-180, 180]);
            ylim(obj.AxResponsePhase, [-180, 180]);

            obj.ForcingMagLine = plot(obj.AxForcingMag, NaN, NaN, 'b-', LineWidth=1.5);
            obj.ForcingPhaseLine = plot(obj.AxForcingPhase, NaN, NaN, 'b-', LineWidth=1.5);
            hold(obj.AxResponseMag, "on");
            hold(obj.AxResponsePhase, "on");
            obj.ResponseMagLine = plot(obj.AxResponseMag, NaN, NaN, '-', ...
                'Color', CartPlotStyle.color(1), 'LineWidth', 1.5, ...
                'DisplayName', CartPlotStyle.label(1));
            obj.ResponsePhaseLine = plot(obj.AxResponsePhase, NaN, NaN, '-', ...
                'Color', CartPlotStyle.color(1), 'LineWidth', 1.5, ...
                'DisplayName', CartPlotStyle.label(1));
            obj.ResponseMagLine2 = plot(obj.AxResponseMag, NaN, NaN, '-', ...
                'Color', CartPlotStyle.color(2), 'LineWidth', 1.5, ...
                'DisplayName', CartPlotStyle.label(2));
            obj.ResponsePhaseLine2 = plot(obj.AxResponsePhase, NaN, NaN, '-', ...
                'Color', CartPlotStyle.color(2), 'LineWidth', 1.5, ...
                'DisplayName', CartPlotStyle.label(2));
            obj.ResponseMagLine2.Visible = 'off';
            obj.ResponsePhaseLine2.Visible = 'off';

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

        function updateResponse(obj, spec, cart)
            if nargin < 3 || isempty(cart)
                cart = 1;
            end
            if cart == 2
                magLine = obj.ResponseMagLine2;
                phaseLine = obj.ResponsePhaseLine2;
            else
                magLine = obj.ResponseMagLine;
                phaseLine = obj.ResponsePhaseLine;
            end
            obj.setSpectrumLines(obj.AxResponseMag, magLine, ...
                obj.AxResponsePhase, phaseLine, spec);
            obj.applyCartVisibility();
        end

        function setCartVisible(obj, showCart1, showCart2)
            obj.ShowCart1 = logical(showCart1);
            obj.ShowCart2 = logical(showCart2);
            obj.applyCartVisibility();
        end

        function clearPlots(obj)
            empty = FftAnalyzer.emptySpectrum();
            obj.updateForcing(empty);
            obj.updateResponse(empty, 1);
            obj.updateResponse(empty, 2);
        end
    end

    methods (Access = private)
        function ax = createPlotCell(obj, row, col, yLabel)
            ax = uiaxes(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            ax.Layout.Row = row;
            ax.Layout.Column = col;
            xlabel(ax, 'Frequency (Hz)');
            ylabel(ax, yLabel);
            ax.XLim = FftAnalyzer.displayXLim();
        end

        function setSpectrumLines(~, magAx, magLine, phaseAx, phaseLine, spec)
            xLim = FftAnalyzer.displayXLim();
            if nargin < 6 || isempty(spec) || spec.n == 0 || isempty(spec.freq)
                set(magLine, 'XData', NaN, 'YData', NaN);
                set(phaseLine, 'XData', NaN, 'YData', NaN);
                magAx.XLim = xLim;
                phaseAx.XLim = xLim;
                return;
            end
            set(magLine, 'XData', spec.freq, 'YData', spec.mag);
            set(phaseLine, 'XData', spec.freq, 'YData', spec.phase);
            magAx.XLim = xLim;
            phaseAx.XLim = xLim;
            ylim(phaseAx, [-180, 180]);
        end

        function applyCartVisibility(obj)
            if ~isempty(obj.ResponseMagLine) && isvalid(obj.ResponseMagLine)
                obj.ResponseMagLine.Visible = CartPlotStyle.onOff(obj.ShowCart1);
                obj.ResponsePhaseLine.Visible = CartPlotStyle.onOff(obj.ShowCart1);
            end
            if ~isempty(obj.ResponseMagLine2) && isvalid(obj.ResponseMagLine2)
                obj.ResponseMagLine2.Visible = CartPlotStyle.onOff(obj.ShowCart2);
                obj.ResponsePhaseLine2.Visible = CartPlotStyle.onOff(obj.ShowCart2);
            end
            CartPlotStyle.applyLegend(obj.AxResponseMag, ...
                obj.ResponseMagLine, obj.ResponseMagLine2, ...
                obj.ShowCart1, obj.ShowCart2);
            CartPlotStyle.applyLegend(obj.AxResponsePhase, ...
                obj.ResponsePhaseLine, obj.ResponsePhaseLine2, ...
                obj.ShowCart1, obj.ShowCart2);
        end
    end
end
