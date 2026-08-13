classdef ZeroOutputSignal < BaseSignal
    % Zero force for Duration seconds (settle / steady-state). Offset, if set,
    % is applied only inside the active window.
    %
    %{
    Example usage:

    >> sig = ZeroOutputSignal(10);
    >> t = 0:0.001:sig.TotalDuration;
    >> plot(t, sig.evaluate(t));      % all zeros unless Offset ~= 0

    %}

    properties
        Name = "Zero Output"
        Duration
    end

    properties (Dependent)
        TotalDuration
    end

    methods
        function obj = ZeroOutputSignal (duration)
            % default values
            if nargin < 1
                duration = 1.0;
            end
            
            % assignment
            obj.Duration = duration;
        end

        function td = get.TotalDuration(obj)
            td = obj.Duration;
        end

        function y = evaluate(obj, t)
            y = zeros(size(t)); 
            
            activeMask = (t >= 0) & (t <= obj.TotalDuration);
            

            % offset (must verify if it was done globally)
            if obj.Offset ~= 0
                y = y + obj.Offset;
                y(~activeMask) = 0.0;
            end
        end
    end
end