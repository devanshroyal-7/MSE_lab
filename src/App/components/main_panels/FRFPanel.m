classdef FRFPanel < handle
    % FRF tab: magnitude, phase, then coherence, stacked full-width.
    % Axes are empty until the controller writes spectra after a run.
    %
    %{
    Example usage:

    >> fig = uifigure("Position", [100, 100, 800, 700]);
    >> panel = FRFPanel(fig);
    >> plot(panel.AxMag, freq, magH);
    >> plot(panel.AxPhase, freq, phaseH);
    >> plot(panel.AxCoherence, freq, coh);

    %}

    properties
        MainLayoutGrid
        MagLabel
        AxMag
        PhaseLabel
        AxPhase
        CoherenceLabel
        AxCoherence
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
        end
    end
end
