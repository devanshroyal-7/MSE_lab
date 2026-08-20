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
        AxMag
        AxPhase
        AxCoherence
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
        end
    end
end
