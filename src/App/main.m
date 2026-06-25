function main()
    delete(timerfindall);             % close any existing instances

    model       = AppModel();
    view        = AppView();
    controller  = AppController();

    assignin('base', 'mse_app_controllers', controller);
end