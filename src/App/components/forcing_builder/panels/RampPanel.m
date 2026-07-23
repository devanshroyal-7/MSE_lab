classdef RampPanel < handle
    properties
        MainLayoutGrid
        SlopeEditField
        DurationEditField
        DwellTimeEditField
        DwellLocSwitch
        TwoSidedCheckBox
        MirroredCheckBox
    end

    methods
        function obj = RampPanel(parentContainer)
            % Construct the programmatic parameters layout grid
            obj.MainLayoutGrid = uigridlayout(parentContainer, [6, 2]);
            obj.MainLayoutGrid.RowHeight = {30, 30, 30, 30, 30, 30};
            obj.MainLayoutGrid.ColumnWidth = {130, '1x'};

            % Render standard fields
            uilabel(obj.MainLayoutGrid, 'Text', 'Slope (N/s):');
            obj.SlopeEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 0.4);

            uilabel(obj.MainLayoutGrid, 'Text', 'Duration (s):');
            obj.DurationEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 10.0);

            uilabel(obj.MainLayoutGrid, 'Text', 'Dwell Time (s):');
            obj.DwellTimeEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 0);

            uilabel(obj.MainLayoutGrid, 'Text', 'Dwell Time Location:');
            obj.DwellLocSwitch = uiswitch(obj.MainLayoutGrid, "Items", ["beginning", "end"]);

            uilabel(obj.MainLayoutGrid, 'Text', 'Twosided:');
            obj.TwoSidedCheckBox = uicheckbox(obj.MainLayoutGrid, "Text", "");

            uilabel(obj.MainLayoutGrid, 'Text', "Mirrored:");
            obj.MirroredCheckBox = uicheckbox(obj.MainLayoutGrid, "Text", "");
        end

        function gridHandle = getLayout(obj)
            gridHandle = obj.MainLayoutGrid;
        end

        function populate(obj, signal)
            obj.DurationEditField.Value     = signal.Duration;
            obj.SlopeEditField.Value        = signal.Slope;
            obj.DwellTimeEditField.Value    = signal.DwellTime;
            obj.DwellLocSwitch.Value        = signal.DwellLoc;
            obj.TwoSidedCheckBox.Value      = signal.TwoSided;
            obj.MirroredCheckBox.Value      = signal.Mirrored;
        end

        function signal = createSignal(obj)
            signal = RampSignal( ...
            obj.SlopeEditField.Value, ...
            obj.DurationEditField.Value, ...
            obj.DwellTimeEditField.Value, ...
            obj.DwellLocSwitch.Value, ...
            obj.TwoSidedCheckBox.Value, ...
            obj.MirroredCheckBox.Value);
        end
    end
end