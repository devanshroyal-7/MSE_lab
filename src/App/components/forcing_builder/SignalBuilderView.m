classdef SignalBuilderView < matlab.ui.componentcontainer.ComponentContainer

    % Properties that correspond to underlying components
    properties (Access = private, Transient, NonCopyable)
        GridLayout             matlab.ui.container.GridLayout
        FunctionSetupLabel     matlab.ui.control.Label
        ForcingFunctionsLabel  matlab.ui.control.Label
        ClearButton            matlab.ui.control.Button
        RemoveButton           matlab.ui.control.Button
        AddButton              matlab.ui.control.Button
        OverallListBox         matlab.ui.control.ListBox
        OverallListBoxLabel    matlab.ui.control.Label
        AvailableListBox       matlab.ui.control.ListBox
        AvailableListBoxLabel  matlab.ui.control.Label
    end

    properties (Access = public)
        Items string % List of Items in available components
    end
    
    % Callbacks that handle component events
    methods (Access = private)

        % Double-clicked callback: AvailableListBox
        function AvailableListBoxClicked(comp, event)
            availableList = comp.AvailableListBox;
            selectedList = comp.OverallListBox;

            new_item = availableList.Value;

            if isempty(new_item)
                return;
            end

            selectedList.Items = [cellstr(selectedList.Items), {new_item}];

        end

        % Button pushed function: AddButton
        function AddButtonPushed(comp, event)
            % gridLayout = findobj(comp.Parent, 'Type', 'uigridlayout');

            availableList = comp.AvailableListBox;
            selectedList = comp.OverallListBox;

            new_item = availableList.Value;

            if isempty(new_item)
                return;
            end

            selectedList.Items = [cellstr(selectedList.Items), {new_item}];
            selectedList.ItemsData = 1:numel(comp.OverallListBox.Items);

        end

        % Button pushed function: RemoveButton
        function RemoveButtonPushed(comp, event)
            selectedList = comp.OverallListBox;

            currentItems = cellstr(selectedList.Items);
            remove_item_idx = selectedList.Value;
            
            if ~isempty(remove_item_idx)
                % indicesToRemove = ismember(currentItems, remove_item);

                currentItems(remove_item_idx) = [];

                selectedList.Items = currentItems;
                selectedList.Value = {};

                selectedList.ItemsData = 1:numel(currentItems);
            end



            
        end

        % Button pushed function: ClearButton
        function ClearButtonPushed(comp, event)
            selectedList = comp.OverallListBox;

            selectedList.Items = {};

            

        end
    end

    methods (Access = protected)
        
        % Code that executes when the value of a property is changed
        function update(comp)
            % Use this function to update the underlying components
            
        end

        % Create the underlying components
        function setup(comp)

            comp.Position = [1 1 668 332];

            % Create GridLayout
            comp.GridLayout = uigridlayout(comp);
            comp.GridLayout.ColumnWidth = {'2x', '1x', '1x', '1x', '1x', '1x'};
            comp.GridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};

            % Create AvailableListBoxLabel
            comp.AvailableListBoxLabel = uilabel(comp.GridLayout);
            comp.AvailableListBoxLabel.FontWeight = 'bold';
            comp.AvailableListBoxLabel.Layout.Row = 2;
            comp.AvailableListBoxLabel.Layout.Column = 1;
            comp.AvailableListBoxLabel.Text = 'Available';

            % Create AvailableListBox
            comp.AvailableListBox = uilistbox(comp.GridLayout);
            comp.AvailableListBox.Items = {'Zero Output', 'Ramp', 'Sine', 'Step', 'Swept Sine', 'Custom'};
            comp.AvailableListBox.Layout.Row = [3 6];
            comp.AvailableListBox.Layout.Column = 1;
            comp.AvailableListBox.DoubleClickedFcn = matlab.apps.createCallbackFcn(comp, @AvailableListBoxClicked, true);
            comp.AvailableListBox.Value = 'Zero Output';

            % Create OverallListBoxLabel
            comp.OverallListBoxLabel = uilabel(comp.GridLayout);
            comp.OverallListBoxLabel.FontWeight = 'bold';
            comp.OverallListBoxLabel.Layout.Row = 2;
            comp.OverallListBoxLabel.Layout.Column = 2;
            comp.OverallListBoxLabel.Text = 'Overall';

            % Create OverallListBox
            comp.OverallListBox = uilistbox(comp.GridLayout);
            comp.OverallListBox.Items = {};
            comp.OverallListBox.Layout.Row = [3 6];
            comp.OverallListBox.Layout.Column = [2 3];
            comp.OverallListBox.Value = {};

            % Create AddButton
            comp.AddButton = uibutton(comp.GridLayout, 'push');
            comp.AddButton.ButtonPushedFcn = matlab.apps.createCallbackFcn(comp, @AddButtonPushed, true);
            comp.AddButton.Layout.Row = 7;
            comp.AddButton.Layout.Column = 2;
            comp.AddButton.Text = 'Add';

            % Create RemoveButton
            comp.RemoveButton = uibutton(comp.GridLayout, 'push');
            comp.RemoveButton.ButtonPushedFcn = matlab.apps.createCallbackFcn(comp, @RemoveButtonPushed, true);
            comp.RemoveButton.Layout.Row = 7;
            comp.RemoveButton.Layout.Column = 3;
            comp.RemoveButton.Text = 'Remove';

            % Create ClearButton
            comp.ClearButton = uibutton(comp.GridLayout, 'push');
            comp.ClearButton.ButtonPushedFcn = matlab.apps.createCallbackFcn(comp, @ClearButtonPushed, true);
            comp.ClearButton.Layout.Row = 8;
            comp.ClearButton.Layout.Column = [2 3];
            comp.ClearButton.Text = 'Clear';

            % Create ForcingFunctionsLabel
            comp.ForcingFunctionsLabel = uilabel(comp.GridLayout);
            comp.ForcingFunctionsLabel.FontSize = 18;
            comp.ForcingFunctionsLabel.FontWeight = 'bold';
            comp.ForcingFunctionsLabel.Layout.Row = 1;
            comp.ForcingFunctionsLabel.Layout.Column = [1 3];
            comp.ForcingFunctionsLabel.Text = 'Forcing Functions';

            % Create FunctionSetupLabel
            comp.FunctionSetupLabel = uilabel(comp.GridLayout);
            comp.FunctionSetupLabel.FontSize = 18;
            comp.FunctionSetupLabel.FontWeight = 'bold';
            comp.FunctionSetupLabel.Layout.Row = 1;
            comp.FunctionSetupLabel.Layout.Column = [4 6];
            comp.FunctionSetupLabel.Text = 'Function Setup';
        end
    end
end