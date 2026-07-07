classdef SweptSineSignal < BaseSignal
    % Subclass for Swept Sine Signal for modal analysis

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