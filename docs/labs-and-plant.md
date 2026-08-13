# Labs and plant

Course experiments and the Simulink model that talks to the EMB SMD hardware.

## Files in `src/`

| File | Role |
| --- | --- |
| `MSE_PLANT.slx` | Desktop Real-Time plant. Run in **external** mode with the kit connected. |
| `MSE_App.mlapp` | App Designer shell for the student app. Programmatic UI is under `src/App/`. |
| `Lab_1.mlx` | Live script for Lab 1 (open this in MATLAB, not the `.m` export). |
| `lab_1.m` | Export of Lab 1 with embedded figure output. Very large; prefer the `.mlx`. |
| `lab_3.m` | Lab 3 harmonic / sine-sweep experiments (same plant contract). |
| `EMB-SMDS-2DOF.png` | Photo of the two-cart SMD kit. |

Build artifacts are gitignored: `slprj/`, `MSE_PLANT_sldrt_win64/`, `MSE_PLANT.slxc`, `*.rxw64`, `*.bak`.

## Hardware parameters (all labs)

Set in the script (and duplicated as protected constants on `AppModel`):

| Name | Typical value | Meaning |
| --- | --- | --- |
| `T` | 0.001 s | Sample time |
| `r` | 0.01 m | Pinion gear radius |
| `Kt` | 0.028 N·m/A | EMB-AM2 torque constant |
| `motor_eff` | 1.0 | Efficiency; labs do `Kt = Kt * motor_eff` before the run |
| `k_sim`, `b_sim` | 0 | Extra simulated stiffness / damping |

## Running a lab against the plant

Pattern used in `lab_1.m` / `lab_3.m`:

```matlab
% 1. Build force vs time (ramp, chirp, …)
sim_input = timeseries(y', t');

% 2. External mode
model_name = 'MSE_PLANT';
load_system(model_name);
set_param(model_name, 'SimulationMode', 'external');
set_param(model_name, 'StopTime', num2str(S));
set_param(model_name, 'SimulationCommand', 'start');

% 3. After the run, plot logged signals (names from the plant):
%    rt_time, f_input, cart1_position, cart2_position,
%    cart1_velocity, cart2_velocity
```

`SignalBuilderApp` replaces step 1: it writes the same `sim_input` timeseries. `AppModel.startSimulation` is the same `set_param` sequence as step 2.

## Lab 1

Quasi-static spring-rate tests. The script builds a multi-leg **ramp** (two-sided and mirrored segments plus a delay), which is the same geometry `RampSignal` encodes. Logged plots include input force and cart position/velocity.

Use `Lab_1.mlx` to change the experiment. `lab_1.m` is a generated dump (`%[text]`, `%[output:…]` markers and inlined images). Do not hand-edit the `.m` unless you intend to throw away the live-script output.

## Lab 3

Harmonic response of the second-order rectilinear system. Experiment 1 is a **sine sweep**: `chirp(t, f0, t1, f1)` with `f0 = 1` Hz, `f1 = 20` Hz, amplitude 1.6 N, duration 15 s — the same parameters `SweptSineSignal` defaults toward.

Later cells plot force, both carts’ position and velocity, and frequency-domain results from the logged `rt_*` vectors.

## Changing the plant

- Keep workspace variable **names** (`sim_input`, `k_sim`, `b_sim`, `Kt`, …) stable; the app and labs all write those names.
- If you add logged signals, document the new base-workspace names here and in `docs/app.md` (TimePanel / FrequencyPanel will need to plot them).
- Real-Time builds stay out of git (see `.gitignore`).
