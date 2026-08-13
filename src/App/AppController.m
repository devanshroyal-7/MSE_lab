classdef AppController < handle
    % Glue between AppModel and AppView. Callbacks are still placeholders.
    %
    %{
    Example usage:

    >> fig = uifigure("Position", [500, 500, 1100, 850]);
    >> model = AppModel;
    >> view = AppView(fig);
    >> controller = AppController(model, view);

    %}

    properties
        Model
        View

    end

    methods 
        function obj = AppController(model, view)
            obj.Model = model;
            obj.View = view;

            % Callback
            obj.View.fwdRunSimCallback = @() handleRunSimCallback();
        end

        function handleRunSimCallback();
            
        end
    end
end