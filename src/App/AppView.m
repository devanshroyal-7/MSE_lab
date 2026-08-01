classdef AppView < handle
    % use size [500, 500, 1100, 850]

    properties 
        MainLayoutGrid
        SimControl
        TabGroup
        SaveButton
        % TimeTab
        TimeDomainPanel
        FreqDomainPanel
    end

    methods
        function obj = AppView(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [10, 10]);
            obj.MainLayoutGrid.Padding = [0, 10, 0, 10];
            obj.MainLayoutGrid.RowHeight = {60, '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', 30};
            obj.MainLayoutGrid.ColumnWidth = {100, '1x', '1x', 100, 100, 100, '1x', '1x', 100, 100};

            titleGrid = uigridlayout(obj.MainLayoutGrid, [1, 1]);
            titleGrid.Layout.Column = [1, 6];
            titleGrid.Layout.Row = 1;
            CrsNumTitle = uilabel(titleGrid, ...
                "Text", "24-452 Mechanical Systems Experiementation", ...
                "FontWeight", "bold", ...
                "FontSize", 25, ...
                "HorizontalAlignment", 'left');
            % CrsNumTitle.Layout.Column = [1, 6];
            % CrsNumTitle.Layout.Row = 1;

            obj.SimControl = uisimcontrols(obj.MainLayoutGrid, ...
                'StartText', 'Start Test');
            obj.SimControl.Layout.Column = [9, 10];
            obj.SimControl.Layout.Row = 1;

            obj.TabGroup = uitabgroup(obj.MainLayoutGrid);
            obj.TabGroup.Layout.Column = [1, 10];
            obj.TabGroup.Layout.Row = [2, 9];

            SaveButtonGrid = uigridlayout(obj.MainLayoutGrid, [1, 2]);
            SaveButtonGrid.Layout.Column = [8, 10];
            SaveButtonGrid.Layout.Row = 10;
            SaveButtonGrid.Padding = [0, 0, 12, 0];
            SaveButtonGrid.ColumnWidth = {'1x', 200};
            obj.SaveButton = uibutton(SaveButtonGrid, "Text", "Save Output");
            obj.SaveButton.Layout.Column = 2;
            obj.SaveButton.Layout.Row = 1;
            
            TimeTab = uitab(obj.TabGroup, "Title", "Time");
            obj.TimeDomainPanel = TimePanel(TimeTab);

            FrequencyTab = uitab(obj.TabGroup, "Title", "Freuqency");
            obj.FreqDomainPanel = FrequencyPanel(FrequencyTab);

            ControlsTab = uitab(obj.TabGroup, "Title", "Controls");
        end
    end
end