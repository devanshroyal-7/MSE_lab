# MSE app

Student-facing window under `src/App/`. Recommended figure size is **1900 × 900** (`main.m`).

## Files

| File | Role |
| --- | --- |
| `main.m` | Entry point. Creates the figure, constructs model/view/controller, registers `CloseRequestFcn`. |
| `AppModel.m` | Loads `MSE_PLANT`, writes hardware constants and `sim_input` to base, starts external-mode simulation, reports run status. |
| `AppView.m` | Grid: title + ROBOTS5 logo, Time / Frequency / Controls tabs, sidebar. Forwards sidebar callbacks to the controller. |
| `AppController.m` | Start Simulation (progress dialog + `startSimulation`); Create Forcing Function / Create Reference Trajectory (`SignalBuilderApp` + reference plot). Save Output writes a `.mat`. |
| `components/main_panels/TimePanel.m` | Response plot (top) and reference plot (bottom). Cached line handles; `updateReferencePlot` / `updateResponsePlot`. |
| `components/main_panels/FrequencyPanel.m` | Forcing FFT, response FFT, FRF axes. |
| `components/main_panels/SidebarPanel.m` | Start/Stop, simulated k/c, PID, Create Forcing Function, Save Outputs. |
| `components/Images/` | `robots5_logo.png`, `sim_start.png`, `sim_stop.png`. |

## Isolated run

```matlab
addpath(genpath('src/App'));
addpath('src');
main
```

Or construct the pieces yourself:

```matlab
fig = uifigure("Name", "MSE Lab", "Position", [500, 500, 1900, 900]);
model = AppModel;                 % load_system('MSE_PLANT'), assignin T/r/Kt
view = AppView(fig);
controller = AppController(model, view);
```

`AppView` builds `TimePanel` and `FrequencyPanel` on tabs, and `SidebarPanel` on the right. After the signal builder finishes, `view.updateReferencePlot(ts)` updates the reference axes.

## AppModel

Constructor calls `load_system("MSE_PLANT")` if the model is not already open, then `assignin` `T`, `r`, `Kt`, and `motor_eff` into the base workspace.

`setForcingInput(ts)`:

1. Stores the timeseries and sets stop time `S` to `ts.Time(end)`.
2. `assignin('base', 'sim_input', ts)` plus `k_sim` and `b_sim`.
3. `set_param(..., 'StopTime', ...)`.
4. `drawnow` so the UI can refresh before a build starts.

`startSimulation`:

1. Clears `TimeBuffer` / `PositionBuffer` / `VelocityBuffer`.
2. Sets `SimulationMode` to `'external'` (Desktop Real-Time).
3. Issues `SimulationCommand` `'start'`.

`getSimulationStatus` / `isSimulationRunning` poll `get_param(..., 'SimulationStatus')`. Status `'running'` or `'external'` counts as running.

The `DataUpdated` event is declared but nothing notifies it yet. Live streaming into `TimePanel.updateResponsePlot` is future work.

## AppView layout

10×10 `uigridlayout`:

- Row 1: course title (cols 1–6), logo (cols 9–10)
- Rows 2–10, cols 1–7: `uitabgroup` (Time, Frequency, Controls)
- Rows 2–10, cols 8–10: `SidebarPanel`

Save Output lives on the sidebar (not a bottom-row button). The Controls tab is still an empty placeholder; live controls are the sidebar.

Callback chain:

`SidebarPanel.fwd*` → `AppView.handle*` → `AppView.fwd*View` → `AppController.handle*`

## AppController

| Sidebar action | Controller method |
| --- | --- |
| Start Simulation | `handleRunSimCallback` — indeterminate progress dialog, `Model.startSimulation`, poll until running or stopped |
| Create Forcing Function | `handleSignalBuilderCallback` — `SignalBuilderApp("Mode", ...)` from Enable Controller, then `setForcingInput` and `updateReferencePlot` if `Length > 0` |
| Enable Controller | `handleEnableControlsCallback` — retitle the builder button, switch TimePanel ylabel to N or mm, clear `sim_input` |
| Save Outputs | `handleSaveOutputCallback` — stub |

`uiwait` is **not** used on the main figure (it delayed simulation). The forcing builder still uses `uiwait` internally.

## SidebarPanel

Four blocks:

1. **Simulation Controls** — Start / Stop. Start forwards `fwdRunSignalCallback`. Stop has no callback yet.
2. **Simulated Parameters** — `k_simulated` [N/m], `c_simulated` [N·s/m], enable state button (red DISABLED / green ENABLED). The toggle only changes appearance.
3. **Control Parameters** — `Kp`, `Ki`, `Kd`, Enable Controller. Enabling switches the builder to mm reference mode and clears any leftover force signal.
4. **Create Forcing Function** / **Save Outputs** on the bottom row. The create button becomes **Create Reference Trajectory** while the controller is on.

`enableSimParamCallback` only changes the simulated-parameter button color. `enableControlCallback` updates the controller button and forwards to `AppController`, which retitles the builder button, switches the TimePanel ylabel, and clears `sim_input`. Gains are not written to the plant yet.

## TimePanel and FrequencyPanel

`TimePanel` keeps `RefLineHandle` / `RespLineHandle` so updates are `set(h, 'XData', t, 'YData', y)` instead of a new `plot`. After **Create Forcing Function**, the controller calls `updateReferencePlot`. The reference ylabel follows `SignalQuantity` (`Force (N)` or `Displacement (mm)`). Overlay-on-response stays force for now. Response streaming is not wired yet.

`FrequencyPanel` is still display-only. After a run, a future controller should compute FFTs and FRF = response / forcing.

## Changing the main window

- Layout / new widgets → `AppView` or the relevant `main_panels` class.
- Simulink / buffers / workspace variables → `AppModel`.
- Button behavior → `AppController`, then assign a function handle on the view or sidebar.

Do not call `set_param` from a panel.
