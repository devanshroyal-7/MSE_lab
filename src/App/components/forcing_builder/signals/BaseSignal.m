classdef (Abstract) BaseSignal < handle
    % Base signal template for all signal that will be used in
    % SignalBuilderModel.m

    properties (Abstract)
        Name        % string: Display name for the "Overall" function
        Duration    % double: Base running time [s]
        SampleRate  % double: Frequency         [Hz]
    end

    properties
        Offset      = 0;
        DelayBefore = 0;
        DelayAfter  = 0;
        Repeat      = 0;
    end

    methods (Abstract)
        y = evaluate(obj, t)
    end
end