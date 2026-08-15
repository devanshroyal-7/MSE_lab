classdef AdditionalPanel < handle
<<<<<<< HEAD
    % Offset / delay / dwell / repeat fields plus Finish. These apply to the
    % stacked composite (compileFinalSignal), not to each BaseSignal.
=======
    % Offset / delay / dwell / repeat fields plus Finish. Values are collected
    % here but not yet copied onto BaseSignal by the controller.
>>>>>>> origin/main
    %
    %{
    Example usage:

    >> fig = uifigure;
    >> panel = AdditionalPanel(fig);
    >> panel.FinishCallback = @() disp("done");
    >> panel.OffsetEditField.Value

    %}

    properties
        MainLayoutGrid
        OffsetLabel
        DelayLabel
        DwellLabel
        RepeatedLabel
        OffsetEditField
        DelayEditField
        DwellEditField
        RepeatEditField
        FinishButton

        % Callback methods in View
        FinishCallback
        ValueChangedCallback
    end

    methods
        function obj = AdditionalPanel(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [6, 2]);
            obj.MainLayoutGrid.RowHeight = {30, 30, 30, 30, 45, 30};
            obj.MainLayoutGrid.ColumnWidth = {130, '1x'};

            obj.OffsetLabel = uilabel(obj.MainLayoutGrid, "Text", "Offset (N)");
            obj.OffsetEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 0);
            obj.OffsetEditField.ValueChangedFcn = @(~, ~) obj.parameterChanged();
            
            obj.DelayLabel = uilabel(obj.MainLayoutGrid, "Text", "Delay (Before) (s)");
            obj.DelayEditField = uieditfield(obj.MainLayoutGrid, 'numeric', ...
                'Value', 0, 'Limits', [0, Inf]);
            obj.DelayEditField.ValueChangedFcn = @(~, ~) obj.parameterChanged();
            
            obj.DwellLabel = uilabel(obj.MainLayoutGrid, "Text", "Dwell (After) (s)");
            obj.DwellEditField = uieditfield(obj.MainLayoutGrid, 'numeric', ...
                'Value', 0, 'Limits', [0, Inf]);
            obj.DwellEditField.ValueChangedFcn = @(~, ~) obj.parameterChanged();
            
            obj.RepeatedLabel = uilabel(obj.MainLayoutGrid, "Text", "Repeat Cycle(s)");
            obj.RepeatEditField = uieditfield(obj.MainLayoutGrid, 'numeric', ...
                'Value', 1, 'Limits', [0, Inf], 'RoundFractionalValues', 'on');
            obj.RepeatEditField.ValueChangedFcn = @(~, ~) obj.parameterChanged();

            hintlabel = uilabel(obj.MainLayoutGrid, ...
                "Text", "*Switch to overall view to see changes", ...
                "FontSize", 10, ...
                "HorizontalAlignment", 'right');
            hintlabel.Layout.Column = [1, 2];
            hintlabel.Layout.Row = 5;

            obj.FinishButton = uibutton(obj.MainLayoutGrid, "Text", "Finish Signal Building");
            obj.FinishButton.Layout.Column = [1, 2];
            obj.FinishButton.Layout.Row = 6;
            obj.FinishButton.ButtonPushedFcn = @(src, event) obj.onFinishButtonPushed();
        end

        function onFinishButtonPushed(obj)
            if ~isempty(obj.FinishCallback)
                obj.FinishCallback();
            end
        end

        function parameterChanged(obj)
            if ~isempty(obj.ValueChangedCallback)
                obj.ValueChangedCallback();
            end
        end

        function resetPanel(obj)
            obj.OffsetEditField.Value = 0;
            obj.DelayEditField.Value = 0;
            obj.DwellEditField.Value = 0;
            obj.RepeatEditField.Value = 1;
        end
    end
end
