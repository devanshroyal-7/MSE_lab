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
        MagLabel
        AxMag
        PhaseLabel
        AxPhase

        MagLine
        PhaseLine
    end
    methods
        function obj = ControlsFrequencyPanel(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [4, 1]);
            obj.MainLayoutGrid.RowHeight = {30, '1x', 30, '1x'};
            obj.MainLayoutGrid.RowSpacing = 5;

            obj.MagLabel = uilabel(obj.MainLayoutGrid, ...
                "Text", "Bode Magnitude", ...
                "FontWeight", "bold", ...
                "FontSize", 17, ...
                "VerticalAlignment", "bottom");
            obj.MagLabel.Layout.Row = 1;

            obj.AxMag = uiaxes(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            obj.AxMag.Layout.Row = 2;
            obj.AxMag.XScale = 'log';
            xlabel(obj.AxMag, 'Frequency (Hz)');
            ylabel(obj.AxMag, 'Magnitude (dB)');

            obj.PhaseLabel = uilabel(obj.MainLayoutGrid, ...
                "Text", "Bode Phase", ...
                "FontWeight", "bold", ...
                "FontSize", 17, ...
                "VerticalAlignment", "bottom");
            obj.PhaseLabel.Layout.Row = 3;

            obj.AxPhase = uiaxes(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            obj.AxPhase.Layout.Row = 4;
            obj.AxPhase.XScale = 'log';
            xlabel(obj.AxPhase, 'Frequency (Hz)');
            ylabel(obj.AxPhase, 'Phase (deg)');
            ylim(obj.AxPhase, [-180, 180]);

            obj.MagLine = plot(obj.AxMag, NaN, NaN, 'b-', LineWidth=1.5);
            obj.PhaseLine = plot(obj.AxPhase, NaN, NaN, 'b-', LineWidth=1.5);
        end
    end
end
