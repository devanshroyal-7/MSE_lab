classdef StepSignal < BaseSignal
    % Subclass for Step Signal

    properties
        Name = "Zero Output"
        Duration    % [s]
        SampleRate  % [Hz]
        Magnitude   % [N]
        OffTime = 1 % [s]
        OnTime  = 1 % [s]
    end

    methods
        function obj = StepSignal (magnitude, on_time, off_time, smp_rate)
            % default values
            if nargin < 1, magnitude = 1.0; end
            if nargin < 2, on_time  = 1.0; end
            if nargin < 3, off_time = 1.0; end
            if nargin < 4, smp_rate = 1000; end

            % assignment
            obj.Magnitude = magnitude;
            obj.OnTime = on_time;
            obj.OffTime = off_time;
            obj.SampleRate = smp_rate;
            obj.Duration = obj.OnTime + obj.OffTime;
        end

        function y = evaluate(obj, t)
            y = zeros(size(t)); 

            stepCondition = (t >= obj.OffTime);
            y(stepCondition) = obj.Magnitude;
            
            % offset (must verify if it was done globally)
            if obj.Offset ~= 0
                y = y + obj.Offset;
            end
        end
    end
end