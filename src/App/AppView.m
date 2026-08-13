classdef AppView < handle
    % Main MSE app window: title, Time/Frequency/Controls tabs, sidebar, save.
    % Recommended figure size: [500, 500, 1100, 850].
    %
    %{
    Example usage:

    >> fig = uifigure("Position", [500, 500, 1100, 850]);
    >> view = AppView(fig);
    >> view.TimeDomainPanel.ResponsePlot   % uiaxes for cart response
    >> view.FreqDomainPanel.AxFRF          % FRF axes

    %}

    properties 
        MainLayoutGrid
        SimStart
        TabGroup
        SaveButton
        % TimeTab
        TimeDomainPanel
        FreqDomainPanel

        % Callback properties
        fwdRunSimCallback
    end

    methods
        function obj = AppView(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [10, 10]);
            obj.MainLayoutGrid.Padding = [0, 10, 0, 10];
            obj.MainLayoutGrid.RowHeight = {60, '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', 30};
            obj.MainLayoutGrid.ColumnWidth = {100, '1x', '1x', 100, 100, 100, '1x', '1x', 100, 100};
            
            % Title 
            titleGrid = uigridlayout(obj.MainLayoutGrid, [1, 1]);
            titleGrid.Layout.Column = [1, 6];
            titleGrid.Layout.Row = 1;
            CrsNumTitle = uilabel(titleGrid, ...
                "Text", "24-452 Mechanical Systems Experiementation", ...
                "FontWeight", "bold", ...
                "FontSize", 25, ...
                "HorizontalAlignment", 'left');

            logopadding = uigridlayout(obj.MainLayoutGrid, [1, 1]);
            logopadding.Layout.Column = [9, 10];
            logopadding.Layout.Row = 1;
            robots5Logo = uiimage(logopadding, ...
                "ImageSource", "robots5_logo.png");

            % Tabs
            obj.TabGroup = uitabgroup(obj.MainLayoutGrid);
            obj.TabGroup.Layout.Column = [1, 7];
            obj.TabGroup.Layout.Row = [2, 9];

            % Save Button
            SaveButtonGrid = uigridlayout(obj.MainLayoutGrid, [1, 2]);
            SaveButtonGrid.Layout.Column = [8, 10];
            SaveButtonGrid.Layout.Row = 10;
            SaveButtonGrid.Padding = [0, 0, 12, 0];
            SaveButtonGrid.ColumnWidth = {'1x', 200};
            obj.SaveButton = uibutton(SaveButtonGrid, "Text", "Save Output");
            obj.SaveButton.Layout.Column = 2;
            obj.SaveButton.Layout.Row = 1;
            
            % Time Domain
            TimeTab = uitab(obj.TabGroup, "Title", "Time");
            obj.TimeDomainPanel = TimePanel(TimeTab);

            % Frequency Domain
            FrequencyTab = uitab(obj.TabGroup, "Title", "Freuqency");
            obj.FreqDomainPanel = FrequencyPanel(FrequencyTab);

            % Controls tab is a placeholder; live sim controls are on SidebarPanel
            ControlsTab = uitab(obj.TabGroup, "Title", "Controls");
            
            SidePanel = uipanel(obj.MainLayoutGrid);
            SidePanel.Layout.Column = [8, 10];
            SidePanel.Layout.Row = [2, 9];

            Sidebar = SidebarPanel(SidePanel);
        end

        function RunSimCallback(obj)
            if ~isempty(obj.fwdRunSimCallback)
                obj.fwdRunSimCallback();
            end
        end
    end
end