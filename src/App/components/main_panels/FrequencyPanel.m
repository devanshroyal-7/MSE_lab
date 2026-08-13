classdef FrequencyPanel < handle
    % Frequency-domain tab: FFT of forcing, FFT of response, then FRF (m/N).
    % Axes are empty until the controller writes spectra after a run.
    %
    %{
    Example usage:

    >> fig = uifigure("Position", [100, 100, 800, 700]);
    >> panel = FrequencyPanel(fig);
    >> plot(panel.AxForcing, freq, magF);
    >> plot(panel.AxResponse, freq, magX);
    >> plot(panel.AxFRF, freq, magX ./ magF);

    %}

    properties
        MainLayoutGrid
        ForcingLabel
        AxForcing
        ResponseLabel
        AxResponse
        FRFLabel
        AxFRF
    end
    methods 
        function obj = FrequencyPanel(parentContainer)
            % 6-row grid: alternating labels (30px) and axes (1x)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [6, 1]);
            obj.MainLayoutGrid.RowHeight = {30, '1x', 30, '1x', 30, '1x'}; 
            obj.MainLayoutGrid.RowSpacing = 5; % Matches TimePanel spacing
            
            % Forcing FFT
            obj.ForcingLabel = uilabel(obj.MainLayoutGrid, ...
                "Text", "Forcing FFT", ...
                "FontWeight", "bold", ...
                "FontSize", 17, ...
                "VerticalAlignment", "bottom");
            obj.ForcingLabel.Layout.Row = 1;
            
            obj.AxForcing = uiaxes(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            obj.AxForcing.Layout.Row = 2;
            xlabel(obj.AxForcing, 'Frequency (Hz)');
            ylabel(obj.AxForcing, 'Magnitude (N)');
                
            % Response FFT
            obj.ResponseLabel = uilabel(obj.MainLayoutGrid, ...
                "Text", "Response FFT", ...
                "FontWeight", "bold", ...
                "FontSize", 17, ...
                "VerticalAlignment", "bottom");
            obj.ResponseLabel.Layout.Row = 3;
            
            obj.AxResponse = uiaxes(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            obj.AxResponse.Layout.Row = 4;
            xlabel(obj.AxResponse, 'Frequency (Hz)');
            ylabel(obj.AxResponse, 'Magnitude (m)');
                
            % FRF
            obj.FRFLabel = uilabel(obj.MainLayoutGrid, ...
                "Text", "Frequency Response Function (FRF)", ...
                "FontWeight", "bold", ...
                "FontSize", 17, ...
                "VerticalAlignment", "bottom");
            obj.FRFLabel.Layout.Row = 5;
            
            obj.AxFRF = uiaxes(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            obj.AxFRF.Layout.Row = 6;
            xlabel(obj.AxFRF, 'Frequency (Hz)');
            ylabel(obj.AxFRF, 'Magnitude (m/N)');
        end
    end
end