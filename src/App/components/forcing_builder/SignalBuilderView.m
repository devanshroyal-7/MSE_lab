classdef SignalBuilderView2 < handle
    % Use grid size 940 x 630

    properties
        MainLayoutGrid
        PlotPanel
        Plot
        OverallPanel
        OverallListWidget
        ForcingPanel
        FunctionSetup
        AdditionalPanel
    end

    methods
        function obj = SignalBuilderView2(parentContainer)
            obj.MainLayoutGrid = uigridlayout(parentContainer, [2, 3]);
            obj.MainLayoutGrid.RowHeight = {300, 300};
            obj.MainLayoutGrid.ColumnWidth = {300, 300, 300};
            
            % Forcing Function Plot Panel
            obj.PlotPanel = uipanel(obj.MainLayoutGrid, ...
                "Title", "Function Plot", "FontWeight", "bold");
            obj.PlotPanel.Layout.Row = 1;
            obj.PlotPanel.Layout.Column = [1, 3];

            plotGrid = uigridlayout(obj.PlotPanel, [1, 1]);
            plotGrid.Padding = [10, 10, 10, 10];

            obj.Plot = uiaxes(plotGrid);

            % Overall List Panel
            obj.OverallPanel = uipanel(obj.MainLayoutGrid, ...
                "Title", "Select Functions", "FontWeight", "bold");
            obj.OverallPanel.Layout.Row = 2;
            obj.OverallPanel.Layout.Column = 1;

            % Function Setup Panel
            obj.ForcingPanel = uipanel(obj.MainLayoutGrid, ...
                "Title", "Function Setup", "FontWeight", "bold");
            obj.ForcingPanel.Layout.Row = 2;
            obj.ForcingPanel.Layout.Column = 2;

            obj.FunctionSetup = CustomPanel(obj.ForcingPanel);

            % Additional Parameter Panel
            obj.AdditionalPanel = uipanel(obj.MainLayoutGrid, ...
                "Title", "Additional Parameters", "FontWeight", "bold");
            obj.AdditionalPanel.Layout.Row = 2;
            obj.AdditionalPanel.Layout.Column = 3;
        end
    end
end


