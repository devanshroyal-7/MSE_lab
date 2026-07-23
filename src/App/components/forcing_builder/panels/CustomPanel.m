classdef CustomPanel < handle
    properties
       MainLayoutGrid
       CustomLabel
       ValidLabel
       ValidLamp
       CustomEditField
       DurationLabel
       DurationEditField
    end

    methods
        function obj = CustomPanel(parentContainer)
            % Construct the programmatic parameter layout grid
            obj.MainLayoutGrid = uigridlayout(parentContainer, [3, 3]);
            obj.MainLayoutGrid.RowHeight = {30, 90, 30};
            obj.MainLayoutGrid.ColumnWidth = {130, '1x', 30};

            % Render standard fields
            obj.CustomLabel = uilabel(obj.MainLayoutGrid, 'Text', 'Function F(t) in N:');
            obj.CustomLabel.Layout.Row = 1;
            obj.CustomLabel.Layout.Column = 1;

            obj.ValidLabel = uilabel(obj.MainLayoutGrid, 'Text', 'Valid');
            obj.ValidLabel.Layout.Row = 1;
            obj.ValidLabel.Layout.Column = 2;
            obj.ValidLabel.HorizontalAlignment = 'right';

            obj.ValidLamp = uilamp(obj.MainLayoutGrid, "Color", "green");
            obj.ValidLamp.Layout.Row = 1;
            obj.ValidLamp.Layout.Column = 3;

            obj.CustomEditField = uieditfield(obj.MainLayoutGrid, 'text','Value', 'sin(2*t)');
            obj.CustomEditField.Layout.Row = 2;
            obj.CustomEditField.Layout.Column = [1, 3];

            obj.DurationLabel = uilabel(obj.MainLayoutGrid, 'Text', 'Duration (s):');
            obj.DurationLabel.Layout.Row = 3;
            obj.DurationLabel.Layout.Column = 1;
            
            obj.DurationEditField = uieditfield(obj.MainLayoutGrid, "numeric", "Value", 10);
            obj.DurationEditField.Layout.Row = 3;
            obj.DurationEditField.Layout.Column = [2, 3];
        end

        function gridHandle = getLayout(obj)
            gridHandle = obj.MainLayoutGrid;
        end

        function populate(obj, signal)
            obj.CustomEditField.Value     = signal.Expression;
            obj.DurationEditField.Value   = signal.Duration;
        end

        function signal = createSignal(obj)
            signal = CustomSignal( ...
                obj.CustomEditField.Value, ...
                obj.DurationEditField.Value);
        end
    end
end
