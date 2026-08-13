classdef SweptSinePanel < handle
    % Function-setup UI for SweptSineSignal (amplitude, start/end Hz, duration).
    %
    %{
    Example usage:

    >> fig = uifigure;
    >> panel = SweptSinePanel(fig);
    >> sig = panel.createSignal;
    >> panel.populate(SweptSineSignal(1.6, 1, 20, 15));

    %}

    properties
        MainLayoutGrid
        AmpEditField
        StartFreqEditField
        EndFreqEditField
        DurationEditField
        ValueChangedCallback
    end

    methods
        function obj = SweptSinePanel(parentContainer)
            % Construct the programmatic parameters layout grid
            obj.MainLayoutGrid = uigridlayout(parentContainer, [5, 2]);
            obj.MainLayoutGrid.RowHeight = {30, 30, 30, 30};
            obj.MainLayoutGrid.ColumnWidth = {130, '1x'};

            % Render standard fields
            uilabel(obj.MainLayoutGrid, 'Text', 'Amplitude (N):');
            obj.AmpEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 1.0);
            obj.AmpEditField.ValueChangedFcn = @(~, ~) obj.parameterChanged();

            uilabel(obj.MainLayoutGrid, 'Text', 'Start Frequency (Hz):');
            obj.StartFreqEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 1.0);
            obj.StartFreqEditField.ValueChangedFcn = @(~, ~) obj.parameterChanged();

            uilabel(obj.MainLayoutGrid, 'Text', 'End Frequency (Hz):');
            obj.EndFreqEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 10.0);
            obj.EndFreqEditField.ValueChangedFcn = @(~, ~) obj.parameterChanged();

            uilabel(obj.MainLayoutGrid, 'Text', 'Duration (s):');
            obj.DurationEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 10.0);
            obj.DurationEditField.ValueChangedFcn = @(~, ~) obj.parameterChanged();
        end

        function gridHandle = getLayout(obj)
            gridHandle = obj.MainLayoutGrid;
        end

        function populate(obj, signal)
            obj.AmpEditField.Value          = signal.Amplitude;
            obj.StartFreqEditField.Value    = signal.StartFrequency;
            obj.EndFreqEditField.Value      = signal.EndFrequency;
            obj.DurationEditField.Value     = signal.Duration;
        end

        function signal = createSignal(obj)
            signal = SweptSineSignal( ...
            obj.AmpEditField.Value, ...
            obj.StartFreqEditField.Value, ...
            obj.EndFreqEditField.Value, ...
            obj.DurationEditField.Value);
        end

        function parameterChanged(obj)
            if ~isempty(obj.ValueChangedCallback)
                obj.ValueChangedCallback();
            end
        end
    end
end