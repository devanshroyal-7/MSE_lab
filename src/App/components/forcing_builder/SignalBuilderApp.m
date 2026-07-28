function tsData = SignalBuilderApp()
    % app = struct();

    fig = uifigure("Name", "Forcing Function Builder", "Position", [500, 500, 940, 630]);

    model = SignalBuilderModel();
    view = SignalBuilderView(fig);
    controller = SignalBuilderController(model, view);

    fig.CloseRequestFcn = @(~, ~) cleanupApp(fig, model, view, controller);

    uiwait(fig);
    
    if isvalid(controller) && controller.IsFinished

        [t, y] = model.compileCompositeSignal();

        tsData = timeseries(y, t);
        
        assignin('base', 'sim_input', tsData);
    else
        tsData = [];
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