classdef SignalQuantity
    % Units, amplitude limit, and UI copy for the signal builder.
    % Waveform math is unitless; this object only describes how y is labeled
    % and clamped. Force mode is commanded force [N]. Reference mode is a
    % displacement trajectory [mm] used when the controller is enabled.
    %
    %{
    Example usage:

    >> q = SignalQuantity.force;
    >> q.Unit, q.Limit                 % "N", 3
    >> q = SignalQuantity.fromMode("reference");
    >> q.Unit, q.Limit                 % "mm", 20
    >> q.amplitudeLabel                % "Amplitude (mm):"

    %}

    properties (Constant)
        ForceLimit = 4              % [N] motor / command cap
        DisplacementLimit = 20      % [mm] travel; confirm hardware
    end

    properties (SetAccess = immutable)
        Mode                    string
        Unit                    string
        RateUnit                string
        Limit                   double
        WindowTitle             string
        PlotYLabel              string
        LimitExceededMessage    string
    end

    methods (Static)
        function obj = force()
            obj = SignalQuantity("force");
        end

        function obj = reference()
            obj = SignalQuantity("reference");
        end

        function obj = fromMode(mode)
            obj = SignalQuantity(mode);
        end
    end

    methods
        function obj = SignalQuantity(mode)
            mode = string(mode);
            switch mode
                case "force"
                    obj.Mode = "force";
                    obj.Unit = "N";
                    obj.RateUnit = "N/s";
                    obj.Limit = SignalQuantity.ForceLimit;
                    obj.WindowTitle = "Forcing Function Builder";
                    obj.PlotYLabel = "Force (N)";
                    obj.LimitExceededMessage = ...
                        "Can't set the provided forcing function because it exceeds the limits.";
                case "reference"
                    obj.Mode = "reference";
                    obj.Unit = "mm";
                    obj.RateUnit = "mm/s";
                    obj.Limit = SignalQuantity.DisplacementLimit;
                    obj.WindowTitle = "Reference Trajectory Builder";
                    obj.PlotYLabel = "Displacement (mm)";
                    obj.LimitExceededMessage = ...
                        "Can't set the provided reference trajectory because it exceeds the limits.";
                otherwise
                    error('SignalQuantity:InvalidMode', ...
                        'Mode must be "force" or "reference".');
            end
        end

        function s = amplitudeLabel(obj)
            s = sprintf('Amplitude (%s):', obj.Unit);
        end

        function s = magnitudeLabel(obj)
            s = sprintf('Magnitude (%s):', obj.Unit);
        end

        function s = slopeLabel(obj)
            s = sprintf('Slope (%s):', obj.RateUnit);
        end

        function s = offsetLabel(obj)
            s = sprintf('Offset (%s)', obj.Unit);
        end

        function s = customExprLabel(obj)
            if obj.Mode == "force"
                s = 'Function F(t) in N:';
            else
                s = 'Function x(t) in mm:';
            end
        end

        function s = sidebarButtonText(obj)
            if obj.Mode == "force"
                s = "Create Forcing Function";
            else
                s = "Create Reference Trajectory";
            end
        end
    end
end
