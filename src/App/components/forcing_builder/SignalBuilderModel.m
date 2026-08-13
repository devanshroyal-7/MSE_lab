classdef SignalBuilderModel < handle
    % Model for signal builder. Maintains the signals added by the user and
    % creates a superposition composite when required. 
    
    %{
    Example usage:

    >> model = SignalBuilderModel;
    >> model.addSignal(StepSignal(2, 5, 5));
    >> [t, y] = model.compileCompositeSignal;
    >> plot(t, y);

    % To view the signals currently added:
    >> model.Signals

    %}

    events
        DataUpdated
    end

    properties
        Signals = {}
        SampleRate = 1000
    end

    properties (Constant)
        ForceLimit = 3  % [N]
    end
    
    properties (Dependent)
        TotalDuration
    end

    methods
        function addSignal(obj, newSignal)
            if ~isa(newSignal, 'BaseSignal')
                error('SignalBuilderModel:InvalidType', ...
                    'Only classes inheriting from BaseSignal can be added');
            end
            
            obj.Signals{end+1} = newSignal;

            notify(obj, 'DataUpdated');
        end

        function removeSignal(obj, index)
            if ~isempty(index) && isscalar(index) && index > 0 && index <= length(obj.Signals)
                obj.Signals(index) = [];

                notify(obj, 'DataUpdated');
            end
        end

        function clearAll(obj)
            obj.Signals = {};

            notify(obj, 'DataUpdated');
        end

        function td = get.TotalDuration(obj)
            if isempty(obj.Signals)
                td = 0.0;
                return
            end

            td = 0;
            for i = 1:length(obj.Signals)
                if obj.Signals{i}.TotalDuration > td
                    td = obj.Signals{i}.TotalDuration;
                end
            end
        end

        function [t, y] = compileCompositeSignal(obj)
            dt = 1/obj.SampleRate;
            t = 0:dt:obj.TotalDuration;

            y = zeros(size(t));
            for i1 = 1:length(obj.Signals)
                y = y + obj.Signals{i1}.evaluate(t);
            end
        end

        function [t, y] = evaluateIndividualSignal(obj, idx)
            dt = 1/obj.SampleRate;
            t = 0:dt:obj.Signals{idx}.TotalDuration;
            y = obj.Signals{idx}.evaluate(t);
        end

        function [t, y] = evaluateSignal(obj, SigObject)
            % this method is for signals that are not part of the model
            % e.g. temp signals for the available select
            dt = 1/obj.SampleRate;
            
            if isempty(SigObject)
                t = [];
                y = [];
                return;
            end

            t = 0:dt:SigObject.TotalDuration;
            y = SigObject.evaluate(t);
        end

        function tf = exceedsForceLimit(obj, y)
            tf = ~isempty(y) && any(abs(y) > obj.ForceLimit);
        end

        function resetModel(obj)
            obj.Signals = {};
        end
    end
end