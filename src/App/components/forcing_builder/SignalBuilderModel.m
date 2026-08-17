classdef SignalBuilderModel < handle
    % Model for signal builder. Maintains the signals added by the user and
    % creates a superposition composite when required. 
    
    %{
    Example usage:

    >> model = SignalBuilderModel;                  % force [N], limit 3
    >> model = SignalBuilderModel(SignalQuantity.reference);
    >> model.addSignal(StepSignal(2, 5, 5));
    >> model.RepeatCycles = 3;
    >> [t, y] = model.compileFinalSignal;
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

        Quantity            % SignalQuantity: units, limit, and UI copy
        AmplitudeLimit = 3  % [Quantity.Unit]; from Quantity.Limit

        Offset = 0          % DC offset in Quantity.Unit, applied to the composite only
        DelayBefore = 0     % [s] leading zeros before the composite
        DelayAfter = 0      % [s] trailing zeros after the composite
        RepeatCycles = 1    % copies of (delay + composite + dwell)
    end
    
    properties (Dependent)
        TotalDuration
        CycleDuration
        NumCycles
    end

    methods
        function obj = SignalBuilderModel(quantity)
            if nargin < 1 || isempty(quantity)
                quantity = SignalQuantity.force();
            end
            obj.Quantity = quantity;
            obj.AmplitudeLimit = quantity.Limit;
        end

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
            % Superposition: every signal is evaluated on the same t axis
            % starting at 0 (not concatenated). TotalDuration is the max.
            dt = 1/obj.SampleRate;
            t = 0:dt:obj.TotalDuration;

            y = zeros(size(t));
            for i1 = 1:length(obj.Signals)
                y = y + obj.Signals{i1}.evaluate(t);
            end
        end

        function n = get.NumCycles(obj)
            n = max(1, round(obj.RepeatCycles));
        end

        function td = get.CycleDuration(obj)
            td = obj.DelayBefore + obj.TotalDuration + obj.DelayAfter;
        end

        function [t, y] = compileFinalSignal(obj)
            % Offset, delay-before, dwell-after, then repeat that cycle.
            [~, y0] = obj.compileCompositeSignal();
            y0 = y0(:).' + obj.Offset;

            nBefore = max(0, round(obj.DelayBefore * obj.SampleRate));
            nAfter = max(0, round(obj.DelayAfter * obj.SampleRate));
            cycle = [zeros(1, nBefore), y0, zeros(1, nAfter)];

            if isempty(cycle)
                t = [];
                y = [];
                return;
            end

            y = repmat(cycle, 1, obj.NumCycles);
            t = (0:numel(y)-1) / obj.SampleRate;
        end

        function [t, y] = evaluateIndividualSignal(obj, idx)
            % Preview one stacked signal on its own duration (Single plot mode).
            dt = 1/obj.SampleRate;
            t = 0:dt:obj.Signals{idx}.TotalDuration;
            y = obj.Signals{idx}.evaluate(t);
        end

        function [t, y] = evaluateSignal(obj, SigObject)
            % Preview a signal that is not in obj.Signals yet (Available list).
            dt = 1/obj.SampleRate;
            
            if isempty(SigObject)
                t = [];
                y = [];
                return;
            end

            t = 0:dt:SigObject.TotalDuration;
            y = SigObject.evaluate(t);
        end

        function tf = exceedsAmplitudeLimit(obj, y)
            tf = ~isempty(y) && any(abs(y) > obj.AmplitudeLimit);
        end

        function resetModel(obj)
            obj.Signals = {};
            obj.Offset = 0;
            obj.DelayBefore = 0;
            obj.DelayAfter = 0;
            obj.RepeatCycles = 1;
        end
    end
end