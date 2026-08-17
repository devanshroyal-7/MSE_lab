function tsData = SignalBuilderApp()
    % Standalone forcing-function UI. Blocks until Finish or the figure is closed.
    % On Finish, returns a timeseries. Closed without Finish returns an empty
    % timeseries (Length == 0). The main app copies that into sim_input.
    %
    %{
    Example usage:

    >> tsData = SignalBuilderApp;     % modal dialog; add signals, then Finish
    >> plot(tsData);

    % Closed without Finish:
    >> tsData.Length                  % 0

    %}

    tsData = timeseries();

    fig = uifigure("Name", "Forcing Function Builder", "Position", [500, 500, 940, 630]);

    model = SignalBuilderModel();
    view = SignalBuilderView(fig);
    controller = SignalBuilderController(model, view);

    fig.CloseRequestFcn = @(~, ~) cleanupApp(fig, model, view, controller);

    drawnow;
    uiwait(fig);    % returns after Finish (uiresume) or CloseRequestFcn

    if isvalid(controller) && controller.IsFinished

        [t, y] = model.compileFinalSignal();

        tsData = timeseries(y, t);
        tsData.UserData = struct( ...
            "CycleDuration", model.CycleDuration, ...
            "NumCycles", model.NumCycles);
    end

    delete(controller)
    delete(view)
    if isvalid(fig),        delete(fig);        end
end

function cleanupApp(fig, model, view, controller)
    if isvalid(controller), delete(controller); end
    if isvalid(model),      delete(model);      end
    if isvalid(view),       delete(view);       end
    if isvalid(fig),        delete(fig);        end
end
