classdef TimePanel < handle
    % use "Position" [x, x, 1100, 640] for this Panel
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
            obj.MainLayoutGrid = uigridlayout(parentContainer, [3, 2]);
            obj.MainLayoutGrid.ColumnWidth = {'1x', '1x'};
            obj.MainLayoutGrid.RowHeight = {30, 300, 30};

            obj.ResponseLabel = uilabel(obj.MainLayoutGrid, "Text", "Response Plot", "FontWeight", "bold", "FontSize", 17, "VerticalAlignment", "bottom");
            obj.ResponseLabel.Layout.Column = 1;
            obj.ResponseLabel.Layout.Row = 1;

            padTimescope = uigridlayout(obj.MainLayoutGrid, [1, 1]);
            padTimescope.Padding = [0, 17, 0, 20];
            padTimescope.Layout.Column = 1;
            padTimescope.Layout.Row = 2;
            obj.ResponsePlot = uitimescope(padTimescope, "XGrid", "on", "YGrid", "on");
            
            obj.ReferenceLabel = uilabel(obj.MainLayoutGrid, "Text", "Reference Plot", "FontWeight", "bold", "FontSize", 17, "VerticalAlignment", "bottom");
            obj.ReferenceLabel.Layout.Column = 2;
            obj.ReferenceLabel.Layout.Row = 1;

            obj.ReferencePlot = uiaxes(obj.MainLayoutGrid);
            obj.ReferencePlot.Layout.Column = 2;
            obj.ReferencePlot.Layout.Row = 2;

            padCheckbox = uigridlayout(obj.MainLayoutGrid, [1, 1]);
            padCheckbox.Padding = [5, 0, 0, 0];
            padCheckbox.Layout.Column = 1;
            padCheckbox.Layout.Row = 3;
            obj.OverlayCheckBox = uicheckbox(padCheckbox, "Text", "  Overlay Reference", "Value", false);
            
            padButton = uigridlayout(obj.MainLayoutGrid, [1, 3]);
            padButton.Layout.Column = 2;
            padButton.Layout.Row = 3;
            padButton.Padding = [0, 0, 0, 0];
            obj.SignalButton = uibutton(padButton, "Text", "Create Forcing Function");
            obj.SignalButton.Layout.Column = 3;
        end
    end
end