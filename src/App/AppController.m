classdef AppController < handle
    % Glue between AppModel and AppView. Start Simulation compiles/connects
    % Desktop Real-Time and waits until stop or a 30 s timeout. Create Forcing
    % Function opens SignalBuilderApp. Save Output writes a .mat of logged data.
    %
    %{
    Example usage:

    >> fig = uifigure("Position", [500, 500, 1900, 900]);
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
            obj.View.fwdRunSimCallbackView = @() obj.handleRunSimCallback();
            obj.View.fwdSignalBuilderCallbackView = @() obj.handleSignalBuilderCallback();
            obj.View.fwdSaveOutputCallbackView = @() obj.handleSaveOutputCallback();
        end

        function handleRunSimCallback(obj)
            figHandle = obj.View.UIFigure;
            timeout_s = obj.Model.RunTimeout;
            d = [];

            obj.View.setAppEnabled(false);
            obj.View.setSimLampRunning(true);

            try
                d = uiprogressdlg(figHandle, ...
                    "Title", "Simulink Desktop-Real Time", ...
                    "Message", "Compiling C code & connecting to real-time target...", ...
                    "Indeterminate", "on");
                drawnow;

                t0 = tic;
                obj.Model.prepareLiveStreaming();
                obj.Model.connectTarget();

                while strcmp(obj.Model.getSimulationStatus(), 'stopped') && toc(t0) < timeout_s
                    pause(0.1);
                    drawnow;
                end

                close(d);
                d = [];

                if strcmp(obj.Model.getSimulationStatus(), 'stopped')
                    errordlg("Model failed to enter real-time execution", "Target Error");
                else
                    obj.Model.startSimulation();
                    obj.View.updateResponsePlot([], []);

                    while obj.Model.isSimulationRunning() && toc(t0) < timeout_s
                        obj.plotLiveResponse();
                        pause(0.1);
                        drawnow;
                    end

                    if obj.Model.isSimulationRunning()
                        obj.Model.stopSimulation();
                    end

                    pause(0.2);
                    obj.plotLoggedResponse();
                end

            catch ME
                if ~isempty(d) && isvalid(d)
                    close(d);
                end
                errordlg(ME.message, 'Simulation Launch Failed');
            end

            obj.View.setSimLampRunning(false);
            obj.View.setAppEnabled(true);
        end

        function handleSignalBuilderCallback(obj)
            sim_input  = SignalBuilderApp();

            if ~isempty(sim_input) && isa(sim_input, 'timeseries') && sim_input.Length > 0
                obj.Model.setForcingInput(sim_input);
                stopTime = sim_input.Time(end);
                
                obj.View.updateReferencePlot(sim_input)

                fprintf('Forcing signal successfully set. Duration %.2f seconds.\n', stopTime);
            else
                fprintf('Signal Builder closed without saving changes.\n');
            end
            
        end

        function handleSaveOutputCallback(obj)
            [file, path] = uiputfile('*.mat', 'Save run data');
            if isequal(file, 0)
                return;
            end

            run = obj.Model.collectRunData();
            save(fullfile(path, file), 'run');
        end
    end

    methods (Access = private)
        function plotLiveResponse(obj)
            [t, y] = obj.Model.getLiveCart1Position();
            if isempty(t) || isempty(y)
                return;
            end
            obj.View.updateResponsePlot(t, y);
        end

        function plotLoggedResponse(obj)
            if ~evalin('base', "exist('rt_time', 'var')") || ...
                    ~evalin('base', "exist('cart1_position', 'var')")
                return;
            end

            t = squeeze(evalin('base', 'rt_time'));
            y = squeeze(evalin('base', 'cart1_position'));
            obj.View.updateResponsePlot(t, y);
        end
    end
end