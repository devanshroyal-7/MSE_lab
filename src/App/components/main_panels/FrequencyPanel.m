classdef FrequencyPanel < handle
    % Frequency-domain tab: 2x2 FFT grid (forcing | response) x (magnitude / phase).
    % Axes are empty until the controller writes spectra after a run.
    % FRF lives on FRFPanel.
    %
    %{
    Example usage:

    >> fig = uifigure("Position", [100, 100, 800, 700]);
    >> panel = FrequencyPanel(fig);
    >> plot(panel.AxForcingMag, freq, magF);
    >> plot(panel.AxForcingPhase, freq, phaseF);
    >> plot(panel.AxResponseMag, freq, magX);
    >> plot(panel.AxResponsePhase, freq, phaseX);

    %}

    properties
        MainLayoutGrid
        ForcingMagLabel
        AxForcingMag
        ForcingPhaseLabel
        AxForcingPhase
        ResponseMagLabel
        AxResponseMag
        ResponsePhaseLabel
        AxResponsePhase
    end
    methods
        function obj = FrequencyPanel(parentContainer)
            % Same pattern as TimePanel: labels + axes on one grid, no nested panels.
            obj.MainLayoutGrid = uigridlayout(parentContainer, [4, 2]);
            obj.MainLayoutGrid.ColumnWidth = {'1x', '1x'};
            obj.MainLayoutGrid.RowHeight = {30, '1x', 30, '1x'};
            obj.MainLayoutGrid.RowSpacing = 5;

            [obj.ForcingMagLabel, obj.AxForcingMag] = obj.createPlotCell( ...
                1, 2, 1, "Forcing FFT Magnitude", "Magnitude (N)");
            [obj.ResponseMagLabel, obj.AxResponseMag] = obj.createPlotCell( ...
                1, 2, 2, "Response FFT Magnitude", "Magnitude (m)");
            [obj.ForcingPhaseLabel, obj.AxForcingPhase] = obj.createPlotCell( ...
                3, 4, 1, "Forcing FFT Phase", "Phase (deg)");
            [obj.ResponsePhaseLabel, obj.AxResponsePhase] = obj.createPlotCell( ...
                3, 4, 2, "Response FFT Phase", "Phase (deg)");

            ylim(obj.AxForcingPhase, [-180, 180]);
            ylim(obj.AxResponsePhase, [-180, 180]);
        end
    end

    methods (Access = private)
        function [label, ax] = createPlotCell(obj, labelRow, axesRow, col, titleText, yLabel)
            label = uilabel(obj.MainLayoutGrid, ...
                "Text", titleText, ...
                "FontWeight", "bold", ...
                "FontSize", 17, ...
                "VerticalAlignment", "bottom");
            label.Layout.Row = labelRow;
            label.Layout.Column = col;

            ax = uiaxes(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            ax.Layout.Row = axesRow;
            ax.Layout.Column = col;
            xlabel(ax, 'Frequency (Hz)');
            ylabel(ax, yLabel);
        end
    end
end
