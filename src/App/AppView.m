classdef AppView < handle
    % use size [500, 500, 1100, 850]

    properties 
        UIFigure
        MainLayoutGrid
        SimStart
        TabGroup
        SaveButton
        TimeDomainPanel
        FreqDomainPanel
        Sidebar

        % Callback properties
        fwdRunSimCallbackView
        fwdSignalBuilderCallbackView
        fwdSaveOutputCallbackView
    end

    methods
        function obj = AppView(parentContainer)
            obj.UIFigure = parentContainer;
            obj.MainLayoutGrid = uigridlayout(parentContainer, [10, 10]);
            % obj.MainLayoutGrid.ColumnSpacing = 0;
            obj.MainLayoutGrid.Padding = [0, 0, 10, 0];
            obj.MainLayoutGrid.RowHeight = {60, '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
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
            obj.TabGroup.Layout.Row = [2, 10];

            % Time Domain
            TimeTab = uitab(obj.TabGroup, "Title", "Time");
            obj.TimeDomainPanel = TimePanel(TimeTab);

            % Frequency Domain
            FrequencyTab = uitab(obj.TabGroup, "Title", "Freuqency");
            obj.FreqDomainPanel = FrequencyPanel(FrequencyTab);

            % Controls
            ControlsTab = uitab(obj.TabGroup, "Title", "Controls");
            
            SidePanel = uipanel(obj.MainLayoutGrid);
            SidePanel.BorderType = 'none';
            SidePanel.Layout.Column = [8, 10];
            SidePanel.Layout.Row = [2, 10];

            obj.Sidebar = SidebarPanel(SidePanel);
            obj.Sidebar.fwdRunSignalCallback = @() obj.handleRunSimCallback();
            obj.Sidebar.fwdSignalBuilderCallback = @() obj.handleSignalBuilderCallback();
            obj.Sidebar.fwdSaveOutputCallback = @() obj.handleSaveOutputCallback();
        end
    
        function updateReferencePlot(obj, sim_input)
            t = sim_input.Time;
            y = sim_input.Data;
            plot(obj.TimeDomainPanel.ReferencePlot, t, y);
        end
    end

    methods
        % Callback methods
        function handleRunSimCallback(obj)
            if ~isempty(obj.fwdRunSimCallbackView)
                obj.fwdRunSimCallbackView();
            end
        end

        function handleSignalBuilderCallback(obj)
            if ~isempty(obj.fwdSignalBuilderCallbackView)
                obj.fwdSignalBuilderCallbackView();
            end
        end

        function handleSaveOutputCallback(obj)
            if ~isempty(obj.fwdSaveOutputCallbackView())
                obj.fwdSaveOutputCallbackView();
            end
        end
    end
end