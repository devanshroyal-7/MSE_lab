classdef AppView < handle
    % Main MSE app window: title, Time/Frequency/Controls tabs, sidebar.
    % Recommended figure size: [500, 500, 1900, 900] (see main.m).
    %
    %{
    Example usage:

    >> fig = uifigure("Position", [500, 500, 1900, 900]);
    >> view = AppView(fig);
    >> view.updateReferencePlot(timeseries(y, t));
    >> view.FreqDomainPanel.AxForcingMag   % forcing FFT magnitude axes

    %}

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
        fwdEnableControlsCallbackView
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

            % Controls tab is a placeholder; live sim controls are on SidebarPanel
            ControlsTab = uitab(obj.TabGroup, "Title", "Controls");
            
            SidePanel = uipanel(obj.MainLayoutGrid);
            SidePanel.BorderType = 'none';
            SidePanel.Layout.Column = [8, 10];
            SidePanel.Layout.Row = [2, 10];

            obj.Sidebar = SidebarPanel(SidePanel);
            obj.Sidebar.fwdRunSignalCallback = @() obj.handleRunSimCallback();
            obj.Sidebar.fwdSignalBuilderCallback = @() obj.handleSignalBuilderCallback();
            obj.Sidebar.fwdSaveOutputCallback = @() obj.handleSaveOutputCallback();
            obj.Sidebar.fwdEnableControlsCallback = @(enabled) obj.handleEnableControlsCallback(enabled);
        end
    
        function updateReferencePlot(obj, sim_input)
            t = sim_input.Time;
            y = squeeze(sim_input.Data);
            obj.TimeDomainPanel.updateReferencePlot(t, y);

            if ~isempty(sim_input.UserData) && isfield(sim_input.UserData, 'Quantity')
                obj.setReferenceQuantity(SignalQuantity.fromMode(sim_input.UserData.Quantity));
            end
        end

        function clearReferencePlot(obj)
            obj.TimeDomainPanel.updateReferencePlot([], []);
        end

        function setReferenceQuantity(obj, quantity)
            obj.TimeDomainPanel.setReferenceQuantity(quantity);
        end

        function setSignalBuilderButtonText(obj, text)
            obj.Sidebar.setSignalBuilderButtonText(text);
        end

        function tf = controlsEnabled(obj)
            tf = obj.Sidebar.controlsEnabled();
        end

        function updateResponsePlot(obj, t, y)
            obj.TimeDomainPanel.updateResponsePlot(t, y);
        end

        function setSimLampRunning(obj, isRunning)
            obj.Sidebar.setSimLampRunning(isRunning);
        end

        function setAppEnabled(obj, tf)
            obj.Sidebar.setActionButtonsEnabled(tf);
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
            if ~isempty(obj.fwdSaveOutputCallbackView)
                obj.fwdSaveOutputCallbackView();
            end
        end

        function handleEnableControlsCallback(obj, enabled)
            if ~isempty(obj.fwdEnableControlsCallbackView)
                obj.fwdEnableControlsCallbackView(enabled);
            end
        end
    end
end
