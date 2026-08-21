function main()
    % Entry point for the MSE lab app. Builds a figure, then wires
    % AppModel / AppView / AppController. CloseRequestFcn tears them down.
    %
    %{
    Example usage (from MATLAB, with src/App on the path):

    >> main

    % Or construct the pieces yourself:
    >> fig = uifigure("Name", "MSE Lab", "Position", [500, 500, 1900, 900]);
    >> model = AppModel();
    >> view = AppView(fig);
    >> controller = AppController(model, view);

    Create Forcing Function on the sidebar opens SignalBuilderApp (force).
    Enable Controller switches that button to Create Reference Trajectory (mm).

    %}

    delete(timerfindall);             % close any leftover timers from a previous run

    fig = uifigure("Name", "Mechanical System Experimenation App", "Position", [100, 100, 1900, 1000]);

    model       = AppModel();
    view        = AppView(fig);
    controller  = AppController(model, view);

    fig.CloseRequestFcn = @(~, ~) cleanupApp(fig, model, view, controller);

    % uiwait is intentionally omitted so the Command Window stays usable
    % while the figure is open. Close the window to run cleanupApp.
end

function cleanupApp(fig, model, view, controller)
    if isvalid(controller), delete(controller); end
    if isvalid(model),      delete(model);      end
    if isvalid(view),       delete(view);       end
    if isvalid(fig),        delete(fig);        end
end
