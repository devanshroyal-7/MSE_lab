classdef TimePanel < handle
    properties
        MainLayoutGrid
        ResponseLabel
        ResponsePlot
        ReferenceLabel
        ReferencePlot
        OverlayCheckBox
        SignalButton
    end
    methods
        function obj = TimePanel(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [6, 2]);
            obj.MainLayoutGrid.ColumnWidth = {'1x', '1x'};
            obj.MainLayoutGrid.RowHeight = {30, '1x', 35, 30, '1x', 30};
            obj.MainLayoutGrid.RowSpacing = 5;

            % Response Section (Top)
            obj.ResponseLabel = uilabel(obj.MainLayoutGrid, ...
                "Text", "Response Plot", ...
                "FontWeight", "bold", ...
                "FontSize", 17, ...
                "VerticalAlignment", "bottom");
            obj.ResponseLabel.Layout.Column = [1 2];
            obj.ResponseLabel.Layout.Row = 1;
            
            obj.ResponsePlot = uitimescope(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            obj.ResponsePlot.Layout.Column = [1 2];
            obj.ResponsePlot.Layout.Row = 2;
            
            % Controls Section (Middle - Overlay Checkbox)
            padCheckbox = uigridlayout(obj.MainLayoutGrid, [1, 2]);
            % [left, bottom, right, top] padding. 10px top padding separates it from the plot
            padCheckbox.Padding = [0, 0, 0, 10]; 
            padCheckbox.Layout.Column = 2; % Place in the right column of main grid
            padCheckbox.Layout.Row = 3; 
            padCheckbox.ColumnWidth = {'1x', 140}; % Push checkbox to the right edge
            
            obj.OverlayCheckBox = uicheckbox(padCheckbox, "Text", "Overlay Reference", "Value", false);
            obj.OverlayCheckBox.Layout.Column = 2;
            
            % Reference Section (Bottom)
            obj.ReferenceLabel = uilabel(obj.MainLayoutGrid, ...
                "Text", "Reference Plot", ...
                "FontWeight", "bold", ...
                "FontSize", 17, ...
                "VerticalAlignment", "bottom");
            obj.ReferenceLabel.Layout.Column = [1 2];
            obj.ReferenceLabel.Layout.Row = 4; 
            
            obj.ReferencePlot = uiaxes(obj.MainLayoutGrid, "XGrid", "on", "YGrid", "on");
            obj.ReferencePlot.Layout.Column = [1 2];
            obj.ReferencePlot.Layout.Row = 5; 
            
            % Controls Section (Bottom - Signal Button)
            padButton = uigridlayout(obj.MainLayoutGrid, [1, 2]);
            padButton.Padding = [0, 0, 0, 0];
            padButton.Layout.Column = 2;
            padButton.Layout.Row = 6; 
            padButton.ColumnWidth = {'1x', 200};
            
            obj.SignalButton = uibutton(padButton, "Text", "Create Forcing Function");
            obj.SignalButton.Layout.Column = 2;
        end
    end
end