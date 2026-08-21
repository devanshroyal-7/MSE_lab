classdef FftAnalyzer
    % One-sided FFT of a real time series. compute() is the on-demand entry
    % point; average() combines several of those spectra (same-length runs,
    % or interpolated onto the first frequency grid).
    %
    %{
    Example usage:

    >> spec = FftAnalyzer.compute(t, y);
    >> plot(spec.freq, spec.mag);
    >> meanSpec = FftAnalyzer.average({specA, specB});

    %}

    properties (Constant)
        DisplayFreqMax = 20   % [Hz] excitation band for linear FFT / FRF axes
    end

    methods (Static)
        function spec = compute(t, y, fs)
            spec = FftAnalyzer.emptySpectrum();
            if nargin < 2 || isempty(y)
                return;
            end
            y = y(:);

            if nargin >= 1 && ~isempty(t)
                t = t(:);
                n = min(numel(t), numel(y));
                t = t(1:n);
                y = y(1:n);
                finiteMask = isfinite(t) & isfinite(y);
                t = t(finiteMask);
                y = y(finiteMask);
                dt = diff(t);
                dt = dt(dt > 0);
                if numel(dt) < 3
                    return;
                end
                meanDt = mean(dt);
                spec.fs = 1 / meanDt;
                if std(dt) / meanDt > 1e-3
                    tU = (t(1):meanDt:t(end))';
                    y = interp1(t, y, tU, 'linear');
                    y = y(:);
                end
            else
                y = y(isfinite(y));
                if nargin >= 3 && ~isempty(fs) && fs > 0
                    spec.fs = fs;
                else
                    spec.fs = 1000;
                end
            end

            N = numel(y);
            if N < 4
                spec = FftAnalyzer.emptySpectrum();
                return;
            end

            Y = fft(y);
            halfN = floor(N / 2) + 1;
            Yhalf = Y(1:halfN);
            % One-sided amplitude spectrum: DC (and Nyquist if even N) stay
            % as-is; other bins are doubled so a sine of amplitude A peaks at A.
            if rem(N, 2) == 0
                Yhalf(2:end-1) = 2 * Yhalf(2:end-1);
            else
                Yhalf(2:end) = 2 * Yhalf(2:end);
            end
            Yhalf = Yhalf / N;

            spec.n = N;
            spec.freq = (0:halfN-1)' * (spec.fs / N);
            spec.complex = Yhalf;
            spec.mag = abs(Yhalf);
            spec.phase = FftAnalyzer.wrapPhaseDeg(rad2deg(angle(Yhalf)));
        end

        function spec = average(spectra)
            % Mean of on-demand spectra. Prefer complex average when every
            % run has the same length; otherwise interpolate onto the first
            % frequency vector.
            spec = FftAnalyzer.emptySpectrum();
            if nargin < 1 || isempty(spectra)
                return;
            end
            if iscell(spectra)
                spectra = [spectra{:}];
            end
            spectra = spectra([spectra.n] > 0);
            if isempty(spectra)
                return;
            end
            if isscalar(spectra)
                spec = spectra;
                return;
            end

            if all([spectra.n] == spectra(1).n) && all(abs([spectra.fs] - spectra(1).fs) < 1e-9)
                C = mean(cat(2, spectra.complex), 2);
                spec = spectra(1);
                spec.complex = C;
                spec.mag = abs(C);
                spec.phase = FftAnalyzer.wrapPhaseDeg(rad2deg(angle(C)));
                spec.magDb = 20 * log10(spec.mag);
                return;
            end

            spec = spectra(1);
            freq = spec.freq;
            acc = zeros(size(freq));
            for i = 1:numel(spectra)
                acc = acc + interp1(spectra(i).freq, spectra(i).complex, freq, 'linear', 0);
            end
            spec.complex = acc / numel(spectra);
            spec.mag = abs(spec.complex);
            spec.phase = FftAnalyzer.wrapPhaseDeg(rad2deg(angle(spec.complex)));
            spec.magDb = 20 * log10(spec.mag);
            spec.n = max([spectra.n]);
        end

        function spec = emptySpectrum()
            spec = struct( ...
                "freq", zeros(0, 1), ...
                "complex", zeros(0, 1), ...
                "mag", zeros(0, 1), ...
                "magDb", zeros(0, 1), ...
                "phase", zeros(0, 1), ...
                "fs", NaN, ...
                "n", 0);
        end

        function xLim = displayXLim(freqMax)
            if nargin < 1 || isempty(freqMax) || ~(isfinite(freqMax) && freqMax > 0)
                freqMax = FftAnalyzer.DisplayFreqMax;
            end
            xLim = [0, freqMax];
        end

        function H = fromInputOutput(tU, u, tY, y)
            % Transfer Y(jω)/U(jω) on a shared time base. magDb is 20 log10 |H|.
            H = FftAnalyzer.emptySpectrum();
            if nargin < 4 || isempty(tU) || isempty(u) || isempty(tY) || isempty(y)
                return;
            end
            tU = tU(:);
            u = u(:);
            tY = tY(:);
            y = y(:);
            nU = min(numel(tU), numel(u));
            nY = min(numel(tY), numel(y));
            tU = tU(1:nU);
            u = u(1:nU);
            tY = tY(1:nY);
            y = y(1:nY);

            t0 = max(tU(1), tY(1));
            t1 = min(tU(end), tY(end));
            if ~(isfinite(t0) && isfinite(t1)) || t1 - t0 <= 0
                return;
            end
            dtU = diff(tU);
            dtU = dtU(dtU > 0);
            if numel(dtU) < 3
                return;
            end
            dt = mean(dtU);
            t = (t0:dt:t1)';
            if numel(t) < 4
                return;
            end
            uI = interp1(tU, u, t, 'linear', 'extrap');
            yI = interp1(tY, y, t, 'linear', 'extrap');
            specU = FftAnalyzer.compute(t, uI);
            specY = FftAnalyzer.compute(t, yI);
            H = FftAnalyzer.transfer(specY, specU);
        end

        function H = transfer(specY, specU)
            H = FftAnalyzer.emptySpectrum();
            if nargin < 2 || isempty(specY) || isempty(specU) ...
                    || specY.n == 0 || specU.n == 0 ...
                    || isempty(specY.freq) || isempty(specU.freq)
                return;
            end
            freq = specU.freq(:);
            U = specU.complex(:);
            Y = specY.complex(:);
            if numel(Y) ~= numel(U) || numel(specY.freq) ~= numel(freq) ...
                    || any(abs(specY.freq(:) - freq) > 1e-12 * max(1, max(freq)))
                Y = interp1(specY.freq(:), specY.complex(:), freq, 'linear', 0);
            end
            magU = abs(U);
            floorVal = max(1e-20, 1e-12 * max(magU));
            H.complex = Y ./ U;
            H.complex(magU < floorVal) = NaN;
            H.freq = freq;
            H.mag = abs(H.complex);
            H.magDb = 20 * log10(H.mag);
            H.phase = FftAnalyzer.wrapPhaseDeg(rad2deg(angle(H.complex)));
            H.fs = specU.fs;
            H.n = min(specY.n, specU.n);
        end
    end

    methods (Static, Access = private)
        function phase = wrapPhaseDeg(phase)
            phase = mod(phase + 180, 360) - 180;
        end
    end
end
