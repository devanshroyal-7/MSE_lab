# Experiments

Student-run procedures from 24-452 Labs 1–5. Homework questions are omitted. Shared software actions used across labs are listed once at the end of this section.

Sample rate is 1000 Hz unless noted.

## Shared software actions

- **Configuration:** simulated stiffness `k_sim` (N/m), simulated damping `c_sim` (Ns/m), Enable, Runs to Average, Averaging noise data?
- **Reset** encoders before each run
- **Run** until IDLE
- **Save:** Time vs Frequency, with a channel picker (force, displacement 1/2, velocity, FRF magnitude/phase 1/2, input trajectory, control effort, Bode)

---

## Lab 1 — Identification of dynamic parameters (1-DOF)

### L1-E1 Quasi-static spring rates

Ramp force on Car 1 with a spring between Car 1 and the motor support. Four mass blocks on Car 1. Mirrored ramp, Repeat 1, `k_sim = c_sim = 0`, Runs to Average = 1. Save after each run.

| Test | Spring | Slope (N/s) | Duration (s) |
| --- | --- | --- | --- |
| 1 | High | 2.5 | 2 |
| 2 | High | 1.25 | 4 |
| 3 | Medium | 2 | 2.5 |
| 4 | Medium | 2 | 2 |
| 5 | Low | 2.5 | 1 |

### L1-E2 Dynamic initial-condition tests

Zero Output, Duration 10 s. After Run, displace ~20 mm and release (zero initial velocity). `k_sim = c_sim = 0`. Save after each run.

**Car 1** — spring between Car 1 and the vertical support:

| Test | Mass | Spring |
| --- | --- | --- |
| 1 | No mass | High |
| 2 | Three large | High |
| 3 | All four | High |
| 4 | No mass | Medium |
| 5 | No mass | Low |

**Car 2** — high spring between Cars 2 and 3 (Car 3 fixed):

| Test | Mass | Spring |
| --- | --- | --- |
| 1 | Three large | High |
| 2 | No mass | High |

**Car 3** — high spring between Car 3 and the right vertical block:

| Test | Mass | Spring | Dashpot |
| --- | --- | --- | --- |
| 1 | Three large | High | No |
| 2 | No mass | High | No |
| 3 | Three large | High | Yes (nub 4.5 turns) |

### L1-E3 Repeatability

Dashpot off. All four masses on Car 3. Same initial-condition procedure as L1-E2, repeated 10 times with approximately the same initial displacement. Save each trial.

---

## Lab 2 — Forced response of first- and second-order systems

When simulated stiffness/damping is enabled, live displacement/velocity plots are not shown during the run; traces appear after the test completes.

### L2-E1.1 First-order step

No spring on Car 1. Step: Magnitude 2 N, On Time 0.5 s, Off Time 0.1 s, Repeat 1. `k_sim = 0`. Start from 2 cm left. Save position and velocity.

| Test | Mass | `c_sim` (Ns/m) |
| --- | --- | --- |
| 1 | All four | 20 |
| 2 | All four | 40 |
| 3 | All four | 60 |
| 4 | One large | 40 |

### L2-E1.2 First-order impulse (half-sine)

Same physical configs as L2-E1.1. Sine used as a short impulse: Amplitude 5 N, Frequency 10 Hz, Duration 0.05 s, Delay 0.1 s, Dwell 0.45 s, Repeat 1. Start at 0 cm. Save after each run.

### L2-E2.1 Second-order system identification

Medium spring on Car 1. Zero Output, Duration 10 s, Repeat 1, `k_sim = c_sim = 0`. After Run, displace 2 cm left and release. Three mass cases: all four, one large, none.

### L2-E2.2 Second-order step

Medium spring. Step: Magnitude 4 N, On Time 4 s, Delay 1 s, Repeat 1.

| Test | Mass | `k_sim` (N/m) | `c_sim` (Ns/m) |
| --- | --- | --- | --- |
| 1 | One large | 300 | 1 |
| 2 | One large | 300 | 5 |
| 3 | All four | 300 | 5 |
| 4 | All four | 500 | 5 |
| 5 | None | 100 | 30 |
| 6 | None | 800 | 30 |
| 7 | All four | 100 | 30 |
| 8 | All four | 300 | 80 |

