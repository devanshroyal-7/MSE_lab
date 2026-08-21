classdef (Abstract) BaseSignal < handle
    % Abstract forcing signal. Concrete subclasses implement evaluate(t).
    % Offset / DelayBefore / DelayAfter / Repeat are shared fields; only Offset
    % is applied in evaluate() today. Delay and Repeat are reserved for sequencing.
    %
    %{
    Example usage (any subclass):

    >> sig = SineSignal(1, 2, 0, 5);  % amplitude, Hz, phase deg, duration
    >> t = 0:0.001:sig.TotalDuration;
    >> y = sig.evaluate(t);
    >> plot(t, y);

    %}

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

    methods
        function f = excitationFrequencyHz(~)
            % Highest commanded frequency [Hz], or NaN when the waveform
            % has no well-defined excitation band (step, ramp, custom, …).
            f = NaN;
        end
    end
end