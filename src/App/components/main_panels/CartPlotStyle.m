classdef CartPlotStyle
    % Shared cart-1 / cart-2 line color, legend, and visibility helpers.

    methods (Static)
        function c = color(cart)
            if nargin >= 1 && cart == 2
                c = [0.10 0.45 0.75];
            else
                c = [0.85 0.15 0.15];
            end
        end

        function name = label(cart)
            name = sprintf('Cart %d', cart);
        end

        function vis = onOff(tf)
            if tf
                vis = 'on';
            else
                vis = 'off';
            end
        end

        function tf = lineHasData(h)
            tf = ~isempty(h) && isvalid(h) ...
                && ~isempty(h.XData) && ~all(isnan(h.XData));
        end

        function applyLegend(ax, line1, line2, show1, show2)
            handles = gobjects(0, 1);
            labels = {};
            if show1 && CartPlotStyle.lineHasData(line1)
                handles(end+1, 1) = line1; %#ok<AGROW>
                labels{end+1} = CartPlotStyle.label(1); %#ok<AGROW>
            end
            if show2 && CartPlotStyle.lineHasData(line2)
                handles(end+1, 1) = line2;
                labels{end+1} = CartPlotStyle.label(2);
            end
            if isempty(handles)
                legend(ax, 'off');
            else
                legend(ax, handles, labels, 'Location', 'northeast');
            end
        end
    end
end
