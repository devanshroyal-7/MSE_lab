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
            H = X ./ F;
            scale = max(abs(F));
            tiny = abs(F) < max(1e-12, 1e-9 * scale);
            H(tiny) = NaN;

            result.n = specF.n;
            result.fs = specF.fs;
            result.freq = specF.freq;
            result.complex = H;
            result.mag = abs(H);
            result.phase = FrfAnalyzer.wrapPhaseDeg(rad2deg(angle(H)));
            result.coherence = FrfAnalyzer.welchCoherence(t, u, y, result.freq);
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
            t = zeros(0, 1);
            u = zeros(0, 1);
            y = zeros(0, 1);
            if nargin < 4 || isempty(f) || isempty(x)
                return;
            end

            f = f(:);
            x = x(:);
            if isempty(tF)
                tF = (0:numel(f)-1)';
            else
                tF = tF(:);
            end
            if isempty(tX)
                tX = (0:numel(x)-1)';
            else
                tX = tX(:);
            end

            nF = min(numel(tF), numel(f));
            nX = min(numel(tX), numel(x));
            tF = tF(1:nF);
            f = f(1:nF);
            tX = tX(1:nX);
            x = x(1:nX);

            maskF = isfinite(tF) & isfinite(f);
            maskX = isfinite(tX) & isfinite(x);
            tF = tF(maskF);
            f = f(maskF);
            tX = tX(maskX);
            x = x(maskX);
            if numel(tF) < 4 || numel(tX) < 4
                return;
            end

            tStart = max(tF(1), tX(1));
            tEnd = min(tF(end), tX(end));
            if ~(tEnd > tStart)
                return;
            end

            dt = min(mean(diff(tF)), mean(diff(tX)));
            if ~(dt > 0)
                return;
            end

            t = (tStart:dt:tEnd)';
            if rem(numel(t), 2) ~= 0
                t = t(1:end-1);
            end
            if numel(t) < 4
                t = zeros(0, 1);
                return;
            end

            u = interp1(tF, f, t, 'linear');
            y = interp1(tX, x, t, 'linear');
            finiteMask = isfinite(u) & isfinite(y);
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
