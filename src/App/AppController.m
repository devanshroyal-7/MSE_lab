classdef AppController < handle
    % Glue between AppModel and AppView. Start Simulation compiles/connects
    % Desktop Real-Time and waits until stop or a 30 s timeout. Create Forcing
    % Function (or Create Reference Trajectory when the controller is on) opens
    % SignalBuilderApp. Save Output writes a .mat of logged data.
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
            obj.View.fwdEnableControlsCallbackView = @(enabled) obj.handleEnableControlsCallback(enabled);
        end

        function handleRunSimCallback(obj)
            figHandle = obj.View.UIFigure;
            timeout_s = obj.Model.RunTimeout;
            d = [];

            obj.View.setAppEnabled(false);
            obj.View.setSimLampRunning(true);
            obj.View.updateResponsePlot([], []);
            obj.View.clearControlsTimePlots();
            obj.View.clearResponseFft();

            try
                d = uiprogressdlg(figHandle, ...
                    "Title", "Simulink Desktop-Real Time", ...
                    "Message", "Compiling C code & connecting to real-time target...", ...
                    "Indeterminate", "on");
                drawnow;

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
                    obj.plotResponseFft();
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
            if obj.View.controlsEnabled()
                mode = "reference";
            else
                mode = "force";
            end

            sim_input = SignalBuilderApp("Mode", mode);

            if ~isempty(sim_input) && isa(sim_input, 'timeseries') && sim_input.Length > 0
                obj.Model.setForcingInput(sim_input);
                stopTime = sim_input.Time(end);

                obj.View.updateReferencePlot(sim_input)
                obj.plotForcingFft(sim_input)

                fprintf('Signal successfully set (%s). Duration %.2f seconds.\n', ...
                    mode, stopTime);
            else
                fprintf('Signal Builder closed without saving changes.\n');
            end
        end

        function handleEnableControlsCallback(obj, enabled)
            if enabled
                quantity = SignalQuantity.reference();
            else
                quantity = SignalQuantity.force();
            end

            obj.View.setSignalBuilderButtonText(quantity.sidebarButtonText);
            obj.View.setReferenceQuantity(quantity);
            obj.Model.clearForcingInput();
            obj.View.clearReferencePlot();
            obj.View.clearForcingFft();
            obj.View.clearResponseFft();
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
            if ~isempty(t) && ~isempty(y)
                obj.View.updateResponsePlot(t, y);
            end
            [tf, f] = obj.Model.getLiveFInput();
            if ~isempty(tf) && ~isempty(f)
                obj.View.updateControlsReferenceInput(tf, f);
            end
        end

        function plotLoggedResponse(obj)
            [t, y] = obj.Model.getLiveCart1Position();
            if ~isempty(t) && ~isempty(y)
                obj.View.updateResponsePlot(t, y);
            end
            [tf, f] = obj.Model.getLiveFInput();
            if ~isempty(tf) && ~isempty(f)
                obj.View.updateControlsReferenceInput(tf, f);
            end
        end

        function plotForcingFft(obj, ts)
            if nargin < 2
                ts = obj.Model.ForcingSignal;
            end
            spec = obj.fftFromTimeseries(ts);
            obj.View.updateForcingFft(spec);
        end

        function plotResponseFft(obj)
            [t, x] = obj.Model.getLoggedResponse();
            spec = FftAnalyzer.compute(t, x);
            obj.View.updateResponseFft(spec);
        end

        function spec = fftFromTimeseries(~, ts)
            if isempty(ts) || ~isa(ts, 'timeseries') || ts.Length == 0
                spec = FftAnalyzer.emptySpectrum();
                return;
            end
            t = ts.Time(:);
            y = squeeze(ts.Data);
            y = y(:);
            spec = FftAnalyzer.compute(t, y);
        end
    end
end
