classdef OverallPanel < handle
    properties
        MainLayoutGrid
        AvailableLabel
        AvailableListBox
        OverallLabel
        OverallListBox
        ClearButton
        AddButton
        RemoveButton
    end

    methods
        function obj = OverallPanel(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [4, 3]);
            obj.MainLayoutGrid.RowHeight = {30, 150, 30, 30};
            obj.MainLayoutGrid.ColumnWidth = {150, 75, 75};

            obj.AvailableLabel = uilabel(obj.MainLayoutGrid, "Text", "Available", "FontWeight", "bold");
            
            obj.OverallLabel = uilabel(obj.MainLayoutGrid, "Text", "Overall", "FontWeight", "bold");

            obj.AvailableListBox = uilistbox(obj.MainLayoutGrid, "Items", ["Custom", "Noise", "Ramp", "Sine", "Step", "Swept Sine", "Zero Output"]);

            obj.OverallListBox = uilistbox(obj.MainLayoutGrid);

            obj.AddButton = uibutton(obj.MainLayoutGrid, "Text", "Add");
            
            obj.RemoveButton = uibutton(obj.MainLayoutGrid, "Text", "Remove");

            obj.ClearButton = uibutton(obj.MainLayoutGrid, "Text", "Clear");

            obj.layoutComponent();
        end

        function layoutComponent(obj)
            obj.AvailableLabel.Layout.Row = 1;
            obj.AvailableLabel.Layout.Column = 1;

            obj.OverallLabel.Layout.Row = 1;
            obj.OverallLabel.Layout.Column = [2, 3];

            obj.AvailableListBox.Layout.Row = 2;
            obj.AvailableListBox.Layout.Column = 1;

            obj.OverallListBox.Layout.Row = 2;
            obj.OverallListBox.Layout.Column = [2, 3];

            obj.AddButton.Layout.Row = 3;
            obj.AddButton.Layout.Column = 2;

            obj.RemoveButton.Layout.Row = 3;
            obj.RemoveButton.Layout.Column = 3;

            obj.ClearButton.Layout.Row = 4;
            obj.ClearButton.Layout.Column = [2, 3];
        end
    end
end