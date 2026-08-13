# MSE_lab

MATLAB codebase for **24-452 Mechanical Systems Experimentation** at CMU.

Students run an EMB spring–mass–damper (SMD) kit from [ROBOTS5](https://www.robots5.com/) through Simulink Desktop Real-Time. `MSE_PLANT.slx` is the plant. `MSE_App.mlapp` / `src/App/` is the student UI (in development). There are five labs; each has (or will have) a live script with the minimum code to drive the hardware.

## Layout

```
src/
  MSE_PLANT.slx              % Desktop Real-Time plant
  MSE_App.mlapp              % App Designer shell
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

## Quick start

From the repo root in MATLAB:

```matlab
addpath(genpath('src/App'));
addpath('src');
```

Build a forcing function without the rest of the app:

```matlab
tsData = SignalBuilderApp;   % Finish writes sim_input in the base workspace
```

Or skip the UI:

```matlab
model = SignalBuilderModel;
model.addSignal(StepSignal(2, 5, 5));
[t, y] = model.compileCompositeSignal;
plot(t, y);
```

Lab scripts (`Lab_1.mlx`, `lab_3.m`) assign `sim_input` the same way, then `set_param('MSE_PLANT', 'SimulationMode', 'external')` and start.

## Documentation

If you are changing code, read **[docs/README.md](docs/README.md)** first. That index links to architecture, the main app, the signal builder (including how to add a waveform), signal math, and the plant/labs.

MATLAB classes include a short description and an `Example usage` block in the same style as `SignalBuilderModel`. Paste the example into the Command Window to exercise that class alone.
