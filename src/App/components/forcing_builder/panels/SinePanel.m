classdef SinePanel < handle
    % Function-setup UI for SineSignal (amplitude, Hz, phase, duration).
    %
    %{
    Example usage:

    >> fig = uifigure;
    >> panel = SinePanel(fig);
    >> sig = panel.createSignal;          % SineSignal from current fields
    >> panel.populate(SineSignal(2, 5, 0, 10));

    %}

    properties
        MainLayoutGrid
        AmpEditField
        FreqEditField
        PhaseEditField
        DurationEditField
        ValueChangedCallback
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
            obj.AmpEditField.ValueChangedFcn = @(~, ~) obj.parameterChanged();

            uilabel(obj.MainLayoutGrid, 'Text', 'Frequency (Hz):');
            obj.FreqEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 1.0);
            obj.FreqEditField.ValueChangedFcn = @(~, ~) obj.parameterChanged();

            uilabel(obj.MainLayoutGrid, 'Text', 'Phase (Deg):');
            obj.PhaseEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 0.0);
            obj.PhaseEditField.ValueChangedFcn = @(~, ~) obj.parameterChanged();

            uilabel(obj.MainLayoutGrid, 'Text', 'Duration (s):');
            obj.DurationEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 5.0);
            obj.DurationEditField.ValueChangedFcn = @(~, ~) obj.parameterChanged();
        end

        function gridHandle = getLayout(obj)
            gridHandle = obj.MainLayoutGrid;
        end

        function populate(obj, signal)
            obj.AmpEditField.Value      = signal.Amplitude;
            obj.FreqEditField.Value     = signal.Frequency;
            obj.PhaseEditField.Value    = signal.InitPhase;
            obj.DurationEditField.Value = signal.Duration;
        end

        function signal = createSignal(obj)
            signal = SineSignal( ...
                obj.AmpEditField.Value, ...
                obj.FreqEditField.Value, ...
                obj.PhaseEditField.Value, ...
                obj.DurationEditField.Value);
        end

        function parameterChanged(obj)
            if ~isempty(obj.ValueChangedCallback)
                obj.ValueChangedCallback();
            end
        end
    end
end