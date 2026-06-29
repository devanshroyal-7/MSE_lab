classdef SineSignal < BaseSignal
    % Subclass for Sine Signal

    properties
        Name = "Sine"
        Duration    % [s]
        SampleRate  % [Hz]
        Amplitude   % [N]
        Frequency   % [Hz]
        InitPhase  % [Deg]
    end

    methods
        function obj = SineSignal (amplitude, freq, init_phase, duration, smp_rate)
            % default values
            if nargin < 1, amplitude    = 1.0; end
            if nargin < 2, freq         = 1.0; end
            if nargin < 3, init_phase   = 0.0; end
            if nargin < 4, duration     = 10.0; end
            if nargin < 5, smp_rate     = 1000; end

            % assignment
            obj.Amplitude = amplitude;
            obj.Frequency = freq;
            obj.InitPhase = init_phase;
            obj.Duration = duration;
            obj.SampleRate = smp_rate;
        end

        function y = evaluate(obj, t)
            y = obj.Amplitude * sin(2 * pi * obj.Frequency * t + deg2rad(obj.InitPhase));

            if obj.Offset ~= 0
                y = y + obj.Offset;
            end
        end
    end
end