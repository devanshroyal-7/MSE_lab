classdef AppModel < handle
    % Application model: loads MSE_PLANT and feeds forcing / sim parameters
    % into the MATLAB base workspace so Desktop Real-Time can read them.
    %
    % Live Time-tab display is uitimescope bound to EMB Cart1-Position [m]
    % (port 3). After Stop, getKernelLoggedResponse() waits for a complete
    % SDI / logsout / SLDRT archive record (~t_span/T samples). ExtMode
    % To Workspace leftovers (tens of samples) are ignored, not plotted.
    % This plant is Simulink Desktop Real-Time (sldrt.tlc), not Speedgoat
    % slrealtime — there is no slrealtime.fileLogImport.
    %
    % Plant log contract:
    %   Block  MSE_PLANT/EMB - Spring-Mass-Damper System 2DOF - DAQ2(NI PCIe-6321)1
    %   Port 3 Cart1-Position [m]  (already instrumented in the .slx)
    %   Clock  MSE_PLANT/Clock1 → To Workspace rt_time
    %   To Workspace names: rt_time, cart1_position [m], … (ExtMode-duration dumps only)
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
    end

    properties (Access = private)
        StaleSdiRunIds = []
        AuxLogs = struct()
        KernelLogsLoaded (1,1) logical = false
        TimeScopeBinding
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

        function prepareExternalMode(obj)
            % External-mode flags needed to connect/start. Do not shrink
            % ExtMode Duration for live uiaxes stitching — live view is
            % uitimescope, post-run data is the kernel File Log / SDI.
            modelName = char(obj.SimulationModelName);
            if ~bdIsLoaded(modelName)
                load_system(modelName);
            end
            set_param(modelName, 'ExtModeArmWhenConnect', 'on');
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

        function [t, y] = getKernelLoggedResponse(obj)
            % Full post-run cart-1 trace for TimePanel uiaxes.
            % t [s], y [mm]. Only a complete kernel record (SDI / logsout /
            % SLDRT archive with ~t_span/T samples). Not ExtMode leftovers.
            obj.ensureKernelLogsLoaded();
            t = obj.TimeBuffer(:);
            y = AppModel.metersToMm(obj.PositionBuffer(:));
        end

        function [t, y] = getLoggedResponse(obj)
            [t, y] = obj.getKernelLoggedResponse();
        end

        function [t, y] = getKernelLoggedError(obj)
            obj.ensureKernelLogsLoaded();
            t = obj.ErrorTimeBuffer(:);
            y = AppModel.metersToMm(obj.ErrorBuffer(:));
        end

        function [t, y] = getKernelLoggedControlEffort(obj)
            obj.ensureKernelLogsLoaded();
            t = obj.EffortTimeBuffer(:);
            y = obj.EffortBuffer(:);
        end

        function connectTarget(obj)
            % External mode first, then rebuild so the host TARGET_DATA_MAP
            % matches the kernel app, then connect.
            modelName = char(obj.SimulationModelName);
            if ~bdIsLoaded(modelName)
                load_system(modelName);
            end

            obj.applySimParamsToWorkspace();
            obj.applyControlParamsToWorkspace();
            obj.ensureExternalMode();
            obj.stopTargetQuietly();
            obj.prepareExternalMode();
            obj.rebuildTarget(modelName);
            obj.prepareExternalMode();

            set_param(modelName, 'SimulationCommand', 'connect');
        end

        function connectLiveTimeScope(obj, scope)
            % Bind uitimescope to EMB Cart1-Position [m] (output port 3).
            %
            % One-time .slx: keep the log badge on that port (already in
            % MSE_PLANT) and Signal logging ON. SLDRT has no File Log block;
            % live data is SDI streaming of the instrumented signal.
            % The bound signal is meters — live scope ylabel is meters.
            %
            %   bind(simulation('MSE_PLANT').LoggedSignals, ...
            %       'MSE_PLANT/<EMB block>:3', scope)
            if nargin < 2 || isempty(scope)
                return;
            end
            try
                if ~isvalid(scope)
                    return;
                end
            catch
                return;
            end

            obj.releaseTimeScopeBinding();
            modelName = char(obj.SimulationModelName);
            [blk, port] = obj.cart1PositionBlock();
            sigPath = sprintf('%s:%d', blk, port);

            try
                Simulink.sdi.markSignalForStreaming(blk, port, 'on');
            catch
            end
            try
                set_param(modelName, 'SignalLogging', 'on');
            catch
            end

            try
                obj.Simulation = simulation(modelName);
            catch ME
                warning('AppModel:NoSimulationObject', ...
                    ['Could not create simulation(''%s'') for uitimescope bind: %s'], ...
                    modelName, ME.message);
                return;
            end

            bound = false;
            try
                obj.TimeScopeBinding = bind(obj.Simulation.LoggedSignals, sigPath, scope);
                bound = true;
            catch
            end
            if ~bound
                try
                    obj.TimeScopeBinding = bind(obj.Simulation.LoggedSignals, ...
                        sigPath, scope, '');
                    bound = true;
                catch ME
                    warning('AppModel:TimeScopeBindFailed', ...
                        ['Could not bind uitimescope to %s. Enable Signal ', ...
                         'logging on EMB port %d (Cart1-Position [m]). %s'], ...
                        sigPath, port, ME.message);
                end
            end
        end

        function resetLoggedSignals(obj)
            obj.TimeBuffer = [];
            obj.PositionBuffer = [];
            obj.VelocityBuffer = [];
            obj.ForcingTimeBuffer = [];
            obj.ForcingBuffer = [];
            obj.ErrorTimeBuffer = [];
            obj.ErrorBuffer = [];
            obj.EffortTimeBuffer = [];
            obj.EffortBuffer = [];
            obj.KernelLogsLoaded = false;
            obj.initAuxLogs();
            obj.clearLoggedWorkspace();
        end

        function prepareNewRun(obj)
            obj.resetLoggedSignals();
            obj.snapshotStaleSdi();
        end

        function startSimulation(obj)
            obj.applySimParamsToWorkspace();
            obj.applyControlParamsToWorkspace();
            obj.resetLoggedSignals();

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
            % so File Log / SDI can finish writing the kernel record.
            obj.stopTargetQuietly();
        end

        function loadKernelLoggedSignals(obj)
            % Wait for a complete kernel record after StopTime.
            % SLDRT (sldrt.tlc) has no slrealtime.fileLogImport. Sources:
            % instrumented SDI (Cart1-Position), logsout, optional ExtMode
            % data-archiving MAT files. To Workspace dumps of tens of
            % samples are ExtMode leftovers and are not plotted.
            t0 = tic;
            t = [];
            y = [];
            while toc(t0) < 8
                obj.tryImportSldrtArchive();
                [t, y] = obj.readKernelNamed('cart1_position', 'Cart1-Position');
                if obj.isCompleteSeries(t, y)
                    break;
                end
                pause(0.25);
                drawnow;
            end

            if ~obj.isCompleteSeries(t, y)
                obj.TimeBuffer = [];
                obj.PositionBuffer = [];
                obj.ForcingTimeBuffer = [];
                obj.ForcingBuffer = [];
                obj.ErrorTimeBuffer = [];
                obj.ErrorBuffer = [];
                obj.EffortTimeBuffer = [];
                obj.EffortBuffer = [];
                obj.initAuxLogs();
                obj.KernelLogsLoaded = true;
                return;
            end

            obj.TimeBuffer = t(:)';
            obj.PositionBuffer = y(:)';

            [tF, yF] = obj.readKernelNamed('f_input', 'f_input');
            obj.ForcingTimeBuffer = tF(:)';
            obj.ForcingBuffer = yF(:)';

            [tE, yE] = obj.readKernelNamed('error', 'error');
            obj.ErrorTimeBuffer = tE(:)';
            obj.ErrorBuffer = yE(:)';

            [tU, yU] = obj.readKernelNamed('control_effort', 'control_effort');
            obj.EffortTimeBuffer = tU(:)';
            obj.EffortBuffer = yU(:)';

            obj.loadAuxLogs();
            obj.promoteLoggedSignalsToWorkspace();
            obj.KernelLogsLoaded = true;
        end

        function run = collectRunData(obj)
            obj.loadKernelLoggedSignals();

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

        function releaseTimeScopeBinding(obj)
            b = obj.TimeScopeBinding;
            obj.TimeScopeBinding = [];
            if isempty(b)
                return;
            end
            try
                delete(b);
            catch
            end
        end

        function [blk, port] = cart1PositionBlock(obj)
            % EMB subsystem output 3 is Cart1-Position [m].
            port = 3;
            modelName = char(obj.SimulationModelName);
            fallback = [modelName ...
                '/EMB - Spring-Mass-Damper System 2DOF - DAQ2(NI PCIe-6321)1'];
            blk = fallback;
            try
                hits = find_system(modelName, 'SearchDepth', 1, ...
                    'Regexp', 'on', 'Name', '^EMB');
                if isempty(hits)
                    return;
                end
                if iscell(hits)
                    hits = hits{1};
                end
                blk = char(hits);
            catch
            end
        end

        function ensureKernelLogsLoaded(obj)
            if ~obj.KernelLogsLoaded
                obj.loadKernelLoggedSignals();
            end
        end

        function tryImportSldrtArchive(obj)
            % Speedgoat File Log is slrealtime.fileLogImport — not used here.
            % SLDRT Run-in-Kernel can archive ExtMode buffers to MAT files
            % when Data Archiving is enabled in the External Mode Control Panel.
            modelName = char(obj.SimulationModelName);
            try
                if ~bdIsLoaded(modelName)
                    return;
                end
                if ~strcmp(get_param(modelName, 'ExtModeEnableArchive'), 'on')
                    return;
                end
                dirName = get_param(modelName, 'ExtModeArchiveDirName');
                filePrefix = get_param(modelName, 'ExtModeArchiveFileName');
                if isempty(dirName)
                    dirName = pwd;
                end
                files = dir(fullfile(dirName, [filePrefix '*.mat']));
                if isempty(files)
                    return;
                end
                [~, newest] = max([files.datenum]);
                data = load(fullfile(files(newest).folder, files(newest).name));
                names = fieldnames(data);
                for i = 1:numel(names)
                    assignin('base', names{i}, data.(names{i}));
                end
            catch
            end
        end

        function [t, y] = readKernelNamed(obj, wsName, sdiName)
            candidates = {};
            [t, y] = obj.readLogsoutNamed(wsName);
            if ~isempty(y)
                candidates{end+1} = {t(:), y(:)};
            end
            [t, y] = obj.readWorkspaceNamed(wsName);
            if ~isempty(y)
                candidates{end+1} = {t(:), y(:)};
            end
            [t, y] = obj.readSdiNamed(sdiName);
            if ~isempty(y)
                candidates{end+1} = {t(:), y(:)};
            end
            if ~strcmp(wsName, sdiName)
                [t, y] = obj.readSdiNamed(wsName);
                if ~isempty(y)
                    candidates{end+1} = {t(:), y(:)};
                end
            end
            [t, y] = obj.pickBestSeries(candidates);
        end

        function [bestT, bestY] = pickBestSeries(obj, candidates)
            % Choose one complete kernel record. Never fall back to a
            % short ExtMode To Workspace dump (e.g. 23 samples).
            bestT = [];
            bestY = [];
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
                if obj.isCompleteSeries(ti, yi) && n > completeN
                    completeN = n;
                    bestT = ti;
                    bestY = yi;
                end
            end
        end

        function tf = isCompleteSeries(obj, t, y)
            % True when the series is dense at sample time T from t≈0.
            % Rejects last ExtMode To Workspace buffers (tens of samples).
            % Allows an early Stop whose span is shorter than commanded S.
            tf = false;
            n = min(numel(t), numel(y));
            if n < 2
                return;
            end
            t = t(1:n);
            if t(1) > max(2 * obj.T, 0.05)
                return;
            end
            span = t(end) - t(1);
            if span < max(0.2, 20 * obj.T)
                return;
            end
            expectedForSpan = max(2, round(span / obj.T));
            if n < expectedForSpan - max(2, 0.1 * expectedForSpan)
                return;
            end
            tf = true;
        end

        function promoteLoggedSignalsToWorkspace(obj)
            % Labs plot(rt_time, cart1_position) and plot(rt_time, f_input).
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

        function promoteAuxLogs(obj)
            names = obj.auxLogNames();
            for i = 1:numel(names)
                wsName = names{i};
                log = obj.AuxLogs.(wsName);
                if ~isempty(log.y)
                    assignin('base', wsName, log.y(:));
                end
            end
        end

        function loadAuxLogs(obj)
            names = obj.auxLogNames();
            for i = 1:numel(names)
                wsName = names{i};
                [t, y] = obj.readKernelNamed(wsName, obj.auxSdiName(wsName));
                obj.AuxLogs.(wsName) = struct('t', t(:)', 'y', y(:)');
            end
        end

        function initAuxLogs(obj)
            names = obj.auxLogNames();
            logs = struct();
            for i = 1:numel(names)
                logs.(names{i}) = struct('t', [], 'y', []);
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

        function [t, y] = readLogsoutNamed(obj, varName)
            t = [];
            y = [];
            try
                if ~evalin('base', "exist('logsout', 'var')")
                    return;
                end
                ds = evalin('base', 'logsout');
                [t, y] = obj.datasetSignalXY(ds, varName);
            catch
            end
        end

        function [t, y] = datasetSignalXY(obj, ds, nameFragment)
            t = [];
            y = [];
            if isempty(ds)
                return;
            end
            n = ds.numElements;
            hit = [];
            for i = 1:n
                try
                    el = ds.getElement(i);
                catch
                    el = ds{i};
                end
                name = char(el.Name);
                if strcmpi(name, nameFragment)
                    hit = el;
                    break;
                end
                if isempty(hit) && contains(name, nameFragment, 'IgnoreCase', true)
                    hit = el;
                end
            end
            if isempty(hit)
                return;
            end
            [t, y] = AppModel.signalValuesToXY(hit.Values);
            t = obj.toSimSeconds(t);
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
                    evalin('base', ['clear ' names{i}]);
                catch
                end
            end
            try
                evalin('base', 'clear logsout');
            catch
            end
        end

        function snapshotStaleSdi(obj)
            obj.StaleSdiRunIds = obj.allSdiRunIds();
        end

        function [t, y] = readSdiNamed(obj, nameFragment)
            t = [];
            y = [];
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

        function ids = allSdiRunIds(~)
            ids = [];
            try
                ids = Simulink.sdi.getAllRunIDs();
            catch
            end
        end

        function runObj = currentSdiRun(obj)
            runObj = [];
            try
                runObj = Simulink.sdi.getCurrentSimulationRun( ...
                    char(obj.SimulationModelName));
            catch
            end
            try
                runIDs = obj.allSdiRunIds();
                if isempty(runIDs)
                    return;
                end
                newer = runIDs;
                if ~isempty(obj.StaleSdiRunIds)
                    newer = setdiff(runIDs, obj.StaleSdiRunIds, 'stable');
                end
                if ~isempty(newer)
                    runObj = Simulink.sdi.getRun(newer(end));
                elseif isempty(runObj)
                    runObj = Simulink.sdi.getRun(runIDs(end));
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