### L2-E2.3 Second-order impulse (half-sine)

Medium spring. Sine: Amplitude 10 N, Frequency 10 Hz, Duration 0.05 s, Delay 0.1 s, Dwell 5.85 s, Repeat 1.

| Test | Mass | `k_sim` (N/m) | `c_sim` (Ns/m) |
| --- | --- | --- | --- |
| 1 | All four | 300 | 1 |
| 2 | All four | 600 | 1 |
| 3 | One large | 100 | 1 |
| 4 | One large | 300 | 50 |
| 5 | One large | 700 | 50 |
| 6 | All four | 300 | 50 |

### L2-E2.4 Second-order harmonic

Medium spring. Sine: Amplitude 2 N, Frequency 2 Hz, Duration 10 s, Repeat 1.

| Test | Mass | `k_sim` (N/m) | `c_sim` (Ns/m) |
| --- | --- | --- | --- |
| 1 | All four | 300 | 1 |
| 2 | All four | 600 | 1 |
| 3 | One large | 100 | 1 |
| 4 | One large | 300 | 50 |

### L2-E3 Superposition / linearity

All four masses, medium spring, `k_sim = 500`, `c_sim = 10`.

Individual runs:

| Test | Type | Amplitude / Magnitude (N) | Frequency (Hz) | Duration (s) | Delay |
| --- | --- | --- | --- | --- | --- |
| 1 | Sine | 1 | 1.5 | 10 | — |
| 2 | Sine | 4 | 1.5 | 10 | — |
| 3 | Sine | 8 | 1.5 | 10 | — |
| 4 | Sine | 12 | 1.5 | 10 | — |
| 5 | Sine | 4 | 2.5 | 10 | — |
| 6 | Step | 8 | — | On 8 | Off 2 |

Then two stacked Overall forcings (Add, view Overall):

1. Step (test 6) + Sine (test 2)
2. Sine (test 2) + Sine (test 5)

---

## Lab 3 — Harmonic response / FRF

Physical default unless noted: thickest spring on Car 1, no added mass, `k_sim = 200` N/m, `c_sim = 2` Ns/m.

### L3-E1 Sine-sweep FRF

Swept Sine: 1–10 Hz, Duration 40 s, Repeat 1. Averaging noise data **off**. Save FRF Magnitude 1, FRF Phase 1, and time-domain input trajectory.

| Test | Amplitude (N) | Averages |
| --- | --- | --- |
| 1 | 0.65 | 2 |
| 2 | 1.00 | 2 |
| 3 | 1.25 | 2 |
| 4 | 1.25 | 5 |
| 5 | 1.5 | 2 |

### L3-E2 Random FRF

Noise: Lower 1 Hz, Upper 10 Hz, Duration 400 s, Repeat 1, Runs to Average = 10, Averaging noise data **on**. Click **Generate** after setting parameters. Save FRF mag/phase 1, coherence, and time-domain input.

| Test | Amplitude (N) |
| --- | --- |
| 1 | 10 |
| 2 | 15 |

### L3-E3 Effect of dynamic parameters on FRF

Swept Sine: Amplitude 1.2 N, 1–10 Hz, 40 s, Repeat 1, 2 averages, Averaging noise data off.

| Test | `k_sim` (N/m) | `c_sim` (Ns/m) | Mass |
| --- | --- | --- | --- |
| 1 | 200 | 1 | None |
| 2 | 200 | 2 | None |
| 3 | 200 | 8 | None |
| 4 | 200 | 15 | None |
| 5 | 200 | 35 | None |
| 6 | 100 | 2 | None |
| 7 | 0 | 2 | None |
| 8 | 0 | 2 | Two large |
| 9 | 0 | 2 | All four |

### L3-E4 Single-frequency sine

Sine: Amplitude 1.2 N, Duration 40 s, Repeat 1, Runs to Average = 1. Save Force and Displacement 1.

| Test | Frequency (Hz) |
| --- | --- |
| 1 | 3 |
| 2 | 5 |
| 3 | 5.7 |
| 4 | 7 |

### L3-E5 Fourier series of a triangular force

Same physical setup as L3-E1.

1. **Actual triangle:** Ramp Slope 16 N/s, Duration 0.5 s, Repeat 5, Mirrored and Two-sided checked. Run this first.
2. **Custom partial sums** (Duration 10 s, Repeat 1). Keep previous terms and add the next:

