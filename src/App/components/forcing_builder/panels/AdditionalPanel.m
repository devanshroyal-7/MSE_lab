classdef AdditionalPanel < handle
    properties
        MainLayoutGrid
        OffsetLabel
        DelayLabel
        DwellLabel
        RepeatedLabel
        OffsetEditField
        DelayEditField
        DwellEditField
        RepeatEditField
    end

    methods
        function obj = AdditionalPanel(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [4, 2]);
            obj.MainLayoutGrid.RowHeight = {30, 30, 30, 30};
            obj.MainLayoutGrid.ColumnWidth = {130, '1x'};

            obj.OffsetLabel = uilabel(obj.MainLayoutGrid, "Text", "Offset (N)");
            obj.OffsetEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 0);
            
            obj.DelayLabel = uilabel(obj.MainLayoutGrid, "Text", "Delay (Before) (s)");
            obj.DelayEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 0);
            
            obj.DwellLabel = uilabel(obj.MainLayoutGrid, "Text", "Dwell (After) (s)");
            obj.DwellEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 0);
            
            obj.RepeatedLabel = uilabel(obj.MainLayoutGrid, "Text", "Repeat Cycle(s)");
            obj.RepeatEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 0);
        end
    end
end

        