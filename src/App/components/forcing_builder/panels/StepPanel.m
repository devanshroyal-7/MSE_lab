classdef StepPanel < handle
    % Function-setup UI for StepSignal (magnitude, on time, off time).
    %
    %{
    Example usage:

    >> fig = uifigure;
    >> panel = StepPanel(fig);
    >> sig = panel.createSignal;
    >> panel.populate(StepSignal(2, 5, 1));

    %}

    properties
        MainLayoutGrid
        MagEditField
        OnTimeEditField
        OffTimeEditField
        ValueChangedCallback
    end

    methods
        function obj = StepPanel(parentContainer)
            % Construct the programmatic parameters layout grid
            obj.MainLayoutGrid = uigridlayout(parentContainer, [3, 2]);
            obj.MainLayoutGrid.RowHeight = {30, 30, 30};
            obj.MainLayoutGrid.ColumnWidth = {130, '1x'};

            % Render standard fields
            uilabel(obj.MainLayoutGrid, 'Text', 'Magnitude (N):');
            obj.MagEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 1.0);
            obj.MagEditField.ValueChangedFcn = @(~, ~) obj.parameterChanged;

            uilabel(obj.MainLayoutGrid, 'Text', 'On Time (s):');
            obj.OnTimeEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 1.0);
            obj.OnTimeEditField.ValueChangedFcn = @(~, ~) obj.parameterChanged;

            uilabel(obj.MainLayoutGrid, 'Text', 'Off Time (s):');
            obj.OffTimeEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 0.0);
            obj.OffTimeEditField.ValueChangedFcn = @(~, ~) obj.parameterChanged;
        end

        function gridHandle = getLayout(obj)
            gridHandle = obj.MainLayoutGrid;
        end

        function populate(obj, signal)
            obj.MagEditField.Value      = signal.Magnitude;
            obj.OnTimeEditField.Value   = signal.OnTime;
            obj.OffTimeEditField.Value  = signal.OffTime;
        end

        function signal = createSignal(obj)
            signal = StepSignal( ...
                obj.MagEditField.Value, ...
                obj.OnTimeEditField.Value, ...
                obj.OffTimeEditField.Value);
        end

        function parameterChanged(obj)
            if ~isempty(obj.ValueChangedCallback)
                obj.ValueChangedCallback();
            end
        end
    end
end