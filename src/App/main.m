function main()
    delete(timerfindall);             % close any existing instances

    fig = uifigure("Name", "Mechanical System Experimenation App", "Position", [500, 500, 1900, 900]);

    model       = AppModel();
    view        = AppView(fig);
    controller  = AppController(model, view);

    fig.CloseRequestFcn = @(~, ~) cleanupApp(fig, model, view, controller);

    % uiwait(fig);
    % 
    % delete(controller)
    % delete(view)
    % if isvalid(fig),    delete(fig);        end
end

function cleanupApp(fig, model, view, controller)
    if isvalid(controller), delete(controller); end
    if isvalid(model),      delete(model);      end
    if isvalid(view),       delete(view);       end
    if isvalid(fig),        delete(fig);        end
end