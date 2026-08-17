# Signal classes

Waveform math lives in `src/App/components/forcing_builder/signals/`. The UI never computes samples itself; it constructs these objects and calls `evaluate(t)`.

## BaseSignal

Abstract handle class. Every concrete signal must define:

- `Name` — string shown in the Overall list (must match the Available list item and `swapActivePanel` case)
- `evaluate(obj, t)` — samples of the commanded quantity for each time [s] in `t`. Units come from `SignalQuantity` (N in force mode, mm in reference mode), not from the signal class.

Shared properties:

| Property | Default | Applied in `evaluate`? |
| --- | --- | --- |
| `Offset` | 0 | Yes (added on the active window) |
| `DelayBefore` | 0 | No (reserved) |
| `DelayAfter` | 0 | No (reserved) |
| `Repeat` | 1 | No (reserved) |

`TotalDuration` is a **dependent** property on each subclass (not on the base class). The model uses it to size the composite time vector.

Isolated check for any subclass:

```matlab
sig = SineSignal(1, 2, 0, 5);
t = 0:0.001:sig.TotalDuration;
plot(t, sig.evaluate(t));
```

## SineSignal

`SineSignal(amplitude, freq, init_phase, duration)`

\[
y = A \sin(2\pi f t + \phi) + \text{Offset}, \quad 0 \le t < \text{Duration}
\]

`InitPhase` is in **degrees** and converted with `deg2rad` inside `evaluate`. Defaults: amplitude 1, 1 Hz, 0°, 10 s.

## StepSignal

`StepSignal(magnitude, on_time, off_time)`

Zero until `OffTime`, then `Magnitude` until `OffTime + OnTime`. `Name` is `"Step"`.

## RampSignal

`RampSignal(slope, duration, dwell_t, dwell_loc, twosided, mirrored)`

- One leg: \( y = \text{Slope} \cdot t_{\text{rel}} \) for \( 0 < t_{\text{rel}} < \text{Duration} \).
- **TwoSided**: a second leg returns to 0 over another `Duration`.
- **Mirrored**: the preceding shape is repeated with opposite sign (one extra leg, or two if also two-sided).
- **DwellTime** / **DwellTimeLoc** (`"beginning"` or `"end"`): idle time. If location is `"beginning"`, `t_rel = t - DwellTime`.

`TotalDuration = num_legs * Duration + DwellTime` with `num_legs` in `{1, 2, 4}`.

## SweptSineSignal

`SweptSineSignal(amplitude, start_freq, end_freq, duration)`

Linear chirp via MATLAB `chirp(t, f0, Duration, f1)`, plus Offset. Used for modal / sine-sweep labs (see `lab_3.m`).

## NoiseSignal

`NoiseSignal(amplitude, lower_freq, upper_freq, duration, seed)`

1. Draw Gaussian samples with `RandStream('mt19937ar', 'Seed', seed)` so the same seed repeats.
2. FFT, keep bins in `[LowerFrequency, UpperFrequency]`, mirror the mask for a real IFFT (brick-wall band-pass).
3. Scale so `std(y) == Amplitude` on the active window.

Needs at least 4 samples (conjugate symmetry). `Seed` is what a “Generate” control would bump to draw a new realization.

## CustomSignal

`CustomSignal(expression, duration)`

`expression` is a MATLAB snippet in `t`, e.g. `"sin(2*pi*t)"`. `vectorize` rewrites `*` `/` `^` to element-wise ops, then `str2func("@(t) " + expr)` runs it. Invalid expressions warn and return zeros. `CustomPanel` tests the expression at `t = 1` and turns the lamp red on failure.

## ZeroOutputSignal

`ZeroOutputSignal(duration)`

Zeros for `Duration` seconds (settle / hold). Offset, if set, applies only inside the window; samples outside are forced back to 0.

## Superposition

`SignalBuilderModel.compileCompositeSignal` adds `evaluate(t)` for every stacked signal on **one** time vector `[0, max duration]`. Shorter signals contribute 0 after they end. They do not start when the previous one finishes.

## Units

Waveform classes are unitless. `SignalQuantity` (see [signal-builder.md](signal-builder.md)) chooses how those numbers are labeled and clamped:

| Quantity | Force mode | Reference mode (controller on) |
| --- | --- | --- |
| Amplitude / magnitude / offset | N | mm |
| Ramp slope | N/s | mm/s |
| Amplitude limit | ±3 N | ±20 mm (travel; confirm hardware) |
| Time / duration / dwell | s | s |
| Frequency | Hz | Hz |
| Phase | deg | deg |
