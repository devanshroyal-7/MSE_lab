classdef ZeroOutputPanel < handle
    properties
        MainLayoutGrid
        DurationEditField
    end

    methods
        function obj = ZeroOutputPanel(parentContainer)
            % Construct the programmatic parameters layout grid
            obj.MainLayoutGrid = uigridlayout(parentContainer, [1, 2]);
            obj.MainLayoutGrid.RowHeight = {30};
            obj.MainLayoutGrid.ColumnWidth = {130, '1x'};

            % Render standard fields
            uilabel(obj.MainLayoutGrid, 'Text', 'Duration (s):');
            obj.DurationEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 10.0);
        end

        function gridHandle = getLayout(obj)
            gridHandle = obj.MainLayoutGrid;
        end

        function populate(obj, signal)
            obj.DurationEditField.Value = signal.Duration;
        end

        function signal = createSignal(obj)
            signal = ZeroOutputSignal( ...
                obj.DurationEditField.Value);
        end
    end
end