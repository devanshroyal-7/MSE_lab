classdef FrequencyPanel < handle
    % Frequency-domain tab: 2x2 FFT grid (forcing | response) x (magnitude / phase).
    % Axes are empty until the controller writes spectra after a run.
    % FRF lives on a separate tab (not built here).
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
            obj.MainLayoutGrid = uigridlayout(parentContainer, [2, 2]);
            obj.MainLayoutGrid.ColumnWidth = {'1x', '1x'};
            obj.MainLayoutGrid.RowHeight = {'1x', '1x'};
            obj.MainLayoutGrid.RowSpacing = 5;
            obj.MainLayoutGrid.ColumnSpacing = 10;

            [obj.ForcingMagLabel, obj.AxForcingMag] = obj.createPlotCell( ...
                1, 1, "Forcing FFT Magnitude", "Magnitude (N)");
            [obj.ResponseMagLabel, obj.AxResponseMag] = obj.createPlotCell( ...
                1, 2, "Response FFT Magnitude", "Magnitude (m)");
            [obj.ForcingPhaseLabel, obj.AxForcingPhase] = obj.createPlotCell( ...
                2, 1, "Forcing FFT Phase", "Phase (deg)");
            [obj.ResponsePhaseLabel, obj.AxResponsePhase] = obj.createPlotCell( ...
                2, 2, "Response FFT Phase", "Phase (deg)");

            ylim(obj.AxForcingPhase, [-180, 180]);
            ylim(obj.AxResponsePhase, [-180, 180]);
        end
    end

    methods (Access = private)
        function [label, ax] = createPlotCell(obj, row, col, titleText, yLabel)
            cellPanel = uipanel(obj.MainLayoutGrid);
            cellPanel.Layout.Row = row;
            cellPanel.Layout.Column = col;

            cellGrid = uigridlayout(cellPanel, [2, 1]);
            cellGrid.RowHeight = {30, '1x'};
            cellGrid.RowSpacing = 5;
            cellGrid.Padding = [5, 5, 5, 5];

            label = uilabel(cellGrid, ...
                "Text", titleText, ...
                "FontWeight", "bold", ...
                "FontSize", 17, ...
                "VerticalAlignment", "bottom");
            label.Layout.Row = 1;

            ax = uiaxes(cellGrid, "XGrid", "on", "YGrid", "on");
            ax.Layout.Row = 2;
            xlabel(ax, 'Frequency (Hz)');
            ylabel(ax, yLabel);
        end
    end
end
