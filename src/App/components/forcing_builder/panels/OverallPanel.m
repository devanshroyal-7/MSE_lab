classdef OverallPanel < handle
    properties
        MainLayoutGrid
        AvailableLabel
        AvailableListBox
        OverallLabel
        OverallListBox
        ClearButton
        AddButton
        RemoveButton
        ViewLabel
        ViewSwitch

        % Callback function handles
        AddCallback
        RemoveCallback
        SelectAvailableCallback
        SelectOverallCallback
    end

    methods
        function obj = OverallPanel(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [4, 3]);
            obj.MainLayoutGrid.RowHeight = {30, 130, 30, 30};
            obj.MainLayoutGrid.ColumnWidth = {62, 62, 62, 62};

            obj.AvailableLabel = uilabel(obj.MainLayoutGrid, "Text", "Available", "FontWeight", "bold");
            
            obj.OverallLabel = uilabel(obj.MainLayoutGrid, "Text", "Overall", "FontWeight", "bold");

            obj.AvailableListBox = uilistbox(obj.MainLayoutGrid, "Items", ["Custom", "Noise", "Ramp", "Sine", "Step", "Swept Sine", "Zero Output"]);

            obj.OverallListBox = uilistbox(obj.MainLayoutGrid, "Items", string.empty);

            obj.AddButton = uibutton(obj.MainLayoutGrid, "Text", "Add");

            obj.RemoveButton = uibutton(obj.MainLayoutGrid, "Text", "Remove");

            obj.ClearButton = uibutton(obj.MainLayoutGrid, "Text", "Clear");

            obj.ViewLabel = uilabel(obj.MainLayoutGrid, "Text", "Plot view: ", "VerticalAlignment", "bottom");

            obj.ViewSwitch = uiswitch(obj.MainLayoutGrid, "Items", ["Single", "Overall"]);

            obj.layoutComponent();

            obj.AddButton.ButtonPushedFcn = @(~, ~) obj.handleAddPushed;
            obj.RemoveButton.ButtonPushedFcn = @(~, ~) obj.handleRemovePushed;
            obj.AvailableListBox.ValueChangedFcn = @(src, event) obj.handleSelectAvailableListBox(src, event);
            obj.OverallListBox.ValueChangedFcn = @(src, event) obj.handleSelectOverallListBox(src, event);
        end

        function layoutComponent(obj)
            obj.AvailableLabel.Layout.Row = 1;
            obj.AvailableLabel.Layout.Column = [1, 2];

            obj.OverallLabel.Layout.Row = 1;
            obj.OverallLabel.Layout.Column = [3, 4];

            obj.AvailableListBox.Layout.Row = 2;
            obj.AvailableListBox.Layout.Column = [1, 2];

            obj.OverallListBox.Layout.Row = 2;
            obj.OverallListBox.Layout.Column = [3, 4];

            obj.AddButton.Layout.Row = 3;
            obj.AddButton.Layout.Column = 3;

            obj.RemoveButton.Layout.Row = 3;
            obj.RemoveButton.Layout.Column = 4;

            obj.ClearButton.Layout.Row = 4;
            obj.ClearButton.Layout.Column = [3, 4];

            obj.ViewLabel.Layout.Row = 3;
            obj.ViewLabel.Layout.Column = [1, 2];

            obj.ViewSwitch.Layout.Row = 4;
            obj.ViewSwitch.Layout.Column = [1, 2];
        end

        function handleAddPushed(obj)
            if ~isempty(obj.AddCallback)
                selectedSignal = obj.AvailableListBox.Value;
                obj.AddCallback(selectedSignal);
            end
        end

        function handleRemovePushed(obj)
            if ~isempty(obj.RemoveCallback)
                selectedSignal = obj.OverallListBox.ValueIndex;
                obj.RemoveCallback(selectedSignal);
            end
        end

        function handleSelectAvailableListBox(obj, ~, event)
            if ~isempty(obj.SelectAvailableCallback)
                selectedSignal = string(event.Value);
                obj.SelectAvailableCallback(selectedSignal);
            end
        end

        function handleSelectOverallListBox(obj, ~, event)
            if ~isempty(obj.SelectOverallCallback)
                selectedSignal = event.ValueIndex;

                % don't destroy panel if same signal is being used
                if strcmp(event.Value, event.PreviousValue)
                    swapFlag = false;
                else
                    swapFlag = true;
                end
                obj.SelectOverallCallback(selectedSignal, swapFlag);
            end
        end
    end
end