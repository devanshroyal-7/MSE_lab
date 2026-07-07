classdef (Abstract) BaseSignal < handle
    % Subclass for Sine Signal

    properties (Abstract)
        Name        % string: Display name for the "Overall" function
    end

    properties
        Offset      = 0
        DelayBefore = 0
        DelayAfter  = 0
        Repeat      = 1
    end

    methods (Abstract)
        y = evaluate(obj, t)
    end
end