| Test | Text added to F(t) |
| --- | --- |
| 2 | `6.4846*sin(3.1416*t)` |
| 3 | `-0.7205*sin(3.1416*3*t)` |
| 4 | `0.2594*sin(3.1416*5*t)` |
| 5 | `-0.1323*sin(3.1416*7*t)` |
| 6 | `0.0801*sin(3.1416*9*t)` |

Save Force and Displacement 1 (time domain) after each run.

---

## Lab 4 — Multi-DOF (2-DOF)

Car 3 stays fixed. For FRF/mode/IC experiments: medium spring Car 1 to left support, medium spring Car 2 to Car 3, low spring between Car 1 and Car 2.

### L4-E1 System identification (1-DOF IC on each car)

Zero Output, Duration 10 s, Repeat 1, `k_sim = c_sim = 0`, 1 average. Displace ~2 cm (Car 1 right, Car 2 left) and release. Save Displacement 1 and Displacement 2.

| Test | Car | Spring | Mass |
| --- | --- | --- | --- |
| 1 | 1 | Low | No mass |
| 2 | 1 | Low | Four large |
| 3 | 1 | Medium 1 | Four large |
| 4 | 2 | Medium 2 | No mass |
| 5 | 2 | Medium 2 | Four large |

### L4-E2 Frequency response of a 2-DOF system

Swept Sine: Amplitude 1.0 N, 1–6 Hz, Duration 40 s, Repeat 1, 2 averages, Averaging noise data off, `k_sim = c_sim = 0` (Enable on). Save FRF Magnitude/Phase 1 and 2. After each run, use peak-finding cursors on FRF Magnitude (Encoder 1) to record both resonant frequencies.

| Test | Car 1 mass | Car 2 mass |
| --- | --- | --- |
| 1 | Three large + one small | Four large |
| 2 | Two large | Four large |
| 3 | Three large + one small | Two large |

### L4-E3 Observation of mode shapes

Sine: Amplitude 1.0 N, Duration 30 s, Repeat 1. Mass: three large + one small on Car 1, four large on Car 2. Save Displacement 1 and 2. For tests 2 and 4, zoom ~5 steady-state cycles and use cursors to get the Car 1 / Car 2 amplitude ratio.

| Test | Frequency (Hz) |
| --- | --- |
| 1 | 1.25 |
| 2 | First (lower) natural frequency from L4-E2 test 1 |
| 3 | Mean of the two natural frequencies |
| 4 | Second (higher) natural frequency from L4-E2 test 1 |
| 5 | 4 |

### L4-E4 Initial-condition tests (2-DOF)

Zero Output, Duration 60 s, Repeat 1. Same physical setup as L4-E3. Fine-adjust using live Encoder 1 / Encoder 2 (within 0.5 mm), release both cars together. Save Displacement 1 and 2.

| Test | Car 1 IC (mm) | Car 2 IC (mm) |
| --- | --- | --- |
| 1 | 15 | 0 |
| 2 | 0 | 15 |
| 3 | 15 | 15 × 1st-mode amplitude ratio (from L4-E3 test 2) |
| 4 | 15 | −15 × 2nd-mode amplitude ratio (from L4-E3 test 4) |
| 5 | 5 | −20 |

Positive = right, negative = left.

---

## Lab 5 — Control systems

Do not build the Controls panel in this pass. Experiments and the controls they need are listed so that work can start later.

Physical setup (unchanged for all Lab 5 tests): first cart connected to the motor through the medium spring, one small mass.

### L5-E1 System identification

Controls **disabled**. Swept Sine: Amplitude 0.7 N, 1–10 Hz, Duration 40 s, Repeat 1, `k_sim = c_sim = 0`, 1 average. Save FRF Magnitude 1 and FRF Phase 1.

### L5-E2 Open-loop proportional control

Controls **enabled**, mode **Open Loop**, Ki = Kd = 0. Reference is a Step of **3 mm** (not newtons), On Time 10 s, Off Time 1 s, Repeat 1. Plot response vs reference (mm) and control effort (N). Save Displacement 1 and Control Effort.

