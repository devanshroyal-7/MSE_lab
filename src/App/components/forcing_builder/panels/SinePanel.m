classdef SinePanel < handle
    properties
        MainLayoutGrid
        AmpEditField
        FreqEditField
        PhaseEditField
        DurationEditField
    end

    methods
        function obj = SinePanel(parentContainer)
            % Construct the programmatic parameters layout grid
            obj.MainLayoutGrid = uigridlayout(parentContainer, [4, 2]);
            obj.MainLayoutGrid.RowHeight = {30, 30, 30, 30};
            obj.MainLayoutGrid.ColumnWidth = {130, '1x'};

            % Render standard fields
            uilabel(obj.MainLayoutGrid, 'Text', 'Amplitude (N):');
            obj.AmpEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 1.0);

            uilabel(obj.MainLayoutGrid, 'Text', 'Frequency (Hz):');
            obj.FreqEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 1.0);

            uilabel(obj.MainLayoutGrid, 'Text', 'Phase (Deg):');
            obj.PhaseEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 0.0);

            uilabel(obj.MainLayoutGrid, 'Text', 'Duration (s):');
            obj.DurationEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 5.0);
        end

        function gridHandle = getLayout(obj)
            gridHandle = obj.MainLayoutGrid;
        end
    end
end