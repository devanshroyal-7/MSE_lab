classdef SineSignal < BaseSignal
    % Subclass for Sine Signal

    properties
        Name = "Sine"
        Duration    % [s]
        Amplitude   % [N]
        Frequency   % [Hz]
        InitPhase  % [Deg]
    end

    properties (Dependent)
        TotalDuration
    end

    methods
        function obj = SineSignal (amplitude, freq, init_phase, duration)
            % default values
            if nargin < 1, amplitude    = 1.0; end
            if nargin < 2, freq         = 1.0; end
            if nargin < 3, init_phase   = 0.0; end
            if nargin < 4, duration     = 10.0; end

            % assignment
            obj.Amplitude = amplitude;
            obj.Frequency = freq;
            obj.InitPhase = init_phase;
            obj.Duration = duration;
        end

        function td = get.TotalDuration(obj)
            td = obj.Duration;
        end

        function y = evaluate(obj, t)
            y = zeros(size(t));

            idx = (t >= 0) & (t <= obj.Duration);

            y(idx) = obj.Amplitude * sin(2 * pi * obj.Frequency * t(idx) + deg2rad(obj.InitPhase));

            if obj.Offset ~= 0
                y = y + obj.Offset;
            end
        end
    end
end