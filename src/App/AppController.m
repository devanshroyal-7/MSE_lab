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
            obj.Model.prepareNewRun();
            obj.View.updateResponsePlot([], [], 1);
            obj.View.updateResponsePlot([], [], 2);
            obj.View.setResponseStatus("");
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
            liveCart = obj.View.livePlotCart();
            obj.View.showLiveResponseScope(1 / obj.Model.T, liveCart);
            obj.Model.connectLiveTimeScope(obj.View.getResponseTimeScope(), liveCart);

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

                        % Bind once after connect. Recreating uitimescope /
                        % simulation() on run 2+ leaves the live view empty
                        % because SLDRT does not reattach LoggedSignals.
                        if k == 1
                            obj.Model.connectLiveTimeScope( ...
                                obj.View.getResponseTimeScope(), liveCart);
                        end
                        obj.Model.startSimulation();

                        tRun = tic;
                        runLimit = obj.Model.S + timeout_s;

                        while ~obj.StopRequested ...
                                && obj.Model.isSimulationRunning() ...
                                && toc(tRun) < runLimit
                            pause(0.1);
                            drawnow;
                        end

                        if obj.StopRequested || obj.Model.isSimulationRunning()
                            obj.Model.haltKernel();
                        end

                        obj.waitUntilStopped(5);
                        obj.Model.loadKernelLoggedSignals();
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
                    obj.View.restoreResponseAxes();
                    obj.plotAccumulated(acc);
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
                if obj.RunInProgress
                    obj.Model.haltKernel();
                else
                    obj.Model.stopSimulation();
                    obj.restoreIdleUi();
                end
            catch
            end
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
                obj.View.setFreqDisplayMax(obj.Model.displayFreqMax());
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
            obj.View.setFreqDisplayMax(FftAnalyzer.DisplayFreqMax);
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
                obj.View.restoreResponseAxes();
            catch
            end
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

        function plotLoggedResponse(obj)
            [t1, y1] = obj.Model.getKernelLoggedCartPosition(1);
            obj.View.updateResponsePlot(t1, y1, 1);
            [t2, y2] = obj.Model.getKernelLoggedCartPosition(2);
            obj.View.updateResponsePlot(t2, y2, 2);
            if isempty(t1) && isempty(t2)
                obj.View.setResponseStatus( ...
                    "No kernel log (~S/T samples). Last ExtMode dump ignored.");
            else
                obj.View.setResponseStatus("");
            end
            [tRef, yRef] = obj.Model.getLoggedForcing();
            if ~isempty(tRef) && ~isempty(yRef)
                obj.View.updateControlsReferenceInput(tRef, yRef);
            end
            [tErr, yErr] = obj.Model.getKernelLoggedError();
            if ~isempty(tErr) && ~isempty(yErr)
                obj.View.updateControlsError(tErr, yErr);
            end
            [tEff, yEff] = obj.Model.getKernelLoggedControlEffort();
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
            [t1, x1] = obj.Model.getKernelLoggedCartPosition(1);
            obj.View.updateResponseFft(FftAnalyzer.compute(t1, x1), 1);
            [t2, x2] = obj.Model.getKernelLoggedCartPosition(2);
            obj.View.updateResponseFft(FftAnalyzer.compute(t2, x2), 2);
        end

        function plotControlsBode(obj)
            [tU, u] = obj.Model.getLoggedForcing();
            [t1, y1] = obj.Model.getKernelLoggedCartPosition(1);
            obj.View.updateControlsBode(FftAnalyzer.fromInputOutput(tU, u, t1, y1), 1);
            [t2, y2] = obj.Model.getKernelLoggedCartPosition(2);
            obj.View.updateControlsBode(FftAnalyzer.fromInputOutput(tU, u, t2, y2), 2);
        end

        function plotFrf(obj)
            [tF, f] = obj.Model.getLoggedForcing();
            [t1, x1] = obj.Model.getKernelLoggedCartPosition(1);
            obj.View.updateFrf(FrfAnalyzer.compute(tF, f, t1, x1, false), false, 1);
            [t2, x2] = obj.Model.getKernelLoggedCartPosition(2);
            obj.View.updateFrf(FrfAnalyzer.compute(tF, f, t2, x2, false), false, 2);
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
            [t1, y1] = obj.Model.getKernelLoggedCartPosition(1);
            if ~isempty(t1) && ~isempty(y1)
                acc.tResp1{end+1} = t1(:);
                acc.yResp1{end+1} = y1(:);
            end

            [t2, y2] = obj.Model.getKernelLoggedCartPosition(2);
            if ~isempty(t2) && ~isempty(y2)
                acc.tResp2{end+1} = t2(:);
                acc.yResp2{end+1} = y2(:);
            end

            [tErr, yErr] = obj.Model.getKernelLoggedError();
            if ~isempty(tErr) && ~isempty(yErr)
                acc.tErr{end+1} = tErr(:);
                acc.yErr{end+1} = yErr(:);
            end

            [tEff, yEff] = obj.Model.getKernelLoggedControlEffort();
            if ~isempty(tEff) && ~isempty(yEff)
                acc.tEff{end+1} = tEff(:);
                acc.yEff{end+1} = yEff(:);
            end

            [tU, u] = obj.Model.getLoggedForcing();
            acc.forceSpec{end+1} = FftAnalyzer.compute(tU, u);
            acc.respSpec1{end+1} = FftAnalyzer.compute(t1, y1);
            acc.respSpec2{end+1} = FftAnalyzer.compute(t2, y2);
            acc.bodeSpec1{end+1} = FftAnalyzer.fromInputOutput(tU, u, t1, y1);
            acc.bodeSpec2{end+1} = FftAnalyzer.fromInputOutput(tU, u, t2, y2);
            acc.frfSpec1{end+1} = FrfAnalyzer.compute(tU, u, t1, y1, false);
            acc.frfSpec2{end+1} = FrfAnalyzer.compute(tU, u, t2, y2, false);
            acc.n = acc.n + 1;
        end

        function plotAccumulated(obj, acc)
            obj.View.setFreqDisplayMax(obj.Model.displayFreqMax());
            [t1, y1] = AppController.meanSignals(acc.tResp1, acc.yResp1);
            obj.View.updateResponsePlot(t1, y1, 1);

            [t2, y2] = AppController.meanSignals(acc.tResp2, acc.yResp2);
            obj.View.updateResponsePlot(t2, y2, 2);

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
            obj.View.updateResponseFft(FftAnalyzer.average(acc.respSpec1), 1);
            obj.View.updateResponseFft(FftAnalyzer.average(acc.respSpec2), 2);
            obj.View.updateControlsBode(FftAnalyzer.average(acc.bodeSpec1), 1);
            obj.View.updateControlsBode(FftAnalyzer.average(acc.bodeSpec2), 2);

            frf1 = FrfAnalyzer.average(acc.frfSpec1);
            frf2 = FrfAnalyzer.average(acc.frfSpec2);
            nFrf = AppController.countNonemptyFrf(acc.frfSpec1);
            showCoherence = nFrf >= 2;
            obj.View.updateFrf(frf1, showCoherence, 1);
            obj.View.updateFrf(frf2, showCoherence, 2);
            if isempty(t1) && isempty(t2)
                obj.View.setResponseStatus( ...
                    "No kernel log (~S/T samples). Last ExtMode dump ignored.");
            else
                obj.View.setResponseStatus("");
            end

            obj.Model.LastAverage = struct( ...
                "n", acc.n, ...
                "t", t1, ...
                "y", y1, ...
                "t2", t2, ...
                "y2", y2, ...
                "t_error", tErr, ...
                "error", yErr, ...
                "t_effort", tEff, ...
                "control_effort", yEff, ...
                "frf", frf1, ...
                "frf2", frf2);
        end
    end

    methods (Static, Access = private)
        function acc = emptyAverage()
            acc = struct( ...
                "n", 0, ...
                "tResp1", {{}}, ...
                "yResp1", {{}}, ...
                "tResp2", {{}}, ...
                "yResp2", {{}}, ...
                "tErr", {{}}, ...
                "yErr", {{}}, ...
                "tEff", {{}}, ...
                "yEff", {{}}, ...
                "forceSpec", {{}}, ...
                "respSpec1", {{}}, ...
                "respSpec2", {{}}, ...
                "bodeSpec1", {{}}, ...
                "bodeSpec2", {{}}, ...
                "frfSpec1", {{}}, ...
                "frfSpec2", {{}});
        end

        function n = countNonemptyFrf(frfSpec)
            n = 0;
            for i = 1:numel(frfSpec)
                if ~isempty(frfSpec{i}) && isfield(frfSpec{i}, 'n') ...
                        && frfSpec{i}.n > 0
                    n = n + 1;
                end
            end
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
