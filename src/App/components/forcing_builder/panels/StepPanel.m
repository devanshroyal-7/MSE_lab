classdef StepPanel < handle
    properties
        MainLayoutGrid
        MagEditField
        OnTimeEditField
        OffTimeEditField
    end

    methods
        function obj = StepPanel(parentContainer)
            % Construct the programmatic parameters layout grid
            obj.MainLayoutGrid = uigridlayout(parentContainer, [3, 2]);
            obj.MainLayoutGrid.RowHeight = {30, 30, 30};
            obj.MainLayoutGrid.ColumnWidth = {100, '1x'};

            % Render standard fields
            uilabel(obj.MainLayoutGrid, 'Text', 'Magnitude (N):');
            obj.MagEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 1.0);

            uilabel(obj.MainLayoutGrid, 'Text', 'On Time (s):');
            obj.OnTimeEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 1.0);

            uilabel(obj.MainLayoutGrid, 'Text', 'Off Time (s):');
            obj.OffTimeEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 0.0);
        end

        function gridHandle = getLayout(obj)
            gridHandle = obj.MainLayoutGrid;
        end
    end
end