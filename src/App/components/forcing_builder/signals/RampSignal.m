classdef RampSignal < BaseSignal
    % Subclass for Ramp Signal

    properties
        Name = "Ramp"
        Duration    % [s]
        SampleRate  % [Hz]
        Slope       % [N/s]
        DwellTime   % [Hz]
        DwellTimeLoc    {mustBeMember(DwellTimeLoc, {"beginning", "end"})} = beginning
        TwoSided        {MustBeA(TwoSided, 'logical')} = false
        Mirrored        {MustBeA(Mirrored, 'logical')} = false
    end

    methods
        function obj = RampSignal (slope, duration, dwell_t, dwell_loc, twosided, mirrored, smp_rate)
            % default values
            if nargin < 1, slope        = 1.0; end
            if nargin < 2, duration     = 10.0; end
            if nargin < 3, dwell_t      = 0.0; end
            if nargin < 4, dwell_loc    = "beginning"; end
            if nargin < 5, twosided     = false; end
            if nargin < 6, mirrored     = false; end
            if nargin < 7, smp_rate     = 1000; end

            % assignment
            obj.Slope= slope;
            obj.Duration = duration;
            obj.DwellTime = dwell_t;
            obj.DwellTimeLoc = dwell_loc;
            obj.TwoSided = twosided;
            obj.Mirrored = mirrored;
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