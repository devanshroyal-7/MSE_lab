classdef NoiseSignal < BaseSignal
    % Band-limited Gaussian noise. White noise is FFT-filtered with a brick-wall
    % passband [LowerFrequency, UpperFrequency], then scaled to Amplitude RMS.
    % Seed makes the realization repeatable.
    %
    %{
    Example usage:

    >> sig = NoiseSignal(1, 1, 10, 10, 42);  % A, f_lo, f_hi, duration, seed
    >> t = 0:0.001:sig.TotalDuration;
    >> plot(t, sig.evaluate(t));

    %}

    properties
        Name = "Noise"
        Duration = 1.0          % [s]
        Amplitude = 1.0         % [N]
        LowerFrequency = 1.0    % [Hz]
        UpperFrequency = 10.0   % [Hz]
        Seed = 42   % Controlled state variable modified by GenerateButton
    end

    properties (Dependent)
        TotalDuration
    end

    methods
        function obj = NoiseSignal (amplitude, lower_freq, upper_freq, duration, seed)
            % default values
            if nargin < 1, amplitude    = 1.0;  end
            if nargin < 2, lower_freq   = 1.0;  end
            if nargin < 3, upper_freq     = 0.0;  end
            if nargin < 4, duration     = 10.0; end
            if nargin < 5, seed         = 42;   end

            % assignment
            obj.Amplitude = amplitude;
            obj.LowerFrequency = lower_freq;
            obj.UpperFrequency = upper_freq;
            obj.Duration = duration;
            obj.Seed = seed;
        end

        function td = get.TotalDuration(obj)
            td = obj.Duration;
        end

        function y = evaluate(obj, t)
            y = zeros(size(t));

            activeMask = (t >= 0) & (t <= obj.Duration);
            t_active = t(activeMask);

            if isempty(t_active) || length(t_active) < 4    % FFT conjugate symmetry needs >= 4 samples
                return;
            end

            dt = mean(diff(t_active));
            fs = 1/dt;
            numPoints = length(t_active);
            
            stream = RandStream('mt19937ar', 'Seed', obj.Seed);
            rawNoise = randn(stream, size(t_active));

            % FFT-based Frequency Domain Brick-Wall Filter
            noiseFFT = fft(rawNoise);
            freqs = (0:numPoints-1) * (fs/numPoints);       % frequency resolution

            if mod(numPoints, 2) == 0
                halfPts = numPoints / 2;
            else
                halfPts = (numPoints - 1) / 2;
            end
            posFreqs = freqs(1:halfPts+1);                  % positive freqs only

            passbandMaskPos = (posFreqs >= obj.LowerFrequency) & (posFreqs <= obj.UpperFrequency);

            fullMask = zeros(1, numPoints);
            fullMask(1:length(passbandMaskPos)) = passbandMaskPos;
            if mod(numPoints, 2) == 0
                fullMask(length(passbandMaskPos)+1:end) = flip(passbandMaskPos(2:end-1));
            else
                fullMask(length(passbandMaskPos)+1:end) = flip(passbandMaskPos(2:end));
            end

            filteredNoise = ifft(noiseFFT .* fullMask);

            if std(filteredNoise) > 0
                y(activeMask) = (filteredNoise / std(filteredNoise)) * obj.Amplitude;
            end

            if obj.Offset ~= 0
                y(activeMask) = y(activeMask) + obj.Offset;
            end
        end
    end
end