classdef NoisePanel < handle
    properties
        MainLayoutGrid
        AmpEditField
        LowerFreqEditField
        UpperFreqEditField
        DurationEditField
        SeedEditField
    end

    methods
        function obj = NoisePanel(parentContainer)
            % Construct the programmatic parameters layout grid
            obj.MainLayoutGrid = uigridlayout(parentContainer, [5, 2]);
            obj.MainLayoutGrid.RowHeight = {30, 30, 30, 30, 30};
            obj.MainLayoutGrid.ColumnWidth = {130, '1x'};

            % Render standard fields
            uilabel(obj.MainLayoutGrid, 'Text', 'Amplitude (N):');
            obj.AmpEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 1.0);

            uilabel(obj.MainLayoutGrid, 'Text', 'Lower Frequency (Hz):');
            obj.LowerFreqEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 1.0);

            uilabel(obj.MainLayoutGrid, 'Text', 'Upper Frequency (Hz):');
            obj.UpperFreqEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 10.0);

            uilabel(obj.MainLayoutGrid, 'Text', 'Duration (s):');
            obj.DurationEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 10.0);

            uilabel(obj.MainLayoutGrid, 'Text', 'Seed:');
            obj.SeedEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 42.0);
        end

        function gridHandle = getLayout(obj)
            gridHandle = obj.MainLayoutGrid;
        end
    end
end