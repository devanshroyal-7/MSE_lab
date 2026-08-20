classdef AppModel < handle
    % Application model: loads MSE_PLANT and feeds forcing / sim parameters
    % into the MATLAB base workspace so Desktop Real-Time can read them.
    %
    %{
    Example usage:

    >> ts = SignalBuilderApp;             % or timeseries(y, t) from a model
    >> model = AppModel;                  % load_system('MSE_PLANT')
    >> model.setForcingInput(ts);         % also sets StopTime and sim_input
    >> model.startSimulation;             % external (SLDRT) mode

    %}

    % Public properties that correspond to the Simulink model
    properties (Access = public, Transient)
        Simulation 
        T (1,1) double {mustBeFloat} = 0.001;

    end

    properties (Constant, Access = protected)
        % Hardware parameters
        r           (1,1) double = 0.01;  % pinion gear radius [m]
        Kt          (1,1) double = 0.028; % torque constant [Nm/A]
        motor_eff   (1,1) double = 1.0;   % system efficiency       
    end

    properties (Access = public)
        % Simulation parameters (sidebar values; plant sees 0 until enabled)
        k_sim       (1,1) double = 0;   % simulated stiffness   [N/m]
        b_sim       (1,1) double = 0;   % simulated damping     [Ns/m]
        SimParamsEnabled (1,1) logical = false;

        Kp (1,1) double = 1;
        Ki (1,1) double = 0;
        Kd (1,1) double = 0;
        ClosedLoop (1,1) logical = false;
        ControlsEnabled (1,1) logical = false;

        % Simulation control and configuration
        SimulationModelName (1,1) string = "MSE_PLANT";
        RunTimeout (1,1) double = 30;   % [s] connect/start hang cap (not run length)
        
        S   (1,1) double {mustBeNumeric} = 10;  % simulation time   [s]
        TimeBuffer      (1,:) double = [];
        PositionBuffer  (1,:) double = [];
        VelocityBuffer  (1,:) double = [];
        ForcingTimeBuffer (1,:) double = [];
        ForcingBuffer     (1,:) double = [];
        ErrorTimeBuffer   (1,:) double = [];
        ErrorBuffer       (1,:) double = [];
        EffortTimeBuffer  (1,:) double = [];
        EffortBuffer      (1,:) double = [];
        ForcingSignal           % timeseries object from SignalBuilder

        % External-mode upload buffer (samples). At T=0.001 this is 0.05 s.
        LiveBufferSamples (1,1) double = 50;
    end

    properties (Access = private)
        LiveArmed (1,1) logical = false
        LiveArmedForcing (1,1) logical = false
        LiveArmedError (1,1) logical = false
        LiveArmedEffort (1,1) logical = false
        LiveAcceptLate (1,1) logical = false
        LiveCaptureEnabled (1,1) logical = false
        StaleSdiRunId = []
        StaleSdiRunIds = []
        StaleSdiFingerprint = struct('n', 0, 'tEnd', NaN, 'yEnd', NaN)
        StaleLogFingerprint = struct('n', 0, 'tEnd', NaN, 'yEnd', NaN)
        SdiFreshForThisRun (1,1) logical = false
        AuxLogs = struct()
    end

    events 
        DataUpdated
    end
        

    methods (Access = public)
        function obj = AppModel()
            % Load "MSE_Plant" simulink model
            if ~bdIsLoaded(obj.SimulationModelName)
                load_system(obj.SimulationModelName)
            end
            obj.ensureExternalMode();
            % MSE_PLANT reads hardware conversion constants from 'base'
            assignin('base', "T", obj.T);
            assignin('base', "r", obj.r);
            assignin('base', "Kt", obj.Kt);
            assignin('base', "motor_eff", obj.motor_eff);
            obj.applySimParamsToWorkspace();
            obj.applyControlParamsToWorkspace();
            obj.initAuxLogs();
        end

        function setSimulatedParameters(obj, k, b, enabled)
            obj.k_sim = k;
            obj.b_sim = b;
            obj.SimParamsEnabled = logical(enabled);
        end

        function applySimParamsToWorkspace(obj)
            % MSE_PLANT Gain blocks read k_sim / b_sim from 'base'. Disabled
            % sidebar params still write 0 so a leftover value cannot leak in.
            [k, b] = obj.effectiveSimParams();
            assignin('base', 'k_sim', k);
            assignin('base', 'b_sim', b);
        end

        function [k, b] = effectiveSimParams(obj)
            if obj.SimParamsEnabled
                k = obj.k_sim;
                b = obj.b_sim;
            else
                k = 0;
                b = 0;
            end
        end

        function setControlParameters(obj, kp, ki, kd, closedLoop, enabled)
            obj.Kp = kp;
            obj.Ki = ki;
            obj.Kd = kd;
            obj.ClosedLoop = logical(closedLoop);
            obj.ControlsEnabled = logical(enabled);
        end

        function applyControlParamsToWorkspace(obj)
            % MSE_PLANT reads Kp/Ki/Kd and K_switch from 'base'.
            % K_switch: 0 = open (force passthrough), 1 = closed.
            assignin('base', 'Kp', obj.Kp);
            assignin('base', 'Ki', obj.Ki);
            assignin('base', 'Kd', obj.Kd);
            assignin('base', 'K_switch', obj.effectiveFeedbackSwitch());
        end

        function feedbackSwitch = effectiveFeedbackSwitch(obj)
            if obj.ControlsEnabled && obj.ClosedLoop
                feedbackSwitch = 1;
            else
                feedbackSwitch = 0;
            end
        end

        function setForcingInput(obj, tsInput)
            obj.ForcingSignal = tsInput;
            obj.S = tsInput.Time(end);

            % MSE_PLANT From Workspace / Gain blocks read these from 'base'
            assignin('base', 'sim_input', tsInput);
            obj.applySimParamsToWorkspace();
            obj.applyControlParamsToWorkspace();

            set_param(obj.SimulationModelName, 'StopTime', num2str(obj.S));

            drawnow;
        end

        function clearForcingInput(obj)
            % Drop a leftover force or reference so toggling the controller
            % cannot send 3 N as 3 mm (or the reverse).
            obj.ForcingSignal = timeseries();
            obj.S = 10;
            assignin('base', 'sim_input', obj.ForcingSignal);
            if bdIsLoaded(obj.SimulationModelName)
                set_param(obj.SimulationModelName, 'StopTime', num2str(obj.S));
            end
        end

        function prepareLiveStreaming(obj)
            % SLDRT Run in Kernel uploads Duration-sized buffers. By default
            % only the last buffer is written to the workspace, which is why
            % the response plot showed a blip at t=end. Write every buffer
            % and rearm. These ExtMode settings are part of TARGET_DATA_MAP,
            % so they must be applied before slbuild (and re-applied after,
            % because slbuild restores Duration 20480 from the .slx).
            modelName = char(obj.SimulationModelName);
            if ~bdIsLoaded(modelName)
                load_system(modelName);
            end

            set_param(modelName, 'ExtModeArmWhenConnect', 'on');
            set_param(modelName, 'ExtModeTrigType', 'manual');
            set_param(modelName, 'ExtModeTrigMode', 'normal');
            set_param(modelName, 'ExtModeTrigDuration', ...
                num2str(obj.LiveBufferSamples));
            set_param(modelName, 'ExtModeLogAll', 'on');
            set_param(modelName, 'ExtModeWriteAllDataToWs', 'on');

            daqBlk = find_system(modelName, 'SearchDepth', 1, ...
                'Regexp', 'on', 'Name', '^EMB');
            if ~isempty(daqBlk)
                if iscell(daqBlk)
                    daqBlk = daqBlk{1};
                end
                Simulink.sdi.markSignalForStreaming(daqBlk, 3, 'on');
            end
        end

        function [t, y] = getLoggedForcing(obj)
            if isempty(obj.ForcingSignal) || ~isa(obj.ForcingSignal, 'timeseries') ...
                    || obj.ForcingSignal.Length == 0
                t = [];
                y = [];
                return;
            end
            t = obj.ForcingSignal.Time(:);
            y = squeeze(obj.ForcingSignal.Data);
            y = y(:);
            n = min(numel(t), numel(y));
            t = t(1:n);
            y = y(1:n);
        end

        function [t, y] = getLoggedResponse(obj)
            [t, y] = obj.getLiveCart1Position();
            if ~isempty(y)
                return;
            end
            [t, y] = obj.readWorkspaceNamed('cart1_position');
            y = AppModel.metersToMm(y);
        end

        function [t, y] = peekLiveCart1Position(obj)
            t = obj.TimeBuffer(:);
            y = AppModel.metersToMm(obj.PositionBuffer(:));
        end

        function [t, y] = peekLiveError(obj)
            t = obj.ErrorTimeBuffer(:);
            y = AppModel.metersToMm(obj.ErrorBuffer(:));
        end

        function [t, y] = peekLiveControlEffort(obj)
            t = obj.EffortTimeBuffer(:);
            y = obj.EffortBuffer(:);
        end

        function [t, y] = getLiveCart1Position(obj)
            if obj.LiveCaptureEnabled || obj.LiveAcceptLate
                obj.captureLiveCart1Chunk();
            end
            t = obj.TimeBuffer(:);
            y = AppModel.metersToMm(obj.PositionBuffer(:));
        end

        function [t, y] = getLiveFInput(obj)
            if obj.LiveCaptureEnabled || obj.LiveAcceptLate
                obj.captureLiveFInputChunk();
            end
            t = obj.ForcingTimeBuffer(:);
            y = obj.ForcingBuffer(:);
        end

        function [t, y] = getLiveError(obj)
            if obj.LiveCaptureEnabled || obj.LiveAcceptLate
                obj.captureLiveNamedChunk('error', 'error', ...
                    'ErrorTimeBuffer', 'ErrorBuffer', 'LiveArmedError');
            end
            t = obj.ErrorTimeBuffer(:);
            y = AppModel.metersToMm(obj.ErrorBuffer(:));
        end

        function [t, y] = getLiveControlEffort(obj)
            if obj.LiveCaptureEnabled || obj.LiveAcceptLate
                obj.captureLiveNamedChunk('control_effort', 'control_effort', ...
                    'EffortTimeBuffer', 'EffortBuffer', 'LiveArmedEffort');
            end
            t = obj.EffortTimeBuffer(:);
            y = obj.EffortBuffer(:);
        end

        function connectTarget(obj)
            % External mode and ExtMode buffers first, then rebuild so the
            % host TARGET_DATA_MAP matches the kernel app, then connect.
            modelName = char(obj.SimulationModelName);
            if ~bdIsLoaded(modelName)
                load_system(modelName);
            end

            obj.applySimParamsToWorkspace();
            obj.applyControlParamsToWorkspace();
            obj.ensureExternalMode();
            obj.stopTargetQuietly();
            obj.prepareLiveStreaming();
            obj.rebuildTarget(modelName);
            obj.prepareLiveStreaming();

            set_param(modelName, 'SimulationCommand', 'connect');
        end

        function resetLiveLog(obj)
            % Drop the previous experiment so Start always replaces the
            % trace. A leftover 0..S series would otherwise re-arm and
            % ignore (or append past) the new run.
            if ~isempty(obj.PositionBuffer)
                obj.StaleLogFingerprint = obj.makeSdiFingerprint( ...
                    [], obj.TimeBuffer, obj.PositionBuffer);
            end
            obj.TimeBuffer = [];
            obj.PositionBuffer = [];
            obj.VelocityBuffer = [];
            obj.ForcingTimeBuffer = [];
            obj.ForcingBuffer = [];
            obj.ErrorTimeBuffer = [];
            obj.ErrorBuffer = [];
            obj.EffortTimeBuffer = [];
            obj.EffortBuffer = [];
            obj.LiveArmed = false;
            obj.LiveArmedForcing = false;
            obj.LiveArmedError = false;
            obj.LiveArmedEffort = false;
            obj.LiveAcceptLate = false;
            obj.LiveCaptureEnabled = false;
            obj.SdiFreshForThisRun = false;
            obj.initAuxLogs();
            obj.clearLoggedWorkspace();
        end

        function prepareNewRun(obj)
            obj.resetLiveLog();
            obj.snapshotStaleSdi();
        end

        function startSimulation(obj)
            obj.applySimParamsToWorkspace();
            obj.applyControlParamsToWorkspace();
            obj.resetLiveLog();
            obj.LiveCaptureEnabled = true;

            obj.ensureExternalMode();
            set_param(obj.SimulationModelName, 'SimulationCommand', 'start');
            try
                set_param(char(obj.SimulationModelName), ...
                    'ExtModeCommand', 'armWired');
            catch
            end
        end

        function stopSimulation(obj)
            % Same teardown as Ctrl+C in the Command Window: halt the
            % kernel task, then drop the external-mode connection.
            obj.stopTargetQuietly();
            obj.disconnectTargetQuietly();
        end

        function haltKernel(obj)
            % Stop the current run but keep the external-mode connection
            % so the last ExtMode / SDI packets can still land.
            obj.stopTargetQuietly();
        end

        function pumpLiveBuffers(obj)
            % Pull the latest ExtMode / SDI packets into the stitched
            % buffers. Must run at least as often as ExtMode Duration or
            % workspace-only dumps drop every other packet.
            if ~obj.LiveCaptureEnabled && ~obj.LiveAcceptLate
                return;
            end
            obj.captureLiveCart1Chunk();
            obj.captureLiveFInputChunk();
            obj.captureLiveNamedChunk('error', 'error', ...
                'ErrorTimeBuffer', 'ErrorBuffer', 'LiveArmedError');
            obj.captureLiveNamedChunk('control_effort', 'control_effort', ...
                'EffortTimeBuffer', 'EffortBuffer', 'LiveArmedEffort');
            obj.captureAuxLogs();
        end

        function dt = livePollPeriod(obj)
            % ExtMode uploads LiveBufferSamples at a time (0.05 s at T=0.001).
            % Poll faster than that so the host sees consecutive packets.
            bufferSec = obj.LiveBufferSamples * obj.T;
            dt = min(0.04, max(0.015, 0.4 * bufferSec));
        end

        function finalizeLoggedSignals(obj)
            % Wait out the last upload packets, then prefer the longest
            % stitched / SDI record over the Duration-sized workspace dump.
            obj.LiveAcceptLate = true;
            obj.waitForRemainingPackets();
            obj.adoptAllRicherLogs();
            obj.promoteLoggedSignalsToWorkspace();
            obj.LiveAcceptLate = false;
            obj.LiveCaptureEnabled = false;
        end

        function run = collectRunData(obj)
            obj.finalizeLoggedSignals();

            names = [ ...
                "rt_time", "f_input", "error", "control_effort", ...
                "cart1_position", "cart2_position", ...
                "cart1_velocity", "cart2_velocity", ...
                "motor_current", "motor_velocity", ...
                "sim_input", "k_sim", "b_sim", ...
                "Kp", "Ki", "Kd", "K_switch", ...
                "T", "r", "Kt", "motor_eff"];

            run = struct();
            run.saved_at = datetime("now");

            for i = 1:numel(names)
                name = char(names(i));
                if evalin('base', ['exist(''' name ''', ''var'')'])
                    run.(name) = evalin('base', name);
                end
            end
        end

        function status = getSimulationStatus(obj)
            if bdIsLoaded(obj.SimulationModelName)
                status = get_param(obj.SimulationModelName, 'SimulationStatus');
            else
                status = 'stopped';
            end
        end

        function isRunning = isSimulationRunning(obj)
            status = obj.getSimulationStatus();
            isRunning = strcmp(status, 'running') || strcmp(status, 'external');
        end
    end

    methods (Access = private)
        function ensureExternalMode(obj)
            modelName = char(obj.SimulationModelName);
            if ~bdIsLoaded(modelName)
                load_system(modelName);
            end
            if ~strcmp(get_param(modelName, 'SimulationMode'), 'external')
                set_param(modelName, 'SimulationMode', 'external');
            end
        end

        function stopTargetQuietly(obj)
            modelName = char(obj.SimulationModelName);
            if ~bdIsLoaded(modelName)
                return;
            end
            try
                if ~strcmp(get_param(modelName, 'SimulationStatus'), 'stopped')
                    set_param(modelName, 'SimulationCommand', 'stop');
                end
            catch
            end
        end

        function disconnectTargetQuietly(obj)
            modelName = char(obj.SimulationModelName);
            if ~bdIsLoaded(modelName)
                return;
            end
            try
                set_param(modelName, 'SimulationCommand', 'disconnect');
            catch
            end
        end

        function rebuildTarget(~, modelName)
            try
                slbuild(modelName);
            catch
                rtwbuild(modelName);
            end
        end

        function waitForRemainingPackets(obj)
            % A gappy stitch can still end at StopTime. Wait until SDI or
            % a merge is gap-free (~S/T samples), not merely t(end)≈S.
            t0 = tic;
            while toc(t0) < 8
                obj.pumpLiveBuffers();
                obj.adoptAllRicherLogs();
                if obj.logLooksComplete()
                    return;
                end
                pause(0.02);
                drawnow;
            end
        end

        function n = expectedSampleCount(obj)
            n = max(2, round(obj.S / obj.T));
        end

        function tf = hasTimeGaps(obj, t)
            tf = false;
            if numel(t) < 2
                return;
            end
            tf = any(diff(t(:)) > 1.5 * obj.T);
        end

        function tf = isCompleteSeries(obj, t, y)
            tf = false;
            n = min(numel(t), numel(y));
            if n < 2
                return;
            end
            t = t(1:n);
            if t(1) > max(2 * obj.T, 0.05)
                return;
            end
            if t(end) < obj.S - 2 * obj.T
                return;
            end
            if n < obj.expectedSampleCount() - 2
                return;
            end
            if obj.hasTimeGaps(t)
                return;
            end
            tf = true;
        end

        function tf = logLooksComplete(obj)
            tf = obj.isCompleteSeries(obj.TimeBuffer, obj.PositionBuffer);
        end

        function adoptAllRicherLogs(obj)
            obj.adoptRicherLog('TimeBuffer', 'PositionBuffer', 'LiveArmed', ...
                'cart1_position', 'Cart1-Position');
            obj.adoptRicherLog('ForcingTimeBuffer', 'ForcingBuffer', 'LiveArmedForcing', ...
                'f_input', 'f_input');
            obj.adoptRicherLog('ErrorTimeBuffer', 'ErrorBuffer', 'LiveArmedError', ...
                'error', 'error');
            obj.adoptRicherLog('EffortTimeBuffer', 'EffortBuffer', 'LiveArmedEffort', ...
                'control_effort', 'control_effort');
            obj.adoptAuxRicherLogs();
        end

        function adoptRicherLog(obj, tField, yField, armedField, wsName, sdiName)
            candidates = {};
            if ~isempty(obj.(yField))
                candidates{end+1} = {obj.(tField)(:), obj.(yField)(:)}; %#ok<AGROW>
            end
            [t, y] = obj.readWorkspaceNamed(wsName);
            if ~isempty(y)
                candidates{end+1} = {t(:), y(:)}; %#ok<AGROW>
            end
            [t, y] = obj.readSdiNamed(sdiName);
            if ~isempty(y)
                candidates{end+1} = {t(:), y(:)}; %#ok<AGROW>
            end
            [bestT, bestY] = obj.pickOrMergeSeries(candidates);
            if ~isempty(bestY)
                obj.(tField) = bestT(:)';
                obj.(yField) = bestY(:)';
                obj.(armedField) = true;
            end
        end

        function [bestT, bestY] = pickOrMergeSeries(obj, candidates)
            bestT = [];
            bestY = [];
            valid = {};
            completeT = [];
            completeY = [];
            completeN = -1;
            for i = 1:numel(candidates)
                ti = candidates{i}{1};
                yi = candidates{i}{2};
                n = min(numel(ti), numel(yi));
                if n < 2
                    continue;
                end
                ti = ti(1:n);
                yi = yi(1:n);
                if ~obj.looksLikeThisRun(ti, yi)
                    continue;
                end
                valid{end+1} = {ti(:), yi(:)}; %#ok<AGROW>
                if obj.isCompleteSeries(ti, yi) && n > completeN
                    completeN = n;
                    completeT = ti;
                    completeY = yi;
                end
            end
            if ~isempty(completeY)
                bestT = completeT;
                bestY = completeY;
                return;
            end
            for i = 1:numel(valid)
                [bestT, bestY] = obj.mergeByTime(bestT, bestY, ...
                    valid{i}{1}, valid{i}{2});
            end
        end

        function [t, y] = mergeByTime(obj, t1, y1, t2, y2)
            if isempty(y2)
                t = t1(:);
                y = y1(:);
                return;
            end
            if isempty(y1)
                t = t2(:);
                y = y2(:);
                return;
            end
            n1 = min(numel(t1), numel(y1));
            n2 = min(numel(t2), numel(y2));
            tAll = [t1(1:n1); t2(1:n2)];
            yAll = [y1(1:n1); y2(1:n2)];
            [tAll, order] = sort(tAll);
            yAll = yAll(order);
            keep = [true; diff(tAll) > (obj.T / 2)];
            t = tAll(keep);
            y = yAll(keep);
        end

        function promoteLoggedSignalsToWorkspace(obj)
            % Labs plot(rt_time, cart1_position) and plot(rt_time, f_input).
            % Same clock, same length, plant origin at t≈0.
            obj.harmonizeStitchedLogs();
            if ~isempty(obj.TimeBuffer)
                assignin('base', 'rt_time', obj.TimeBuffer(:));
            end
            if ~isempty(obj.PositionBuffer)
                assignin('base', 'cart1_position', obj.PositionBuffer(:));
            end
            if ~isempty(obj.ForcingBuffer)
                assignin('base', 'f_input', obj.ForcingBuffer(:));
            end
            if ~isempty(obj.ErrorBuffer)
                assignin('base', 'error', obj.ErrorBuffer(:));
            end
            if ~isempty(obj.EffortBuffer)
                assignin('base', 'control_effort', obj.EffortBuffer(:));
            end
            obj.promoteAuxLogs();
        end

        function harmonizeStitchedLogs(obj)
            n = min(numel(obj.TimeBuffer), numel(obj.PositionBuffer));
            if n < 2
                return;
            end
            t = obj.TimeBuffer(1:n);
            y = obj.PositionBuffer(1:n);
            [t, y] = obj.monotonicPlantClock(t, y);
            obj.TimeBuffer = t(:)';
            obj.PositionBuffer = y(:)';
            if ~isempty(obj.ForcingBuffer) && ~isempty(obj.ForcingTimeBuffer)
                obj.ForcingBuffer = obj.resampleOntoClock( ...
                    obj.ForcingTimeBuffer, obj.ForcingBuffer, t);
                obj.ForcingTimeBuffer = t(:)';
            end
            if ~isempty(obj.ErrorBuffer) && ~isempty(obj.ErrorTimeBuffer)
                obj.ErrorBuffer = obj.resampleOntoClock( ...
                    obj.ErrorTimeBuffer, obj.ErrorBuffer, t);
                obj.ErrorTimeBuffer = t(:)';
            end
            if ~isempty(obj.EffortBuffer) && ~isempty(obj.EffortTimeBuffer)
                obj.EffortBuffer = obj.resampleOntoClock( ...
                    obj.EffortTimeBuffer, obj.EffortBuffer, t);
                obj.EffortTimeBuffer = t(:)';
            end
        end

        function yOut = resampleOntoClock(obj, tIn, yIn, tClock)
            yOut = yIn;
            if isempty(yIn) || isempty(tIn) || numel(tClock) < 2
                return;
            end
            n = min(numel(tIn), numel(yIn));
            tIn = tIn(1:n);
            yIn = yIn(1:n);
            if numel(yIn) == numel(tClock) && max(abs(tIn(:) - tClock(:))) <= obj.T
                yOut = yIn(:)';
                return;
            end
            if obj.hasTimeGaps(tIn)
                yOut = yIn(:)';
                return;
            end
            try
                yOut = interp1(tIn(:), yIn(:), tClock(:), 'linear', 'extrap')';
            catch
                yOut = yIn(:)';
            end
        end

        function [t, y] = monotonicPlantClock(obj, t, y)
            t = t(:);
            y = y(:);
            n = min(numel(t), numel(y));
            t = t(1:n);
            y = y(1:n);
            [t, order] = sort(t);
            y = y(order);
            keep = [true; diff(t) > (obj.T / 2)];
            t = t(keep);
            y = y(keep);
        end

        function promoteAuxLogs(obj)
            tClock = obj.TimeBuffer(:);
            names = obj.auxLogNames();
            for i = 1:numel(names)
                wsName = names{i};
                log = obj.AuxLogs.(wsName);
                y = [];
                if ~isempty(log.y) && ~isempty(log.t) ...
                        && (log.t(end) - log.t(1)) >= 0.8 * obj.S
                    y = obj.resampleOntoClock(log.t, log.y, tClock);
                end
                if numel(y) ~= numel(tClock)
                    [tWs, yWs] = obj.readWorkspaceNamed(wsName);
                    if numel(yWs) == numel(tClock)
                        y = yWs(:);
                    elseif ~isempty(tWs) && ~isempty(yWs) ...
                            && (tWs(end) - tWs(1)) >= 0.8 * obj.S
                        y = obj.resampleOntoClock(tWs, yWs, tClock);
                    end
                end
                if numel(y) ~= numel(tClock)
                    [tSdi, ySdi] = obj.readSdiNamed(obj.auxSdiName(wsName));
                    if numel(ySdi) == numel(tClock)
                        y = ySdi(:);
                    elseif ~isempty(tSdi) && ~isempty(ySdi) ...
                            && (tSdi(end) - tSdi(1)) >= 0.8 * obj.S
                        y = obj.resampleOntoClock(tSdi, ySdi, tClock);
                    end
                end
                if numel(y) == numel(tClock) && ~isempty(y)
                    assignin('base', wsName, y(:));
                end
            end
        end

        function initAuxLogs(obj)
            names = obj.auxLogNames();
            logs = struct();
            for i = 1:numel(names)
                logs.(names{i}) = struct('t', [], 'y', [], 'armed', false);
            end
            obj.AuxLogs = logs;
        end

        function names = auxLogNames(~)
            names = { ...
                'cart2_position', 'cart1_velocity', 'cart2_velocity', ...
                'motor_current', 'motor_velocity'};
        end

        function sdiName = auxSdiName(~, wsName)
            switch wsName
                case 'cart2_position'
                    sdiName = 'Cart2-Position';
                case 'cart1_velocity'
                    sdiName = 'Cart1-Velocity';
                case 'cart2_velocity'
                    sdiName = 'Cart2-Velocity';
                otherwise
                    sdiName = wsName;
            end
        end

        function captureAuxLogs(obj)
            names = obj.auxLogNames();
            for i = 1:numel(names)
                wsName = names{i};
                log = obj.AuxLogs.(wsName);
                [t, y] = obj.readWorkspaceNamed(wsName);
                [log.t, log.y, log.armed] = obj.appendLiveSamples( ...
                    log.t, log.y, log.armed, t, y);
                if obj.LiveAcceptLate
                    [t, y] = obj.readSdiNamed(obj.auxSdiName(wsName));
                    [log.t, log.y, log.armed] = obj.appendLiveSamples( ...
                        log.t, log.y, log.armed, t, y);
                end
                obj.AuxLogs.(wsName) = log;
            end
        end

        function adoptAuxRicherLogs(obj)
            names = obj.auxLogNames();
            for i = 1:numel(names)
                wsName = names{i};
                log = obj.AuxLogs.(wsName);
                log = obj.adoptRicherLogInto(log, wsName, obj.auxSdiName(wsName));
                obj.AuxLogs.(wsName) = log;
            end
        end

        function log = adoptRicherLogInto(obj, log, wsName, sdiName)
            candidates = {};
            if ~isempty(log.y)
                candidates{end+1} = {log.t(:), log.y(:)}; %#ok<AGROW>
            end
            [t, y] = obj.readWorkspaceNamed(wsName);
            if ~isempty(y)
                candidates{end+1} = {t(:), y(:)}; %#ok<AGROW>
            end
            [t, y] = obj.readSdiNamed(sdiName);
            if ~isempty(y)
                candidates{end+1} = {t(:), y(:)}; %#ok<AGROW>
            end
            [bestT, bestY] = obj.pickOrMergeSeries(candidates);
            if ~isempty(bestY)
                log.t = bestT(:)';
                log.y = bestY(:)';
                log.armed = true;
            end
        end

        function captureLiveCart1Chunk(obj)
            [t, y] = obj.readWorkspaceCart1();
            obj.appendLiveChunk(t, y);
            if obj.LiveAcceptLate
                [t, y] = obj.readSdiNamed('Cart1-Position');
                obj.appendLiveChunk(t, y);
            end
        end

        function captureLiveFInputChunk(obj)
            [t, y] = obj.readWorkspaceNamed('f_input');
            obj.appendLiveForcingChunk(t, y);
            if obj.LiveAcceptLate
                [t, y] = obj.readSdiNamed('f_input');
                obj.appendLiveForcingChunk(t, y);
            end
        end

        function captureLiveNamedChunk(obj, wsName, sdiName, tField, yField, armedField)
            [t, y] = obj.readWorkspaceNamed(wsName);
            [obj.(tField), obj.(yField), obj.(armedField)] = ...
                obj.appendLiveSamples(obj.(tField), obj.(yField), ...
                obj.(armedField), t, y);
            if obj.LiveAcceptLate
                [t, y] = obj.readSdiNamed(sdiName);
                [obj.(tField), obj.(yField), obj.(armedField)] = ...
                    obj.appendLiveSamples(obj.(tField), obj.(yField), ...
                    obj.(armedField), t, y);
            end
        end

        function [t, y] = readWorkspaceNamed(obj, varName)
            t = [];
            y = [];
            try
                if ~evalin('base', ['exist(''' varName ''', ''var'')'])
                    return;
                end
                raw = evalin('base', varName);
                [t, y] = AppModel.signalValuesToXY(raw);
                t = obj.toSimSeconds(t);
                if strcmp(varName, 'rt_time')
                    if ~isempty(y)
                        t = obj.toSimSeconds(y);
                    end
                    y = t;
                    return;
                end
                tClock = obj.readWorkspaceClock();
                if numel(tClock) == numel(y) && numel(y) >= 2
                    t = tClock;
                end
            catch
            end
        end

        function tClock = readWorkspaceClock(obj)
            tClock = [];
            try
                if ~evalin('base', "exist('rt_time', 'var')")
                    return;
                end
                raw = evalin('base', 'rt_time');
                [t, y] = AppModel.signalValuesToXY(raw);
                if ~isempty(y)
                    tClock = obj.toSimSeconds(y);
                else
                    tClock = obj.toSimSeconds(t);
                end
            catch
            end
        end

        function names = workspaceLogNames(~)
            names = { ...
                'rt_time', 'f_input', 'error', 'control_effort', ...
                'cart1_position', 'cart2_position', ...
                'cart1_velocity', 'cart2_velocity', ...
                'motor_current', 'motor_velocity'};
        end

        function clearLoggedWorkspace(obj)
            names = obj.workspaceLogNames();
            for i = 1:numel(names)
                try
                    assignin('base', names{i}, []);
                catch
                end
                try
                    evalin('base', ['clear ' names{i}]);
                catch
                end
            end
        end

        function [t, y] = readWorkspaceCart1(obj)
            [t, y] = obj.readWorkspaceNamed('cart1_position');
        end

        function id = currentSdiRunId(obj)
            id = [];
            try
                runObj = obj.currentSdiRun();
                if ~isempty(runObj)
                    id = runObj.id;
                end
            catch
            end
        end

        function id = currentSdiRunIdUnfiltered(obj)
            id = [];
            try
                runObj = obj.currentSdiRunUnfiltered();
                if ~isempty(runObj)
                    id = runObj.id;
                end
            catch
            end
        end

        function ids = allSdiRunIds(~)
            ids = [];
            try
                ids = Simulink.sdi.getAllRunIDs();
            catch
            end
        end

        function tf = isStaleSdiId(obj, id)
            tf = false;
            if isempty(id)
                return;
            end
            if ~isempty(obj.StaleSdiRunId) && isequal(id, obj.StaleSdiRunId)
                tf = true;
                return;
            end
            if ~isempty(obj.StaleSdiRunIds)
                tf = ismember(id, obj.StaleSdiRunIds);
            end
        end

        function snapshotStaleSdi(obj)
            obj.StaleSdiRunId = obj.currentSdiRunIdUnfiltered();
            obj.StaleSdiRunIds = obj.allSdiRunIds();
            [t, y, runObj] = obj.fetchSdiNamedUnfiltered('Cart1-Position');
            obj.StaleSdiFingerprint = obj.makeSdiFingerprint(runObj, t, y);
        end

        function [t, y] = readSdiNamed(obj, nameFragment)
            t = [];
            y = [];
            [tRaw, yRaw, runObj] = obj.fetchSdiNamed(nameFragment);
            if isempty(yRaw)
                return;
            end
            if obj.sdiRecordIsStale(runObj, tRaw, yRaw)
                return;
            end
            obj.SdiFreshForThisRun = true;
            t = tRaw;
            y = yRaw;
        end

        function [t, y, runObj] = fetchSdiNamedUnfiltered(obj, nameFragment)
            t = [];
            y = [];
            runObj = [];
            try
                runObj = obj.currentSdiRunUnfiltered();
                if isempty(runObj)
                    return;
                end
                [t, y] = obj.sdiSignalXY(runObj, nameFragment);
            catch
            end
        end

        function [t, y, runObj] = fetchSdiNamed(obj, nameFragment)
            t = [];
            y = [];
            runObj = [];
            try
                runObj = obj.currentSdiRun();
                if isempty(runObj)
                    return;
                end
                [t, y] = obj.sdiSignalXY(runObj, nameFragment);
                if obj.isClockName(nameFragment)
                    if ~isempty(y)
                        t = obj.toSimSeconds(y);
                        y = t;
                    end
                    return;
                end
                tClock = obj.sdiClockFromRun(runObj);
                if numel(tClock) == numel(y) && numel(y) >= 2
                    t = tClock;
                end
            catch
            end
        end

        function [t, y] = sdiSignalXY(obj, runObj, nameFragment)
            t = [];
            y = [];
            sigs = runObj.getAllSignals();
            hit = [];
            for i = 1:numel(sigs)
                name = char(sigs(i).Name);
                if strcmpi(name, nameFragment)
                    hit = i;
                    break;
                end
                if isempty(hit) && contains(name, nameFragment, 'IgnoreCase', true)
                    hit = i;
                end
            end
            if isempty(hit)
                return;
            end
            [t, y] = AppModel.signalValuesToXY(sigs(hit).Values);
            t = obj.toSimSeconds(t);
        end

        function tClock = sdiClockFromRun(obj, runObj)
            tClock = [];
            clockNames = {'rt_time', 'Clock', 'tout'};
            for i = 1:numel(clockNames)
                [t, y] = obj.sdiSignalXY(runObj, clockNames{i});
                if ~isempty(y)
                    tClock = obj.toSimSeconds(y);
                elseif ~isempty(t)
                    tClock = t;
                end
                if numel(tClock) >= 2
                    return;
                end
            end
        end

        function tf = isClockName(~, nameFragment)
            tf = any(strcmpi(char(nameFragment), {'rt_time', 'Clock', 'tout', 'time'}));
        end

        function t = toSimSeconds(obj, t)
            if isempty(t)
                return;
            end
            if isduration(t)
                t = seconds(t);
            elseif isdatetime(t)
                t = seconds(t - t(1));
            end
            t = double(t(:));
            % Wall-clock / epoch seconds, not simulation time.
            if t(1) > max(100, 10 * obj.S)
                t = t - t(1);
            end
        end

        function tf = sdiRecordIsStale(obj, runObj, t, y)
            tf = true;
            if isempty(y)
                return;
            end
            if obj.matchesStaleLog(t, y)
                return;
            end
            reused = isempty(runObj) || obj.isStaleSdiId(runObj.id);
            if reused
                % Same SDI run id as before Start, but this recording can
                % still be a complete replacement for the current StopTime.
                tf = ~obj.isCompleteSeries(t, y);
                return;
            end
            tf = false;
        end

        function fp = makeSdiFingerprint(~, runObj, t, y)
            fp = struct('n', 0, 'tEnd', NaN, 'yEnd', NaN, 'id', []);
            if ~isempty(runObj)
                fp.id = runObj.id;
            end
            if isempty(y)
                return;
            end
            fp.n = numel(y);
            fp.yEnd = y(end);
            if ~isempty(t)
                fp.tEnd = t(end);
            end
        end

        function runObj = currentSdiRun(obj)
            runObj = obj.currentSdiRunUnfiltered();
        end

        function runObj = currentSdiRunUnfiltered(obj)
            runObj = [];
            try
                runObj = Simulink.sdi.getCurrentSimulationRun( ...
                    char(obj.SimulationModelName));
            catch
            end
            if ~isempty(runObj)
                return;
            end
            try
                runIDs = obj.allSdiRunIds();
                if isempty(runIDs)
                    return;
                end
                runObj = Simulink.sdi.getRun(runIDs(end));
            catch
            end
        end

        function appendLiveChunk(obj, t, y)
            [obj.TimeBuffer, obj.PositionBuffer, obj.LiveArmed] = ...
                obj.appendLiveSamples(obj.TimeBuffer, obj.PositionBuffer, ...
                obj.LiveArmed, t, y);
        end

        function appendLiveForcingChunk(obj, t, y)
            [obj.ForcingTimeBuffer, obj.ForcingBuffer, obj.LiveArmedForcing] = ...
                obj.appendLiveSamples(obj.ForcingTimeBuffer, obj.ForcingBuffer, ...
                obj.LiveArmedForcing, t, y);
        end

        function [timeBuf, yBuf, armed] = appendLiveSamples(obj, timeBuf, yBuf, armed, t, y)
            if isempty(t) || isempty(y)
                return;
            end
            t = t(:)';
            y = y(:)';
            n = min(numel(t), numel(y));
            t = t(1:n);
            y = y(1:n);
            if obj.matchesStaleLog(t, y) || ~obj.looksLikeThisRun(t, y)
                return;
            end

            % First packet of this run must be a short ExtMode dump near t=0.
            % A leftover full series also starts at t=0; accepting it freezes
            % the plot (new t <= old t(end)) or appends only past the old S.
            if ~armed
                maxStart = max(1.0, 4 * obj.LiveBufferSamples * obj.T);
                maxFirstEnd = max(2.0, 8 * obj.LiveBufferSamples * obj.T);
                if obj.LiveAcceptLate
                    if t(1) <= maxStart || numel(t) <= 2 * obj.LiveBufferSamples
                        armed = true;
                        timeBuf = t;
                        yBuf = y;
                    end
                elseif t(1) <= maxStart && t(end) <= maxFirstEnd
                    armed = true;
                    timeBuf = t;
                    yBuf = y;
                end
                return;
            end

            covers = t(1) <= timeBuf(1) + obj.T ...
                && t(end) >= timeBuf(end) - obj.T;
            if (covers && numel(t) > numel(timeBuf)) ...
                    || obj.isCompleteSeries(t, y)
                timeBuf = t;
                yBuf = y;
                return;
            end

            [timeBuf, yBuf] = obj.mergeByTime(timeBuf(:), yBuf(:), t(:), y(:));
            timeBuf = timeBuf(:)';
            yBuf = yBuf(:)';
        end

        function tf = looksLikeThisRun(obj, t, y)
            tf = false;
            if isempty(t) || isempty(y)
                return;
            end
            n = min(numel(t), numel(y));
            t = t(1:n);
            y = y(1:n);
            if n < 2
                return;
            end
            if obj.matchesStaleLog(t, y)
                return;
            end
            if t(end) > obj.S + 1.0
                return;
            end
            tf = true;
        end

        function tf = matchesStaleLog(obj, t, y)
            tf = false;
            fp = obj.StaleLogFingerprint;
            if isempty(fp) || fp.n <= 0 || isempty(y)
                return;
            end
            tf = numel(y) == fp.n ...
                && isequaln(y(end), fp.yEnd) ...
                && (isempty(t) || isequaln(t(end), fp.tEnd));
        end
    end

    methods (Static, Access = private)
        function yMm = metersToMm(y)
            if isempty(y)
                yMm = y;
                return;
            end
            yMm = y * 1000;
        end

        function [t, y] = signalValuesToXY(vals)
            t = [];
            y = [];
            if isa(vals, 'timeseries')
                t = vals.Time(:);
                y = squeeze(vals.Data);
                y = y(:);
                if isduration(t)
                    t = seconds(t);
                    t = t(:);
                elseif isdatetime(t)
                    t = seconds(t - t(1));
                    t = t(:);
                end
            elseif istimetable(vals)
                t = seconds(vals.Time);
                t = t(:);
                y = vals{:, 1};
                y = y(:);
            elseif isstruct(vals) && isfield(vals, 'time') && isfield(vals, 'signals')
                t = vals.time(:);
                y = squeeze(vals.signals(1).values);
                y = y(:);
            elseif isnumeric(vals)
                y = squeeze(vals);
                y = y(:);
            end
            if ~isempty(t) && ~isempty(y)
                n = min(numel(t), numel(y));
                t = t(1:n);
                y = y(1:n);
            end
        end
    end
end
