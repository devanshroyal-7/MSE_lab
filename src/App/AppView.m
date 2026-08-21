classdef AppView < handle
    % Main MSE app window: title, Time/FFT/FRF/Controls-Time/Controls-Frequency
    % tabs, sidebar.
    % Recommended figure size: [500, 500, 1900, 900] (see main.m).
    %
    %{
    Example usage:

    >> fig = uifigure("Position", [500, 500, 1900, 900]);
    >> view = AppView(fig);
    >> view.updateReferencePlot(timeseries(y, t));
    >> view.FFTPanel.AxForcingMag          % forcing FFT magnitude axes
    >> view.FRFPanel.AxMag                 % FRF magnitude axes
    >> view.ControlsPanel.AxDisplacement   % controls-time displacement axes
    >> view.ControlsFrequencyPanel.AxMag   % controls-frequency Bode magnitude

    %}

    properties 
        UIFigure
        MainLayoutGrid
        SimStart
        TabGroup
        SaveButton
        TimeDomainPanel
        FFTPanel
        FRFPanel
        ControlsPanel
        ControlsFrequencyPanel
        ControlsTimeTab
        ControlsFreqTab
        Sidebar

        % Callback properties
        fwdRunSimCallbackView
        fwdStopSimCallbackView
        fwdSignalBuilderCallbackView
        fwdSaveOutputCallbackView
        fwdEnableControlsCallbackView
        fwdSimParamsChangedCallbackView
        fwdControlParamsChangedCallbackView
        fwdAverageRunsChangedCallbackView
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
            FFTTab = uitab(obj.TabGroup, "Title", "FFT");
            obj.FFTPanel = FrequencyPanel(FFTTab);

            FRFTab = uitab(obj.TabGroup, "Title", "FRF");
            frfPanel = FRFPanel(FRFTab);
            obj.FRFPanel = frfPanel;

            obj.ControlsTimeTab = uitab(obj.TabGroup, "Title", "Controls - Time");
            obj.ControlsPanel = ControlsPanel(obj.ControlsTimeTab);

            obj.ControlsFreqTab = uitab(obj.TabGroup, "Title", "Controls - Frequency");
            obj.ControlsFrequencyPanel = ControlsFrequencyPanel(obj.ControlsFreqTab);
            
            SidePanel = uipanel(obj.MainLayoutGrid);
            SidePanel.BorderType = 'none';
            SidePanel.Layout.Column = [8, 10];
            SidePanel.Layout.Row = [2, 10];

            obj.Sidebar = SidebarPanel(SidePanel);
            obj.Sidebar.fwdRunSignalCallback = @() obj.handleRunSimCallback();
            obj.Sidebar.fwdStopSignalCallback = @() obj.handleStopSimCallback();
            obj.Sidebar.fwdSignalBuilderCallback = @() obj.handleSignalBuilderCallback();
            obj.Sidebar.fwdSaveOutputCallback = @() obj.handleSaveOutputCallback();
            obj.Sidebar.fwdEnableControlsCallback = @(enabled) obj.handleEnableControlsCallback(enabled);
            obj.Sidebar.fwdSimParamsChangedCallback = @(k, b, enabled) obj.handleSimParamsChangedCallback(k, b, enabled);
            obj.Sidebar.fwdControlParamsChangedCallback = @(kp, ki, kd, closedLoop, enabled) obj.handleControlParamsChangedCallback(kp, ki, kd, closedLoop, enabled);
            obj.Sidebar.fwdAverageRunsChangedCallback = @(enabled) obj.handleAverageRunsChangedCallback(enabled);
            obj.TabGroup.SelectionChangedFcn = @(src, event) obj.handleTabChanged();
            obj.handleTabChanged();
        end
    
        function updateReferencePlot(obj, sim_input)
            t = sim_input.Time;
            y = squeeze(sim_input.Data);
            obj.TimeDomainPanel.updateReferencePlot(t, y);
            obj.ControlsPanel.updateReferenceInput(t, y);

            if ~isempty(sim_input.UserData) && isfield(sim_input.UserData, 'Quantity')
                obj.setReferenceQuantity(SignalQuantity.fromMode(sim_input.UserData.Quantity));
            end
        end

        function clearReferencePlot(obj)
            obj.TimeDomainPanel.updateReferencePlot([], []);
            obj.ControlsPanel.updateReferenceInput([], []);
        end

        function setReferenceQuantity(obj, quantity)
            obj.TimeDomainPanel.setReferenceQuantity(quantity);
            obj.ControlsPanel.setReferenceQuantity(quantity);
        end

        function setSignalBuilderButtonText(obj, text)
            obj.Sidebar.setSignalBuilderButtonText(text);
        end

        function tf = controlsEnabled(obj)
            tf = obj.Sidebar.controlsEnabled();
        end

        function tf = averageRunsEnabled(obj)
            tf = obj.Sidebar.averageRunsEnabled();
        end

        function updateResponsePlot(obj, t, y)
            obj.TimeDomainPanel.updateResponsePlot(t, y);
            obj.ControlsPanel.updateDisplacement(t, y);
        end

        function showLiveResponseScope(obj, sampleRate)
            obj.TimeDomainPanel.showLiveTimeScope(sampleRate);
        end

        function restoreResponseAxes(obj)
            obj.TimeDomainPanel.restoreResponseAxes();
        end

        function scope = getResponseTimeScope(obj)
            scope = obj.TimeDomainPanel.getResponseTimeScope();
        end

        function updateControlsReferenceInput(obj, t, y)
            obj.ControlsPanel.updateReferenceInput(t, y);
        end

        function updateControlsError(obj, t, y)
            obj.ControlsPanel.updateError(t, y);
        end

        function updateControlsEffort(obj, t, y)
            obj.ControlsPanel.updateEffort(t, y);
        end

        function clearControlsTimePlots(obj)
            obj.ControlsPanel.clearPlots();
        end

        function updateFftPlots(obj, forcingSpec, responseSpec)
            obj.FFTPanel.updateForcing(forcingSpec);
            obj.FFTPanel.updateResponse(responseSpec);
        end

        function updateForcingFft(obj, spec)
            obj.FFTPanel.updateForcing(spec);
        end

        function updateResponseFft(obj, spec)
            obj.FFTPanel.updateResponse(spec);
        end

        function clearFftPlots(obj)
            obj.FFTPanel.clearPlots();
        end

        function clearForcingFft(obj)
            obj.FFTPanel.updateForcing(FftAnalyzer.emptySpectrum());
        end

        function clearResponseFft(obj)
            obj.FFTPanel.updateResponse(FftAnalyzer.emptySpectrum());
        end

        function updateFrf(obj, result, showCoherence)
            if nargin < 3
                showCoherence = false;
            end
            obj.FRFPanel.update(result, showCoherence);
        end

        function clearFrf(obj)
            obj.FRFPanel.clearPlots();
            obj.FRFPanel.setCoherenceVisible(false);
        end

        function clearFrfCoherence(obj)
            obj.FRFPanel.clearCoherence();
        end

        function updateControlsBode(obj, spec)
            obj.ControlsFrequencyPanel.updateBode(spec);
        end

        function clearControlsBode(obj)
            obj.ControlsFrequencyPanel.clearPlots();
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

        function handleStopSimCallback(obj)
            if ~isempty(obj.fwdStopSimCallbackView)
                obj.fwdStopSimCallbackView();
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

        function handleSimParamsChangedCallback(obj, k, b, enabled)
            if ~isempty(obj.fwdSimParamsChangedCallbackView)
                obj.fwdSimParamsChangedCallbackView(k, b, enabled);
            end
        end

        function handleControlParamsChangedCallback(obj, kp, ki, kd, closedLoop, enabled)
            if ~isempty(obj.fwdControlParamsChangedCallbackView)
                obj.fwdControlParamsChangedCallbackView(kp, ki, kd, closedLoop, enabled);
            end
        end

        function handleAverageRunsChangedCallback(obj, enabled)
            if ~isempty(obj.fwdAverageRunsChangedCallbackView)
                obj.fwdAverageRunsChangedCallbackView(enabled);
            end
        end

        function handleTabChanged(obj)
            if isempty(obj.Sidebar)
                return;
            end
            selected = obj.TabGroup.SelectedTab;
            onControlsTime = ~isempty(obj.ControlsTimeTab) && isequal(selected, obj.ControlsTimeTab);
            onControlsFreq = ~isempty(obj.ControlsFreqTab) && isequal(selected, obj.ControlsFreqTab);
            onControls = onControlsTime || onControlsFreq;
            obj.Sidebar.setControlPanelsVisible(onControls, onControls);
        end

        function name = selectedTabTitle(obj)
            name = "";
            try
                name = string(obj.TabGroup.SelectedTab.Title);
            catch
            end
        end
    end
end
