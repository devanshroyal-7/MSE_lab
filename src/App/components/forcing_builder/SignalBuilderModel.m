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

    properties
        Signals = {}
        SampleRate = 1000
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
        end

        function removeSignal(obj, index)
            if index > 0 && index <= length(obj.Signals)
                obj.Signals(index) = [];
            end
        end

        function clearAll(obj)
            obj.Signals = {};
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
            for i = 1:length(obj.Signals)
                y = y + obj.Signals{i}.evaluate(t);
            end
        end
    end
end