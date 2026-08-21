classdef SweptSineSignal < BaseSignal
    % Linear chirp from StartFrequency to EndFrequency over Duration (modal tests).
    % Uses MATLAB chirp(); Offset is added on the active window.
    %
    %{
    Example usage:

    >> sig = SweptSineSignal(1.6, 1, 20, 15);  % A [N], f0 [Hz], f1 [Hz], duration [s]
    >> t = 0:0.001:sig.TotalDuration;
    >> plot(t, sig.evaluate(t));

    %}

    properties
        Name = "Swept Sine"
        Amplitude       % [N]
        StartFrequency  % [Hz]
        EndFrequency    % [Hz]
        Duration        % [s]
    end

    properties (Dependent)
        TotalDuration
    end

    methods
        function obj = SweptSineSignal (amplitude, start_freq, end_freq, duration)
            % default values
            if nargin < 1, amplitude    = 1.0; end
            if nargin < 2, start_freq   = 1.0; end
            if nargin < 3, end_freq     = 0.0; end
            if nargin < 4, duration     = 10.0; end

            % assignment
            obj.Amplitude = amplitude;
            obj.StartFrequency = start_freq;
            obj.EndFrequency = end_freq;
            obj.Duration = duration;
            
        end

        function td = get.TotalDuration(obj)
            td = obj.Duration;
        end

        function f = excitationFrequencyHz(obj)
            f = max(obj.StartFrequency, obj.EndFrequency);
            if ~(isfinite(f) && f > 0)
                f = NaN;
            end
        end

        function y = evaluate(obj, t)
            y = zeros(size(t));

            activeMask = (t >= 0) & (t <= obj.Duration);
            t_active = t(activeMask);
            if ~isempty(t_active)
                y(activeMask) = obj.Amplitude * chirp(t_active, obj.StartFrequency, obj.Duration, obj.EndFrequency) + obj.Offset;
            end
        end
    end
end