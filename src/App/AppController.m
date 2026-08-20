classdef AppController < handle
    % Glue between AppModel and AppView. Start Simulation compiles/connects
    % Desktop Real-Time and waits until stop or a 30 s timeout. When Average
    % Runs is enabled, the same forcing function is repeated N times on one
    % connection (1 s gap between runs); plots show the running average.
    % Stop Simulation is the UI equivalent of Ctrl+C: halt the kernel,
    % disconnect, restore Start / Save / etc. Create Forcing Function (or
    % Create Reference Trajectory when the controller is on) opens
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

    properties (Access = private)
        StopRequested (1,1) logical = false
        RunInProgress (1,1) logical = false
    end

    methods 
        function obj = AppController(model, view)
            obj.Model = model;
            obj.View = view;

            % Callback
            obj.View.fwdRunSimCallbackView = @() obj.handleRunSimCallback();
            obj.View.fwdStopSimCallbackView = @() obj.handleStopSimCallback();
            obj.View.fwdSignalBuilderCallbackView = @() obj.handleSignalBuilderCallback();
            obj.View.fwdSaveOutputCallbackView = @() obj.handleSaveOutputCallback();
            obj.View.fwdEnableControlsCallbackView = @(enabled) obj.handleEnableControlsCallback(enabled);
            obj.View.fwdSimParamsChangedCallbackView = @(k, b, enabled) obj.handleSimParamsChangedCallback(k, b, enabled);
            obj.View.fwdControlParamsChangedCallbackView = @(kp, ki, kd, closedLoop, enabled) obj.handleControlParamsChangedCallback(kp, ki, kd, closedLoop, enabled);
            obj.View.fwdAverageRunsChangedCallbackView = @(enabled) obj.handleAverageRunsChangedCallback(enabled);
        end

        function handleRunSimCallback(obj)
            if obj.RunInProgress
                return;
            end

            figHandle = obj.View.UIFigure;
            timeout_s = obj.Model.RunTimeout;
            d = [];
            obj.StopRequested = false;
            obj.RunInProgress = true;

            obj.View.setAppEnabled(false);
            obj.View.setSimLampRunning(true);
            obj.View.updateResponsePlot([], []);
            obj.View.clearControlsTimePlots();
            obj.View.clearResponseFft();
            obj.View.clearFrf();
            obj.View.clearControlsBode();
            obj.Model.LastAverage = struct();

            if obj.View.averageRunsEnabled()
                nRuns = obj.View.runsToAverage();
            else
                nRuns = 1;
            end
            if nRuns >= 2
                obj.View.setAverageRunProgress(1, nRuns);
            end

            % Ctrl+C in the Command Window still runs this, so Start/Save
            % cannot stay greyed out after an interrupt.
            cleanupObj = onCleanup(@() obj.finishRun()); %#ok<NASGU>

            try
                d = uiprogressdlg(figHandle, ...
                    "Title", "Simulink Desktop-Real Time", ...
                    "Message", "Compiling C code & connecting to real-time target...", ...
                    "Indeterminate", "on", ...
                    "Cancelable", "on", ...
                    "CancelText", "Stop");
                drawnow;

                tConnect = tic;
                obj.Model.connectTarget();

                while ~obj.StopRequested ...
                        && ~obj.dialogCancelRequested(d) ...
                        && strcmp(obj.Model.getSimulationStatus(), 'stopped') ...
                        && toc(tConnect) < timeout_s
                    pause(0.05);
                    drawnow;
                end

                if obj.dialogCancelRequested(d)
                    obj.StopRequested = true;
                end

                if ~isempty(d) && isvalid(d)
                    close(d);
                end
                d = [];

                if obj.StopRequested
                    obj.Model.stopSimulation();
                    return;
                end

                if strcmp(obj.Model.getSimulationStatus(), 'stopped')
                    errordlg("Model failed to enter real-time execution", "Target Error");
                else
                    acc = AppController.emptyAverage();
                    for k = 1:nRuns
                        if obj.StopRequested
                            break;
                        end

                        if nRuns >= 2
                            obj.View.setAverageRunProgress(k, nRuns);
                            drawnow;
                        end

                        obj.Model.startSimulation();
                        if k == 1
                            obj.View.updateResponsePlot([], []);
                        end

                        tRun = tic;
                        runLimit = obj.Model.S + timeout_s;

                        while ~obj.StopRequested ...
                                && obj.Model.isSimulationRunning() ...
                                && toc(tRun) < runLimit
                            obj.plotLiveResponse();
                            % pause already flushes graphics. Extra drawnow here
                            % plus yyaxis/xlim on uiaxes causes SceneTree
                            % replaceChild warnings.
                            pause(0.1);
                        end

                        if obj.StopRequested || obj.Model.isSimulationRunning()
                            obj.Model.haltKernel();
                        end

                        obj.waitUntilStopped(5);
                        pause(0.2);
                        acc = obj.accumulateRun(acc);
                        obj.plotAccumulated(acc);

                        if obj.StopRequested
                            break;
                        end
                        if k < nRuns
                            % SLDRT needs a beat after halt before the next
                            % start will take; no extra progress dialog.
                            obj.pauseInterruptible(1.0);
                        end
                    end
                end

            catch ME
                if ~isempty(d) && isvalid(d)
                    close(d);
                end
                try
                    obj.Model.stopSimulation();
                catch
                end
                if ~obj.StopRequested && ~obj.isInterrupt(ME)
                    errordlg(ME.message, 'Simulation Launch Failed');
                end
            end
        end

        function handleStopSimCallback(obj)
            obj.StopRequested = true;
            try
                obj.Model.stopSimulation();
            catch
            end
            obj.restoreIdleUi();
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
            obj.View.clearFrf();
            obj.View.clearControlsBode();
        end

        function handleSimParamsChangedCallback(obj, k, b, enabled)
            obj.Model.setSimulatedParameters(k, b, enabled);
        end

        function handleControlParamsChangedCallback(obj, kp, ki, kd, closedLoop, enabled)
            obj.Model.setControlParameters(kp, ki, kd, closedLoop, enabled);
        end

        function handleAverageRunsChangedCallback(obj, enabled)
            if ~enabled
                obj.View.clearFrfCoherence();
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
        function finishRun(obj)
            try
                obj.Model.stopSimulation();
            catch
            end
            obj.restoreIdleUi();
            obj.RunInProgress = false;
        end

        function restoreIdleUi(obj)
            obj.View.setSimLampRunning(false);
            obj.View.setAppEnabled(true);
            obj.View.clearAverageRunProgress();
        end

        function tf = dialogCancelRequested(~, d)
            tf = ~isempty(d) && isvalid(d) && d.CancelRequested;
        end

        function tf = isInterrupt(~, ME)
            tf = any(strcmp(ME.identifier, ...
                {'MATLAB:interrupt', 'MATLAB:OperationTerminated'})) ...
                || contains(ME.message, 'Operation terminated', 'IgnoreCase', true);
        end

        function plotLiveResponse(obj)
            [t, y] = obj.Model.getLiveCart1Position();
            tab = obj.View.selectedTabTitle();
            if tab == "Controls - Time"
                [tRef, yRef] = obj.Model.getLoggedForcing();
                [tErr, yErr] = obj.Model.getLiveError();
                [tEff, yEff] = obj.Model.getLiveControlEffort();
                obj.View.updateLiveControlsPlots(t, y, tRef, yRef, tErr, yErr, tEff, yEff);
            else
                obj.View.updateLivePlots(t, y);
            end
        end

        function plotLoggedResponse(obj)
            [t, y] = obj.Model.getLiveCart1Position();
            if ~isempty(t) && ~isempty(y)
                obj.View.updateResponsePlot(t, y);
            end
            [tRef, yRef] = obj.Model.getLoggedForcing();
            if ~isempty(tRef) && ~isempty(yRef)
                obj.View.updateControlsReferenceInput(tRef, yRef);
            end
            [tErr, yErr] = obj.Model.getLiveError();
            if ~isempty(tErr) && ~isempty(yErr)
                obj.View.updateControlsError(tErr, yErr);
            end
            [tEff, yEff] = obj.Model.getLiveControlEffort();
            if ~isempty(tEff) && ~isempty(yEff)
                obj.View.updateControlsEffort(tEff, yEff);
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

        function plotControlsBode(obj)
            [tY, y] = obj.Model.getLoggedResponse();
            [tU, u] = obj.Model.getLoggedForcing();
            H = FftAnalyzer.fromInputOutput(tU, u, tY, y);
            obj.View.updateControlsBode(H);
        end

        function plotFrf(obj)
            [tF, f] = obj.Model.getLoggedForcing();
            [tX, x] = obj.Model.getLoggedResponse();
            result = FrfAnalyzer.compute(tF, f, tX, x, false);
            obj.View.updateFrf(result, false);
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

        function waitUntilStopped(obj, timeout_s)
            t0 = tic;
            while obj.Model.isSimulationRunning() && toc(t0) < timeout_s
                if obj.StopRequested
                    return;
                end
                pause(0.05);
                drawnow;
            end
        end

        function pauseInterruptible(obj, seconds)
            t0 = tic;
            while toc(t0) < seconds
                if obj.StopRequested
                    return;
                end
                pause(0.05);
                drawnow;
            end
        end

        function acc = accumulateRun(obj, acc)
            [tY, y] = obj.Model.getLoggedResponse();
            if ~isempty(tY) && ~isempty(y)
                acc.tResp{end+1} = tY(:);
                acc.yResp{end+1} = y(:);
            end

            [tErr, yErr] = obj.Model.getLiveError();
            if ~isempty(tErr) && ~isempty(yErr)
                acc.tErr{end+1} = tErr(:);
                acc.yErr{end+1} = yErr(:);
            end

            [tEff, yEff] = obj.Model.getLiveControlEffort();
            if ~isempty(tEff) && ~isempty(yEff)
                acc.tEff{end+1} = tEff(:);
                acc.yEff{end+1} = yEff(:);
            end

            [tU, u] = obj.Model.getLoggedForcing();
            acc.forceSpec{end+1} = FftAnalyzer.compute(tU, u);
            acc.respSpec{end+1} = FftAnalyzer.compute(tY, y);
            acc.bodeSpec{end+1} = FftAnalyzer.fromInputOutput(tU, u, tY, y);
            acc.frfSpec{end+1} = FrfAnalyzer.compute(tU, u, tY, y, false);
            acc.n = acc.n + 1;
        end

        function plotAccumulated(obj, acc)
            [tY, y] = AppController.meanSignals(acc.tResp, acc.yResp);
            if ~isempty(tY)
                obj.View.updateResponsePlot(tY, y);
            end

            [tErr, yErr] = AppController.meanSignals(acc.tErr, acc.yErr);
            if ~isempty(tErr)
                obj.View.updateControlsError(tErr, yErr);
            end

            [tEff, yEff] = AppController.meanSignals(acc.tEff, acc.yEff);
            if ~isempty(tEff)
                obj.View.updateControlsEffort(tEff, yEff);
            end

            [tRef, yRef] = obj.Model.getLoggedForcing();
            if ~isempty(tRef)
                obj.View.updateControlsReferenceInput(tRef, yRef);
            end

            obj.View.updateForcingFft(FftAnalyzer.average(acc.forceSpec));
            obj.View.updateResponseFft(FftAnalyzer.average(acc.respSpec));
            obj.View.updateControlsBode(FftAnalyzer.average(acc.bodeSpec));

            frf = FrfAnalyzer.average(acc.frfSpec);
            nFrf = 0;
            for i = 1:numel(acc.frfSpec)
                if ~isempty(acc.frfSpec{i}) && isfield(acc.frfSpec{i}, 'n') ...
                        && acc.frfSpec{i}.n > 0
                    nFrf = nFrf + 1;
                end
            end
            obj.View.updateFrf(frf, nFrf >= 2);

            obj.Model.LastAverage = struct( ...
                "n", acc.n, ...
                "t", tY, ...
                "y", y, ...
                "t_error", tErr, ...
                "error", yErr, ...
                "t_effort", tEff, ...
                "control_effort", yEff, ...
                "frf", frf);
        end
    end

    methods (Static, Access = private)
        function acc = emptyAverage()
            acc = struct( ...
                "n", 0, ...
                "tResp", {{}}, ...
                "yResp", {{}}, ...
                "tErr", {{}}, ...
                "yErr", {{}}, ...
                "tEff", {{}}, ...
                "yEff", {{}}, ...
                "forceSpec", {{}}, ...
                "respSpec", {{}}, ...
                "bodeSpec", {{}}, ...
                "frfSpec", {{}});
        end

        function [tMean, yMean] = meanSignals(tCell, yCell)
            tMean = [];
            yMean = [];
            n = min(numel(tCell), numel(yCell));
            idx = [];
            for i = 1:n
                if ~isempty(tCell{i}) && ~isempty(yCell{i}) ...
                        && numel(tCell{i}) >= 2 && numel(yCell{i}) >= 2
                    idx(end+1) = i; %#ok<AGROW>
                end
            end
            if isempty(idx)
                return;
            end
            t0 = tCell{idx(1)}(:);
            y0 = yCell{idx(1)}(:);
            m = min(numel(t0), numel(y0));
            tGrid = t0(1:m);
            acc = zeros(size(tGrid));
            for i = idx
                ti = tCell{i}(:);
                yi = yCell{i}(:);
                mi = min(numel(ti), numel(yi));
                acc = acc + interp1(ti(1:mi), yi(1:mi), tGrid, 'linear', 'extrap');
            end
            tMean = tGrid;
            yMean = acc / numel(idx);
        end
    end
end
