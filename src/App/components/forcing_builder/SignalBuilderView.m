classdef SignalBuilderView < handle
    % Use grid size 940 x 630

    properties
        MainLayoutGrid
        PlotPanel
        Plot
        PanelOverall
        OverallListWidget
        PanelForcing
        ActiveSetupPanel
        ForcingCanvas
        PanelAdditional
        AdditionalSetup

        % View Callback functions % these callbacks pass it from overall panel to
        % the SignalBuilderController
        AddCallbackView
        RemoveCallbackView
        SelectAvailableCallbackView
        SelectOverallCallbackView
    end

    events
        ViewUpdated
    end

    methods
        function obj = SignalBuilderView(parentContainer)
    		obj.createComponents(parentContainer)
    		obj.layoutComponents()
    	end
    end

    methods (Access = private)
        function createComponents(obj, parentContainer)

    		obj.MainLayoutGrid = uigridlayout(parentContainer, [2, 3]);
    		obj.MainLayoutGrid.RowHeight = {300, 300};
    		obj.MainLayoutGrid.ColumnWidth = {300, 300, 300};

    		% Forcing Function Plot Panel
    		obj.PlotPanel = uipanel(obj.MainLayoutGrid, ...
        		"Title", "Function Plot", "FontWeight", "bold");

    		plotGrid = uigridlayout(obj.PlotPanel, [1, 1]);
    		plotGrid.Padding = [10, 10, 10, 10];
    		obj.Plot = uiaxes(plotGrid, "XGrid", "on", "YGrid", "on");

    		% Overall List Panel
    		obj.PanelOverall = uipanel(obj.MainLayoutGrid, ...
        		"Title", "Select Functions", "FontWeight", "bold");

            obj.OverallListWidget = OverallPanel(obj.PanelOverall);

            obj.OverallListWidget.AddCallback = @(value) obj.fwdAddCallback(value);
            obj.OverallListWidget.RemoveCallback = @(idx) obj.fwdRemoveCallback(idx);
            obj.OverallListWidget.SelectAvailableCallback = @(value) obj.fwdSelectAvailableCallback(value);
            obj.OverallListWidget.SelectOverallCallback = @(idx) obj.fwdSelectOverallCallback(idx);


    		% Function Setup Panel
    		obj.PanelForcing = uipanel(obj.MainLayoutGrid, ...
        		"Title", "Function Setup", "FontWeight", "bold");

            obj.ForcingCanvas  = uigridlayout(obj.PanelForcing, [1, 1]);
            obj.ForcingCanvas.Padding = [0, 0, 0, 0];

            obj.swapActivePanel("Custom");      % Initialize with Custom


    		% Additional Parameter Panel
    		obj.PanelAdditional = uipanel(obj.MainLayoutGrid, ...
                "Title", "Additional Parameters", "FontWeight", "bold");

            obj.AdditionalSetup = AdditionalPanel(obj.PanelAdditional);
        end

        function layoutComponents(obj)

            obj.PlotPanel.Layout.Row = 1;
            obj.PlotPanel.Layout.Column = [1, 3];

            obj.PanelOverall.Layout.Row = 2;
            obj.PanelOverall.Layout.Column = 1;

            obj.PanelForcing.Layout.Row = 2;
            obj.PanelForcing.Layout.Column = 2;

            obj.PanelAdditional.Layout.Row = 2;
            obj.PanelAdditional.Layout.Column = 3;
        end
    end

    methods
        function updatePlot(obj, t, y)
            plot(obj.Plot, t, y);
        end

        function swapActivePanel(obj, panelName)
            if ~isempty(obj.ActiveSetupPanel) && isvalid(obj.ActiveSetupPanel)
                delete(obj.ActiveSetupPanel.MainLayoutGrid);
                obj.ActiveSetupPanel = [];
            end

            switch panelName
                case "Custom"
                    obj.ActiveSetupPanel = CustomPanel(obj.ForcingCanvas);
                case "Noise"
                    obj.ActiveSetupPanel = NoisePanel(obj.ForcingCanvas);
                case "Ramp"
                    obj.ActiveSetupPanel = RampPanel(obj.ForcingCanvas);
                case "Sine"
                    obj.ActiveSetupPanel = SinePanel(obj.ForcingCanvas);
                case "Step"
                    obj.ActiveSetupPanel = StepPanel(obj.ForcingCanvas);
                case "Swept Sine"
                    obj.ActiveSetupPanel = SweptSinePanel(obj.ForcingCanvas);
                case "Zero Output"
                    obj.ActiveSetupPanel = ZeroOutputPanel(obj.ForcingCanvas);
            end
        end
    end

    methods
        % methods for forwarding the callback function from view to
        % controller

        function fwdAddCallback(obj, value)
            if ~isempty(obj.AddCallbackView)
                obj.AddCallbackView(value);
            end
        end

        function fwdRemoveCallback(obj, idx)
            if ~isempty(obj.RemoveCallbackView)
                obj.RemoveCallbackView(idx);
            end
        end

        function fwdSelectAvailableCallback(obj, value)
            if ~isempty(obj.SelectAvailableCallbackView)
                obj.SelectAvailableCallbackView(value);
            end
        end

        function fwdSelectOverallCallback(obj, idx)
            if ~isempty(obj.SelectOverallCallbackView)
                obj.SelectOverallCallbackView(idx);
            end
        end
    end
end

