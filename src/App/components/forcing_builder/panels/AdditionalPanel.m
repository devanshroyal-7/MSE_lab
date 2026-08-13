classdef AdditionalPanel < handle
    % Offset / delay / dwell / repeat fields plus Finish. Values are collected
    % here but not yet copied onto BaseSignal by the controller.
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

        % Callback method in View
        FinishCallback
    end

    methods
        function obj = AdditionalPanel(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [4, 2]);
            obj.MainLayoutGrid.RowHeight = {30, 30, 30, 30, 45, 30};
            obj.MainLayoutGrid.ColumnWidth = {130, '1x'};

            obj.OffsetLabel = uilabel(obj.MainLayoutGrid, "Text", "Offset (N)");
            obj.OffsetEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 0);
            
            obj.DelayLabel = uilabel(obj.MainLayoutGrid, "Text", "Delay (Before) (s)");
            obj.DelayEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 0);
            
            obj.DwellLabel = uilabel(obj.MainLayoutGrid, "Text", "Dwell (After) (s)");
            obj.DwellEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 0);
            
            obj.RepeatedLabel = uilabel(obj.MainLayoutGrid, "Text", "Repeat Cycle(s)");
            obj.RepeatEditField = uieditfield(obj.MainLayoutGrid, 'numeric', 'Value', 0);

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

    end
end

        