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
        StaleSdiRunId = []
        StaleSdiFingerprint = struct('n', 0, 'tEnd', NaN, 'yEnd', NaN)
        SdiFreshForThisRun (1,1) logical = false
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

        function [t, y] = getLiveCart1Position(obj)
            obj.captureLiveCart1Chunk();
            t = obj.TimeBuffer(:);
            y = AppModel.metersToMm(obj.PositionBuffer(:));
        end

        function [t, y] = getLiveFInput(obj)
            obj.captureLiveFInputChunk();
            t = obj.ForcingTimeBuffer(:);
            y = obj.ForcingBuffer(:);
        end

        function [t, y] = getLiveError(obj)
            obj.captureLiveNamedChunk('error', 'error', ...
                'ErrorTimeBuffer', 'ErrorBuffer', 'LiveArmedError');
            t = obj.ErrorTimeBuffer(:);
            y = AppModel.metersToMm(obj.ErrorBuffer(:));
        end

        function [t, y] = getLiveControlEffort(obj)
            obj.captureLiveNamedChunk('control_effort', 'control_effort', ...
                'EffortTimeBuffer', 'EffortBuffer', 'LiveArmedEffort');
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

        function startSimulation(obj)
            obj.applySimParamsToWorkspace();
            obj.applyControlParamsToWorkspace();
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
            obj.SdiFreshForThisRun = false;
            obj.snapshotStaleSdi();

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
            obj.captureLiveCart1Chunk();
            obj.captureLiveFInputChunk();
            obj.captureLiveNamedChunk('error', 'error', ...
                'ErrorTimeBuffer', 'ErrorBuffer', 'LiveArmedError');
            obj.captureLiveNamedChunk('control_effort', 'control_effort', ...
                'EffortTimeBuffer', 'EffortBuffer', 'LiveArmedEffort');
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
        end

        function run = collectRunData(obj)
            obj.finalizeLoggedSignals();

            names = [ ...
                "rt_time", "f_input", "error", "control_effort", ...
                "cart1_position", "cart2_position", ...
                "cart1_velocity", "cart2_velocity", ...
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
            % Do not treat t(end)≈S as complete: a gappy stitch of every
            % other ExtMode packet still ends near StopTime. Wait until the
            % sample count is ~S/T or SDI replaces the buffer with a full
            % record.
            t0 = tic;
            while toc(t0) < 5
                obj.pumpLiveBuffers();
                obj.adoptAllRicherLogs();
                if obj.logLooksComplete()
                    return;
                end
                pause(obj.livePollPeriod());
                drawnow;
            end
        end

        function n = expectedSampleCount(obj)
            n = max(2, round(obj.S / obj.T));
        end

        function tf = logLooksComplete(obj)
            tf = false;
            if isempty(obj.TimeBuffer)
                return;
            end
            nOk = numel(obj.TimeBuffer) >= 0.90 * obj.expectedSampleCount();
            tOk = obj.TimeBuffer(end) >= 0.90 * obj.S;
            tf = nOk && tOk;
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

            bestT = [];
            bestY = [];
            bestScore = -1;
            for i = 1:numel(candidates)
                ti = candidates{i}{1};
                yi = candidates{i}{2};
                n = min(numel(ti), numel(yi));
                if n < 2
                    continue;
                end
                ti = ti(1:n);
                yi = yi(1:n);
                tSpan = ti(end) - ti(1);
                score = n + 1e6 * max(tSpan, 0);
                if ti(1) <= max(0.5, 0.1 * obj.S)
                    score = score + 1e9;
                end
                if n >= 0.90 * obj.expectedSampleCount()
                    score = score + 1e8;
                end
                if score > bestScore
                    bestScore = score;
                    bestT = ti;
                    bestY = yi;
                end
            end
            if ~isempty(bestY)
                obj.(tField) = bestT(:)';
                obj.(yField) = bestY(:)';
                obj.(armedField) = true;
            end
        end

        function promoteLoggedSignalsToWorkspace(obj)
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
            obj.promoteNamed('cart2_position', 'Cart2-Position');
            obj.promoteNamed('cart1_velocity', 'Cart1-Velocity');
            obj.promoteNamed('cart2_velocity', 'Cart2-Velocity');
        end

        function promoteNamed(obj, wsName, sdiName)
            [~, yWs] = obj.readWorkspaceNamed(wsName);
            [~, ySdi] = obj.readSdiNamed(sdiName);
            y = yWs;
            if numel(ySdi) > numel(y)
                y = ySdi;
            end
            if isempty(y)
                return;
            end
            assignin('base', wsName, y(:));
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
                if isempty(t) && ~isempty(y) && evalin('base', "exist('rt_time', 'var')")
                    tWs = squeeze(evalin('base', 'rt_time'));
                    tWs = tWs(:);
                    if numel(tWs) == numel(y)
                        t = tWs;
                    end
                end
            catch
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

        function snapshotStaleSdi(obj)
            obj.StaleSdiRunId = obj.currentSdiRunId();
            [t, y, runObj] = obj.fetchSdiNamed('Cart1-Position');
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

        function [t, y, runObj] = fetchSdiNamed(obj, nameFragment)
            t = [];
            y = [];
            runObj = [];
            try
                runObj = obj.currentSdiRun();
                if isempty(runObj)
                    return;
                end
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
            catch
            end
        end

        function tf = sdiRecordIsStale(obj, runObj, t, y)
            tf = false;
            if obj.SdiFreshForThisRun || isempty(y)
                return;
            end
            fp = obj.StaleSdiFingerprint;
            if isempty(fp) || fp.n <= 0
                return;
            end
            if ~isempty(obj.StaleSdiRunId) && ~isempty(runObj) ...
                    && ~isequal(runObj.id, obj.StaleSdiRunId)
                return;
            end
            tf = numel(y) == fp.n ...
                && isequaln(y(end), fp.yEnd) ...
                && (isempty(t) || isequaln(t(end), fp.tEnd));
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
                runIDs = Simulink.sdi.getAllRunIDs();
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

            % Workspace/SDI still hold the previous run's last buffer, whose
            % timestamps are near the old StopTime. If we accept that as the
            % start of this run, new samples at t≈0 are dropped until they
            % catch up. Wait for a buffer that starts near t=0. After the
            % kernel has stopped, accept the leftover packet so we do not
            % discard the only data that arrived.
            if ~armed
                maxStart = max(1.0, 4 * obj.LiveBufferSamples * obj.T);
                if t(1) <= maxStart || obj.LiveAcceptLate
                    armed = true;
                    timeBuf = t;
                    yBuf = y;
                end
                return;
            end

            % SDI often holds the full record while workspace only has the
            % latest Duration packet. append-after-end cannot fill holes, so
            % replace when the incoming series is a longer covering record.
            covers = t(1) <= timeBuf(1) + obj.T ...
                && t(end) >= timeBuf(end) - obj.T;
            if covers && numel(t) > numel(timeBuf)
                timeBuf = t;
                yBuf = y;
                return;
            end

            mask = t > timeBuf(end) + (obj.T / 2);
            if any(mask)
                timeBuf = [timeBuf, t(mask)];
                yBuf = [yBuf, y(mask)];
            end
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
