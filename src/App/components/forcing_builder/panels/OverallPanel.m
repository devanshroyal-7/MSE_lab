classdef OverallPanel < handle
    % Left column of the forcing builder: Available types vs Overall stack,
    % Add/Remove/Clear, and Single/Overall plot switch.
    % OverallMode is 'available' while previewing a type, 'overall' while
    % editing a signal already on the stack. Add switches from available
    % to overall and selects the last stacked signal.
    %
    %{
    Example usage:

    >> fig = uifigure;
    >> panel = OverallPanel(fig);
    >> panel.AvailableListBox.Value     % e.g. "Sine"
    >> panel.AddCallback = @(name) disp(name);   % controller assigns these

    %}

    properties
        MainLayoutGrid
        AvailableLabel
        AvailableListBox
        OverallLabel
        OverallListBox
        OverallMode
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
        ViewSwitchCallback
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

            obj.OverallMode = 'available';

            obj.AddButton = uibutton(obj.MainLayoutGrid, "Text", "Add");

            obj.RemoveButton = uibutton(obj.MainLayoutGrid, "Text", "Remove");

            obj.ClearButton = uibutton(obj.MainLayoutGrid, "Text", "Clear");

            obj.ViewLabel = uilabel(obj.MainLayoutGrid, "Text", "Plot view: ", "VerticalAlignment", "bottom");

            obj.ViewSwitch = uiswitch(obj.MainLayoutGrid, "Items", ["Single", "Overall"]);
            obj.ViewSwitch.Enable = 'off';

            obj.layoutComponent();

            obj.AddButton.ButtonPushedFcn = @(~, ~) obj.handleAddPushed;
            obj.RemoveButton.ButtonPushedFcn = @(~, ~) obj.handleRemovePushed;
            obj.AvailableListBox.ValueChangedFcn = @(src, event) obj.handleSelectAvailableListBox(src, event);
            obj.OverallListBox.ValueChangedFcn = @(src, event) obj.handleSelectOverallListBox(src, event);
            obj.ViewSwitch.ValueChangedFcn = @(src, event) obj.handleViewSwitchCallback(src, event);
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
            if isempty(obj.AddCallback)
                return;
            end

            nBefore = numel(obj.OverallListBox.Items);
            obj.AddCallback(obj.AvailableListBox.Value);
            nAfter = numel(obj.OverallListBox.Items);

            % Successful add: leave Available and select the new stack item.
            if nAfter > nBefore
                obj.enterOverallMode(nAfter, false);
            end
        end

        function handleRemovePushed(obj)
            if ~isempty(obj.RemoveCallback)
                selectedSignal = obj.OverallListBox.ValueIndex;
                if strcmp(obj.OverallMode, 'overall')
                    obj.RemoveCallback(selectedSignal);
                end
            end
        end

        function handleSelectAvailableListBox(obj, ~, event)
            obj.enterAvailableMode(string(event.Value));
        end

        function handleSelectOverallListBox(obj, ~, event)
            % Rebuild the setup panel only when the selected type changes.
            if strcmp(event.Value, event.PreviousValue)
                swapFlag = false;
            else
                swapFlag = true;
            end
            obj.enterOverallMode(event.ValueIndex, swapFlag);
        end

        function handleViewSwitchCallback(obj, ~, ~)
            if strcmp(obj.OverallMode, 'overall') && ~isempty(obj.ViewSwitchCallback)
                obj.ViewSwitchCallback();
            end
        end

        function enterAvailableMode(obj, signalName)
            % Preview a type from the Available list: deselect Overall,
            % lock plot view to Single, and refresh the setup panel.
            obj.OverallMode = 'available';

            obj.setListValueSilent(obj.OverallListBox, string.empty);

            obj.ViewSwitch.Value = 'Single';
            obj.ViewSwitch.Enable = 'off';   % Single/Overall only applies to the stack

            if ~isempty(obj.SelectAvailableCallback)
                obj.SelectAvailableCallback(string(signalName));
            end
        end

        function enterOverallMode(obj, idx, swapFlag)
            % Edit a stacked signal: deselect Available, enable plot view,
            % and select Overall item idx.
            if isempty(idx) || idx < 1 || idx > numel(obj.OverallListBox.Items)
                return;
            end

            obj.OverallMode = 'overall';

            obj.setListValueSilent(obj.AvailableListBox, string.empty);

            obj.ViewSwitch.Enable = 'on';

            obj.selectOverallIndexSilent(idx);

            if ~isempty(obj.SelectOverallCallback)
                obj.SelectOverallCallback(idx, swapFlag);
            end
        end

        function setOverallItems(obj, signalNames)
            % Refresh the Overall list without firing ValueChangedFcn
            % (MATLAB may auto-select the first item when Items changes).
            fcn = obj.OverallListBox.ValueChangedFcn;
            obj.OverallListBox.ValueChangedFcn = [];
            obj.OverallListBox.Items = signalNames;
            if strcmp(obj.OverallMode, 'available')
                obj.OverallListBox.Value = string.empty;
            end
            obj.OverallListBox.ValueChangedFcn = fcn;
        end

        function selectOverallIndexSilent(obj, idx)
            obj.setListValueSilent(obj.OverallListBox, [], idx);
        end

        function resetOverallWidget(obj)
            obj.OverallMode = 'available';

            obj.setListValueSilent(obj.AvailableListBox, 'Custom');
            obj.setListValueSilent(obj.OverallListBox, string.empty);

            obj.ViewSwitch.Value = 'Single';
            obj.ViewSwitch.Enable = 'off';
        end
    end

    methods (Access = private)
        function setListValueSilent(~, listBox, value, valueIndex)
            % Assign Value/ValueIndex without running ValueChangedFcn so
            % Available <-> Overall switches do not bounce the other list.
            fcn = listBox.ValueChangedFcn;
            listBox.ValueChangedFcn = [];
            if nargin >= 4 && ~isempty(valueIndex)
                listBox.ValueIndex = valueIndex;
            else
                listBox.Value = value;
            end
            listBox.ValueChangedFcn = fcn;
        end
    end
end