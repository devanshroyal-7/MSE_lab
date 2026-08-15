classdef AppController < handle
    % Glue between AppModel and AppView. Start Simulation compiles/connects
<<<<<<< HEAD
    % Desktop Real-Time and waits until stop or a 30 s timeout. Create Forcing
    % Function opens SignalBuilderApp. Save Output writes a .mat of logged data.
=======
    % Desktop Real-Time; Create Forcing Function opens SignalBuilderApp and
    % draws the result on the reference plot. Save Output is still a stub.
>>>>>>> origin/main
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
<<<<<<< HEAD
            timeout_s = obj.Model.RunTimeout;
            d = [];

            obj.View.setAppEnabled(false);
            obj.View.setSimLampRunning(true);
            obj.View.updateResponsePlot([], []);
=======
>>>>>>> origin/main

            try
                d = uiprogressdlg(figHandle, ...
                    "Title", "Simulink Desktop-Real Time", ...
                    "Message", "Compiling C code & connecting to real-time target...", ...
                    "Indeterminate", "on");
                drawnow;

<<<<<<< HEAD
                tConnect = tic;
                obj.Model.connectTarget();

                while strcmp(obj.Model.getSimulationStatus(), 'stopped') && toc(tConnect) < timeout_s
                    pause(0.05);
                    drawnow;
                end

                close(d);
                d = [];

                if strcmp(obj.Model.getSimulationStatus(), 'stopped')
                    errordlg("Model failed to enter real-time execution", "Target Error");
                else
                    obj.Model.startSimulation();
                    obj.View.updateResponsePlot([], []);

                    tRun = tic;
                    runLimit = obj.Model.S + timeout_s;

                    while obj.Model.isSimulationRunning() && toc(tRun) < runLimit
                        obj.plotLiveResponse();
                        pause(0.05);
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
=======
                obj.Model.startSimulation();
                
                while true
                    if obj.Model.isSimulationRunning() || strcmp(obj.Model.getSimulationStatus(), 'stopped')
                        break;
                    end

                    pause(0.1)
                end

                close(d);

                if obj.Model.isSimulationRunning()
                    disp('Simulation is running')
                    % start(obj.StreamingTimer)
                else
                    errordlg("Model failed to enter real-time execution", "Target Error");
                end

            catch ME
                if exist('d', 'var') && isvalid(d)
                    close(d);
                end 
                errordlg(ME.message, 'Simulation Launch Failed');
            end
>>>>>>> origin/main
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
<<<<<<< HEAD
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
            [t, y] = obj.Model.getLiveCart1Position();
            if isempty(t) || isempty(y)
                return;
            end
            obj.View.updateResponsePlot(t, y);
=======
            % obj
>>>>>>> origin/main
        end
    end
end