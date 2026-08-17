function tsData = SignalBuilderApp(opts)
    % Standalone signal-builder UI. Blocks until Finish or the figure is closed.
    % On Finish, returns a timeseries. Closed without Finish returns an empty
    % timeseries (Length == 0). The main app copies that into sim_input.
    %
    % Mode "force" (default) labels and clamps y in newtons. Mode "reference"
    % is a displacement trajectory in mm, used when the controller is on.
    %
    %{
    Example usage:

    >> tsData = SignalBuilderApp;     % modal dialog; add signals, then Finish
    >> plot(tsData);

    >> tsData = SignalBuilderApp("Mode", "reference");   % mm + travel limit

    % Closed without Finish:
    >> tsData.Length                  % 0

    %}

    arguments
        opts.Mode (1,1) string {mustBeMember(opts.Mode, ["force", "reference"])} = "force"
    end

    tsData = timeseries();
    quantity = SignalQuantity.fromMode(opts.Mode);

    fig = uifigure("Name", quantity.WindowTitle, "Position", [500, 500, 940, 630]);

    model = SignalBuilderModel(quantity);
    view = SignalBuilderView(fig, quantity);
    controller = SignalBuilderController(model, view);

    fig.CloseRequestFcn = @(~, ~) cleanupApp(fig, model, view, controller);

    drawnow;
    uiwait(fig);    % returns after Finish (uiresume) or CloseRequestFcn

    if isvalid(controller) && controller.IsFinished

        [t, y] = model.compileFinalSignal();

        tsData = timeseries(y, t);
        tsData.UserData = struct( ...
            "CycleDuration", model.CycleDuration, ...
            "NumCycles", model.NumCycles, ...
            "Quantity", char(quantity.Mode), ...
            "Unit", char(quantity.Unit));
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
