# MSE app

Student-facing window under `src/App/`. Recommended figure size is **1100 × 850** (see the `AppView` header).

## Files

| File | Role |
| --- | --- |
| `main.m` | Entry point. Instantiates model/view/controller. Still a stub: `AppView` needs a parent `uifigure`. |
| `AppModel.m` | Loads `MSE_PLANT`, holds buffers and `k_sim` / `b_sim`, starts external-mode simulation. |
| `AppView.m` | Grid: title + ROBOTS5 logo, Time / Frequency / Controls tabs, sidebar, Save Output. |
| `AppController.m` | Should connect sidebar Start to `AppModel.startSimulation`. `handleRunSimCallback` is empty. |
| `components/main_panels/TimePanel.m` | Response plot (top) and reference plot (bottom), overlay checkbox. |
| `components/main_panels/FrequencyPanel.m` | Forcing FFT, response FFT, FRF axes. |
| `components/main_panels/SidebarPanel.m` | Start/Stop, simulated k/c, PID Kp/Ki/Kd, enable toggles. |
| `components/Images/` | `robots5_logo.png`, `sim_start.png`, `sim_stop.png`. |
| `../MSE_App.mlapp` | App Designer shell. The programmatic classes above are the code that is actually evolving. |

## Isolated run

```matlab
addpath(genpath('src/App'));
fig = uifigure("Name", "MSE Lab", "Position", [500, 500, 1100, 850]);
model = AppModel;                 % load_system('MSE_PLANT')
view = AppView(fig);
controller = AppController(model, view);
```

`AppView` builds `TimePanel` and `FrequencyPanel` on tabs, and `SidebarPanel` on the right. Access axes with `view.TimeDomainPanel.ResponsePlot` and `view.FreqDomainPanel.AxFRF`.

## AppModel

Constructor calls `load_system("MSE_PLANT")` if the model is not already open.

`setForcingInput(ts)`:

1. Stores the timeseries and sets stop time `S` to `ts.Time(end)`.
2. `assignin('base', 'sim_input', ts)` plus `k_sim` and `b_sim`.
3. `set_param(..., 'StopTime', ...)`.

`startSimulation`:

1. Clears `TimeBuffer` / `PositionBuffer` / `VelocityBuffer`.
2. Sets `SimulationMode` to `'external'` (Desktop Real-Time).
3. Issues `SimulationCommand` `'start'`.

The `DataUpdated` event is declared but nothing notifies it yet. Live streaming from the plant into the time-scope axes is future work.

Hardware constants `r`, `Kt`, `motor_eff` match the lab scripts. They are protected on the model; the plant still uses the copies in the base workspace that the labs assign.

## AppView layout

10×10 `uigridlayout`:

- Row 1: course title (cols 1–6), logo (cols 9–10)
- Rows 2–9, cols 1–7: `uitabgroup` (Time, Frequency, Controls)
- Rows 2–9, cols 8–10: `SidebarPanel`
- Row 10: Save Output button (not hooked up)

`fwdRunSimCallback` is the hook `AppController` assigns. `RunSimCallback` just calls it. The sidebar Start button currently calls `SidebarPanel.runSimCallback`, which is empty and is **not** forwarded to `AppView` yet. Connecting those two is the next wiring step.

## SidebarPanel

Three blocks:

1. **Simulation Controls** — Start / Stop. Start has `ButtonPushedFcn` → `runSimCallback` (stub). Stop has no callback.
2. **Simulated Parameters** — `k_simulated` [N/m], `c_simulated` [N·s/m], enable state button (red DISABLED / green ENABLED). The toggle only changes appearance.
3. **Control Parameters** — `Kp`, `Ki`, `Kd`, same enable pattern. Not written to the plant.

`enableSimParamCallback` / `enableControlCallback` are the place to later `assignin` gains and call `set_param`.

## TimePanel and FrequencyPanel

These are display-only. After a run, the controller (once implemented) should:

- Plot cart position/velocity on `TimePanel.ResponsePlot`
- Plot `sim_input` on `TimePanel.ReferencePlot`
- If `OverlayCheckBox.Value`, overlay the reference on the response axes
- Compute FFTs and FRF = response / forcing and plot on `FrequencyPanel`

There is no DSP code in these classes on purpose.

## Changing the main window

- Layout / new widgets → `AppView` or the relevant `main_panels` class.
- Simulink / buffers / workspace variables → `AppModel`.
- Button behavior → `AppController`, then assign a function handle on the view or sidebar.

Do not call `set_param` from a panel.
