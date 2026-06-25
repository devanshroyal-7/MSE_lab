classdef AppView < handle

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure       matlab.ui.Figure
        GridLayout     matlab.ui.container.GridLayout
        TimeScope_2    matlab.ui.scope.TimeScope
        VelocityLabel  matlab.ui.control.Label
        PositionLabel  matlab.ui.control.Label
        TimeScope      matlab.ui.scope.TimeScope
        MechanicalSystemExperimentationLabel  matlab.ui.control.Label
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1282 741];
            app.UIFigure.Name = 'MATLAB App';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x'};
            app.GridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};

            % Create MechanicalSystemExperimentationLabel
            app.MechanicalSystemExperimentationLabel = uilabel(app.GridLayout);
            app.MechanicalSystemExperimentationLabel.HorizontalAlignment = 'right';
            app.MechanicalSystemExperimentationLabel.FontSize = 24;
            app.MechanicalSystemExperimentationLabel.FontWeight = 'bold';
            app.MechanicalSystemExperimentationLabel.Layout.Row = 1;
            app.MechanicalSystemExperimentationLabel.Layout.Column = [4 6];
            app.MechanicalSystemExperimentationLabel.Text = '24-251 Mechanical System Experimentation ';

            % Create TimeScope
            app.TimeScope = uitimescope(app.GridLayout);
            app.TimeScope.YLabel = 'Amplitude';
            app.TimeScope.Layout.Row = [3 6];
            app.TimeScope.Layout.Column = [4 6];

            % Create PositionLabel
            app.PositionLabel = uilabel(app.GridLayout);
            app.PositionLabel.HorizontalAlignment = 'center';
            app.PositionLabel.VerticalAlignment = 'bottom';
            app.PositionLabel.FontSize = 18;
            app.PositionLabel.FontWeight = 'bold';
            app.PositionLabel.Layout.Row = 2;
            app.PositionLabel.Layout.Column = 5;
            app.PositionLabel.Text = 'Position';

            % Create VelocityLabel
            app.VelocityLabel = uilabel(app.GridLayout);
            app.VelocityLabel.HorizontalAlignment = 'center';
            app.VelocityLabel.VerticalAlignment = 'bottom';
            app.VelocityLabel.FontSize = 18;
            app.VelocityLabel.FontWeight = 'bold';
            app.VelocityLabel.Layout.Row = 7;
            app.VelocityLabel.Layout.Column = 5;
            app.VelocityLabel.Text = 'Velocity';

            % Create TimeScope_2
            app.TimeScope_2 = uitimescope(app.GridLayout);
            app.TimeScope_2.Title = 'Title';
            app.TimeScope_2.YLabel = 'Amplitude';
            app.TimeScope_2.Layout.Row = [8 11];
            app.TimeScope_2.Layout.Column = [4 6];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = MSE_App_handcode

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end