classdef CustomSignal < BaseSignal
    % Subclass for Noise Signal

    properties
        Name = "Custom"
        Duration = 1.0          % [s]
        Expression string = "0*t"       % custom function text input
    end

    properties (Dependent)
        TotalDuration
    end

    methods
        function obj = CustomSignal (expression, duration)
            % default values
            if nargin < 1, expression = "0*t";  end
            if nargin < 2, duration = 1.0;      end

            % assignment
            obj.Duration = duration;
            obj.Expression = expression;
        end

        function td = get.TotalDuration(obj)
            td = obj.Duration;
        end

        function y = evaluate(obj, t)
            y = zeros(size(t));

            activeMask = (t >= 0) & (t < obj.Duration);
            t_active = t(activeMask);

            try
                safeExpr = vectorize(obj.Expression);

                mathFunc = str2func("@(t) " + safeExpr);

                y(activeMask) = mathFunc(t_active);
            catch ME
                warning("Invalid custom expression: %s", ME.message);
                y(activeMask) = zeros(size(t_active));
            end

            if obj.Offset ~= 0
                y(activeMask) = y(activeMask) + obj.Offset;
            end
        end
    end
end