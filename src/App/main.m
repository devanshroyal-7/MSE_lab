function main()
    % Entry point for the MSE lab app. Wires AppModel / AppView / AppController.
    % AppView currently expects a parent uifigure; pass one before this stub is complete.
    %
    %{
    Example usage (intended, once the view takes a figure):

    >> fig = uifigure("Name", "MSE Lab", "Position", [500, 500, 1100, 850]);
    >> model = AppModel();
    >> view = AppView(fig);
    >> controller = AppController(model, view);

    Forcing functions are built separately with SignalBuilderApp.

    %}

    delete(timerfindall);             % close any leftover timers from a previous run

    model       = AppModel();
    view        = AppView();
    controller  = AppController();

    assignin('base', 'mse_app_controllers', controller);  % keep a handle alive in the MATLAB workspace
end