classdef AppController < handle
    % Glue between AppModel and AppView. Start Simulation compiles/connects
    % Desktop Real-Time; Create Forcing Function opens SignalBuilderApp and
    % draws the result on the reference plot. Save Output is still a stub.
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

            try
                d = uiprogressdlg(figHandle, ...
                    "Title", "Simulink Desktop-Real Time", ...
                    "Message", "Compiling C code & connecting to real-time target...", ...
                    "Indeterminate", "on");
                drawnow;

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
            % obj
        end
    end
end