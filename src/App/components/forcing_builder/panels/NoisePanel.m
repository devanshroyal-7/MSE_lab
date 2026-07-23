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

        function populate(obj, signal)
            obj.AmpEditField.Value = signal.Amplitude;
            obj.LowerFreqEditField.Value = signal.LowerFrequency;
            obj.UpperFreqEditField.Value = signal.UpperFrequency;
            obj.DurationEditField.Value = signal.Duration;
            obj.SeedEditField.Value = signal.Seed;
        end

        function signal = createSignal(obj)
            signal = NoiseSignal( ...
                obj.AmpEditField.Value, ...
                obj.LowerFreqEditField.Value, ...
                obj.UpperFreqEditField.Value, ...
                obj.DurationEditField.Value, ...
                obj.SeedEditField.Value);
        end
    end
end