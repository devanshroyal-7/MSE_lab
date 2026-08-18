classdef FrfAnalyzer
    % Input/output FRF and coherence. compute() aligns two time series,
    % forms H = X/F from full-record FFTs, and estimates ordinary coherence
    % with Welch averaging so a single run is not trivially gamma^2 = 1.
    %
    %{
    Example usage:

    >> result = FrfAnalyzer.compute(tF, f, tX, x);
    >> plot(result.freq, result.mag);
    >> plot(result.freq, result.coherence);

    %}

    methods (Static)
        function result = compute(tF, f, tX, x)
            result = FrfAnalyzer.emptyResult();
            [t, u, y] = FrfAnalyzer.alignPair(tF, f, tX, x);
            if numel(t) < 4
                return;
            end

            specF = FftAnalyzer.compute(t, u);
            specX = FftAnalyzer.compute(t, y);
            if specF.n == 0 || specX.n == 0
                return;
            end

            F = specF.complex;
            X = specX.complex;
            if numel(X) ~= numel(F)
                X = interp1(specX.freq, specX.complex, specF.freq, 'linear', NaN);
            end

            H = X ./ F;
            scale = max(abs(F(isfinite(F))));
            if isempty(scale) || ~(scale > 0)
                H(:) = NaN;
            else
                % Drop bins with no input energy so mag/phase are not Inf
                % and out-of-band coherence is not plotted as noise.
                weak = ~isfinite(F) | abs(F) < 1e-3 * scale;
                H(weak | ~isfinite(H)) = NaN;
            end

            result.n = specF.n;
            result.fs = specF.fs;
            result.freq = specF.freq;
            result.complex = H;
            result.mag = abs(H);
            result.phase = FrfAnalyzer.wrapPhaseDeg(rad2deg(angle(H)));
            result.coherence = FrfAnalyzer.welchCoherence(t, u, y, result.freq);
            result.coherence(isnan(H)) = NaN;
        end

        function result = emptyResult()
            result = struct( ...
                "freq", zeros(0, 1), ...
                "complex", zeros(0, 1), ...
                "mag", zeros(0, 1), ...
                "phase", zeros(0, 1), ...
                "coherence", zeros(0, 1), ...
                "fs", NaN, ...
                "n", 0);
        end
    end

    methods (Static, Access = private)
        function [t, u, y] = alignPair(tF, f, tX, x)
            % Put both traces on the response clock (or force clock if
            % response has no time). Same idea as lab_3 min-length truncate
            % when timestamps are missing; interpolate when both exist.
            t = zeros(0, 1);
            u = zeros(0, 1);
            y = zeros(0, 1);
            if nargin < 4 || isempty(f) || isempty(x)
                return;
            end

            f = f(:);
            x = x(:);
            tF = tF(:);
            tX = tX(:);

            nF = min(max(numel(tF), 0), numel(f));
            nX = min(max(numel(tX), 0), numel(x));
            if nF > 0
                f = f(1:nF);
                tF = tF(1:nF);
            end
            if nX > 0
                x = x(1:nX);
                tX = tX(1:nX);
            end

            hasFTime = numel(tF) >= 2 && all(isfinite(tF));
            hasXTime = numel(tX) >= 2 && all(isfinite(tX));

            if hasXTime && hasFTime
                t = tX;
                y = x;
                u = interp1(tF, f, t, 'linear', NaN);
            elseif hasXTime
                t = tX;
                y = x;
                L = min(numel(f), numel(y));
                t = t(1:L);
                y = y(1:L);
                u = f(1:L);
            elseif hasFTime
                t = tF;
                u = f;
                L = min(numel(x), numel(u));
                t = t(1:L);
                u = u(1:L);
                y = x(1:L);
            else
                L = min(numel(f), numel(x));
                u = f(1:L);
                y = x(1:L);
                t = (0:L-1)' * 0.001;
            end

            finiteMask = isfinite(t) & isfinite(u) & isfinite(y);
            t = t(finiteMask);
            u = u(finiteMask);
            y = y(finiteMask);
            if rem(numel(t), 2) ~= 0
                t = t(1:end-1);
                u = u(1:end-1);
                y = y(1:end-1);
            end
        end

        function coh = welchCoherence(t, u, y, freqOut)
            coh = NaN(size(freqOut));
            N = numel(u);
            nAvg = 8;
            L = floor(2 * N / (nAvg + 1));
            while nAvg > 1 && L < 16
                nAvg = nAvg - 1;
                L = floor(2 * N / (nAvg + 1));
            end
            if rem(L, 2) ~= 0
                L = L - 1;
            end
            if L < 16 || N < L
                return;
            end

            hop = max(1, floor(L / 2));
            w = 0.5 * (1 - cos(2 * pi * (0:L-1)' / (L - 1)));

            Gxx = [];
            Gyy = [];
            Gxy = [];
            freqW = [];
            nUsed = 0;
            startIdx = 1;
            while startIdx + L - 1 <= N
                idx = startIdx:(startIdx + L - 1);
                specU = FftAnalyzer.compute(t(idx), u(idx) .* w);
                specY = FftAnalyzer.compute(t(idx), y(idx) .* w);
                startIdx = startIdx + hop;
                if specU.n == 0 || specY.n == 0
                    continue;
                end
                if isempty(Gxx)
                    freqW = specU.freq;
                    Gxx = zeros(size(specU.complex));
                    Gyy = zeros(size(specU.complex));
                    Gxy = zeros(size(specU.complex));
                end
                U = specU.complex;
                Yc = specY.complex;
                if numel(U) ~= numel(Gxx)
                    U = interp1(specU.freq, U, freqW, 'linear', 0);
                    Yc = interp1(specY.freq, Yc, freqW, 'linear', 0);
                end
                Gxx = Gxx + abs(U).^2;
                Gyy = Gyy + abs(Yc).^2;
                Gxy = Gxy + conj(U) .* Yc;
                nUsed = nUsed + 1;
            end

            if nUsed == 0 || isempty(freqW)
                return;
            end

            Gxx = Gxx / nUsed;
            Gyy = Gyy / nUsed;
            Gxy = Gxy / nUsed;
            den = Gxx .* Gyy;
            raw = abs(Gxy).^2 ./ den;
            raw(~isfinite(raw) | den <= 0) = NaN;
            raw = min(max(raw, 0), 1);
            coh = interp1(freqW, raw, freqOut, 'linear', NaN);
        end

        function phase = wrapPhaseDeg(phase)
            phase = mod(phase + 180, 360) - 180;
        end
    end
end
