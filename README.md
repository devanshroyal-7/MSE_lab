# MSE_lab

MATLAB software for **24-452 Mechanical Systems Experimentation** at CMU. Students drive an EMB spring–mass–damper (SMD) kit from [ROBOTS5](https://www.robots5.com/) through Simulink Desktop Real-Time.

## Highlights

- **Plant** — `MSE_PLANT.slx` runs in Desktop Real-Time (external) mode and reads force, stiffness, and damping from the MATLAB base workspace.
- **Forcing function builder** — `SignalBuilderApp` stacks sine, step, ramp, swept sine, band-limited noise, custom \(F(t)\), and zero-output, then returns a `timeseries`. With the controller on, the same builder is a reference trajectory in mm. The main app writes that to `sim_input`.
- **Student app** — `src/App/` is an MVC window with time/frequency tabs and a sidebar. **Start Simulation** compiles and connects Desktop Real-Time; **Create Forcing Function** opens the builder and plots the result as the reference.
- **Labs** — Live scripts (`Lab_1.mlx`, `lab_3.m`, …) build the same `sim_input` by hand and start the plant. Five labs; each has or will have the minimum code to run the kit.
- **Same contract everywhere** — Labs, `AppModel.setForcingInput`, and the lab scripts all write `sim_input`, `k_sim`, and `b_sim` into the base workspace for `MSE_PLANT`.

## Quickstart

From the repo root in MATLAB:

```matlab
addpath(genpath('src/App'));
addpath('src');
```

`genpath('src/App')` also puts `src/App/components/Images` on the path so sidebar icons resolve.

### 1. Launch the student app

```matlab
main
```

That opens a 1900×900 figure, loads `MSE_PLANT`, and wires the sidebar. **Create Forcing Function** runs `SignalBuilderApp` in force mode; **Enable Controller** switches that button to **Create Reference Trajectory** (mm). **Start Simulation** builds/connects Desktop Real-Time (hardware must be attached).

### 2. Build a forcing function alone

```matlab
tsData = SignalBuilderApp;   % blocks until Finish or the window is closed
tsData = SignalBuilderApp("Mode", "reference");   % mm + travel limit
```

Add waveforms, preview Single vs Overall, then **Finish Signal Building**. That returns a `timeseries`. Closing without Finish returns an empty timeseries (`Length == 0`).

### 3. Build a forcing function (no UI)

```matlab
model = SignalBuilderModel;
model.addSignal(StepSignal(2, 5, 5));     % magnitude [N], on [s], off [s]
model.addSignal(SineSignal(1, 2, 0, 5));  % A [N], f [Hz], phase [deg], duration [s]
[t, y] = model.compileCompositeSignal;    % superposition from t = 0
plot(t, y);
```

Signals overlay on one time axis; they are not played back-to-back. See [docs/signals.md](docs/signals.md).

### 4. Run the plant from a timeseries

```matlab
appModel = AppModel;
appModel.setForcingInput(tsData);   % writes sim_input, k_sim, b_sim; sets StopTime
appModel.startSimulation;          % external (SLDRT) mode
```

Lab 1 is `src/Lab_1.mlx`; Lab 3 sine-sweep is `src/lab_3.m`. Those scripts assign `sim_input` themselves, then `set_param('MSE_PLANT', ...)`.

## Layout

```
src/
  MSE_PLANT.slx              % Desktop Real-Time plant
  Lab_1.mlx, lab_1.m, lab_3.m
  App/
    main.m                   % app entry (MVC)
    AppModel.m, AppView.m, AppController.m
    components/
      forcing_builder/       % standalone forcing-function UI
      main_panels/           % Time, Frequency, Sidebar
      Images/
docs/                        % developer guides
```

## Documentation

Changing code? Start at **[docs/README.md](docs/README.md)**.

| Guide | When to open it |
| --- | --- |
| [architecture.md](docs/architecture.md) | How the app, builder, plant, and labs fit together |
| [app.md](docs/app.md) | Main window, sidebar, Simulink wiring |
| [signal-builder.md](docs/signal-builder.md) | Forcing-function UI, or adding a new waveform type |
| [signals.md](docs/signals.md) | How each `*Signal` is computed |
| [labs-and-plant.md](docs/labs-and-plant.md) | `MSE_PLANT`, hardware parameters, lab scripts |

MATLAB classes use the `SignalBuilderModel` header style: a short description plus an `Example usage` block you can paste into the Command Window.
