classdef SignalBuilderView < handle
    % Use grid size 940 x 630

    properties
        MainLayoutGrid
        PlotPanel
        Plot
        PanelOverall
        OverallListWidget
        PanelForcing
        FunctionSetup
        PanelAdditional
        AdditionalSetup
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


    		% Function Setup Panel
    		obj.PanelForcing = uipanel(obj.MainLayoutGrid, ...
        		"Title", "Function Setup", "FontWeight", "bold");


    		obj.FunctionSetup = CustomPanel(obj.PanelForcing);

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
end

