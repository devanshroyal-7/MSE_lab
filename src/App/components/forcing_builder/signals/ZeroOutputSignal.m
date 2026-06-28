classdef ZeroOutputSignal < BaseSignal
    % zero output signal for steady state analysis

    properties
        Name = "Zero Output"
        Duration    % [s]
        SampleRate  % [Hz]
    end

    methods
        function obj = ZeroOutput (duration, smp_rate)
            % default values
            if nargin < 1
                duration = 1.0;
            end
            if nargin < 2
                smp_rate = 1000;
            end
            
            % assignment
            obj.Duration = duration;
            obj.SampleRate = smp_rate;
        end

        function y = evaluate(obj, t)
            y = zeros(size(t)); 
            
            % offset (must verify if it was done globally)
            if obj.Offset ~= 0
                y = y + obj.Offset;
            end
        end
    end
end