classdef RampSignal < BaseSignal
    % Linear ramp of Slope [N/s] over Duration. Optional dwell, two-sided
    % (up then down), and mirrored (repeat with opposite sign). Legs stack
    % in time; TotalDuration = num_legs * Duration + DwellTime.
    %
    %{
    Example usage:

    >> sig = RampSignal(0.4, 10, 1, "beginning", true, true);
    >> t = 0:0.001:sig.TotalDuration;
    >> plot(t, sig.evaluate(t));

    %}

    properties
        Name = "Ramp"
        Duration    % [s]
        Slope       % [N/s]
        DwellTime   % [s]
        DwellTimeLoc    {mustBeMember(DwellTimeLoc, ["beginning", "end"])} = "beginning"
        TwoSided    (1,1) logical = false
        Mirrored    (1,1) logical = false
    end

    properties (Dependent)
        TotalDuration
    end

    methods
        function obj = RampSignal (slope, duration, dwell_t, dwell_loc, twosided, mirrored)
            % default values
            if nargin < 1, slope        = 1.0; end
            if nargin < 2, duration     = 10.0; end
            if nargin < 3, dwell_t      = 0.0; end
            if nargin < 4, dwell_loc    = "beginning"; end
            if nargin < 5, twosided     = false; end
            if nargin < 6, mirrored     = false; end

            % assignment
            obj.Slope= slope;
            obj.Duration = duration;
            obj.DwellTime = dwell_t;
            obj.DwellTimeLoc = dwell_loc;
            obj.TwoSided = twosided;
            obj.Mirrored = mirrored;
        end

        function td = get.TotalDuration(obj)
            num_legs = 1;

            if obj.TwoSided, num_legs = num_legs*2; end
            if obj.Mirrored, num_legs = num_legs*2; end

            td = (num_legs * obj.Duration) + obj.DwellTime;
        end

        function y = evaluate(obj, t)
            y = zeros(size(t));
            L = obj.Duration;

            if obj.DwellTimeLoc == "beginning"
                t_rel = t - obj.DwellTime;
            else
                t_rel = t;
            end

            idx1 = (t_rel >= 0) & (t_rel <= L);
            y(idx1) = t_rel(idx1) * obj.Slope;

            if obj.TwoSided
                % Second leg: return to 0 over another Duration
                idx2 = (t_rel >= L) & (t_rel <= 2*L);
                y(idx2) = (2*L - t_rel(idx2)) * obj.Slope;
            end

            if obj.Mirrored
                % Repeat the preceding shape with opposite sign
                if obj.TwoSided
                    idx3 = (t_rel >= 2*L) & (t_rel < 3*L);
                    idx4 = (t_rel >= 3*L) & (t_rel < 4*L);

                    y(idx3) = (2*L - t_rel(idx3)) * obj.Slope;
                    y(idx4) = (t_rel(idx4) - 4*L) * obj.Slope;
                else
                    idx3 = (t_rel >= L) & (t_rel < 2*L);
                    
                    y(idx3) = - (t_rel(idx3) - L) * obj.Slope;
                end
            end

            if obj.Offset ~= 0
                y = y + obj.Offset;
            end
        end
    end
end