| Test | Kp | `k_sim` (N/m) | `c_sim` (Ns/m) | Disturbance (shake table) |
| --- | --- | --- | --- | --- |
| 1 | 1 | 0 | 8 | No |
| 2 | Tune until Encoder 1 SS is 2.9–3.1 mm | 0 | 8 | No |
| 3 | Kp from test 2 | 0 | 8 | Yes |
| 4 | Kp from test 2 | 400 | 8 | No |

### L5-E3 Closed-loop P, PI, and PID

Controls enabled, mode **Closed Loop**, `k_sim = 0`, `c_sim = 8`. Step 3 mm, Off Time 1 s. Save Displacement 1 and Control Effort.

| Test | Kp | Ki | Kd | Disturbance | On Time (s) |
| --- | --- | --- | --- | --- | --- |
| 1 | 1 | 0 | 0 | No | 10 |
| 2 | 2 | 0 | 0 | No | 10 |
| 3 | 3 | 0 | 0 | No | 10 |
| 4 | 2 | 1 | 0 | No | 10 |
| 5 | 2 | 5 | 0 | No | 10 |
| 6 | 2 | 8 | 0 | No | 10 |
| 7 | 2 | 22 | 0 | No | 2 |
| 8 | 2 | 22 | 0.01 | No | 10 |
| 9 | 2 | 22 | 0.05 | No | 10 |
| 10 | 2 | 8 | 0.1 | No | 10 |
| 11 | 2 | 8 | 0.1 | Yes | 10 |

### L5-E4 Open-loop Bode plots

Controls enabled, mode **Open Loop**, `k_sim = 0`, `c_sim = 8`, 5 averages, Averaging noise data **on**. Noise: Amplitude 5 mm, Duration 200 s, Lower 0.1 Hz, Upper 20 Hz, Repeat 1, then Generate. Nested frequency view: Bode amplitude (dB, log frequency) and Bode phase (deg). Save Bode Amplitude Ratio 1 and Bode Phase 1.

| Test | Kp | Ki | Kd |
| --- | --- | --- | --- |
| 1 | 2 | 0 | 0 |
| 2 | 2 | 8 | 0 |
| 3 | 2 | 8 | 0.05 |

### Lab 5 controls to build later

- Enable checkbox
- Mode: Open Loop vs Closed Loop
- Gains: Kp, Ki, Kd
- When controls are enabled, Signal Builder units become **mm** (reference trajectory), not force (N)
- Controls tab: displacement response (white) vs reference (red) in mm; control effort in N
- Nested Frequency Domain tab for Bode (dB, log-f, phase in degrees)
- Live Encoder 1 readout for tuning Kp in L5-E2
- Logging/saving Displacement 1 and Control Effort (time); Bode mag/phase (frequency)

Disturbance in L5-E2/E3 is a physical table shake, not a software control.

---

# Not yet implemented

What the MATLAB app still needs so the experiments above can be run. Forcing-function types for most labs already exist (Ramp with mirrored/two-sided, Step, Sine, Swept Sine, Noise math, Custom, Zero Output, superposition, Additional Panel offset/delay/dwell/repeat, ±3 N force limit). `k_sim` / `c_sim` fields and Start Simulation exist as UI. Save Outputs and Controls are stubs.

## Missing for Labs 1–4

- Encoder **Reset** and Run / IDLE status
- **Save Outputs:** `.txt` export, Time vs Frequency, channel picker (force, disp 1/2, velocity, FRF mag/phase 1/2, input trajectory)
- `k_sim` / `c_sim` **applied to the plant** when Enabled (the sidebar toggle currently only changes color)
- **Runs to Average** and **Averaging noise data?**
- Live **Encoder 1** and **Encoder 2** indicators
- Time plots for **Cart 2**, **velocity**, and post-run vs live traces (Lab 2: simulated k/c hides live plots until the run finishes)
- FRF **phase**, second-DOF FRFs, averaging, and **coherence**
- FRF **peak cursors** / resonant-frequency readout (Lab 4)
- Time **zoom and cursors** for amplitude ratio (Lab 4)
- Noise **Generate** button
- **Stop Simulation** wired
- Overlay Reference checkbox unwired

## Lab 5 (later)

A working Controls tab as inventoried above: Bode plots, control-effort logging, mm reference when control is on. The sidebar already has inert Kp / Ki / Kd fields; that is not a Controls tab.
