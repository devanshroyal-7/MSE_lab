# Developer documentation

Guides for changing this repository. Start with [architecture.md](architecture.md) if you are new to the codebase.

| Document | Use it when you need to… |
| --- | --- |
| [architecture.md](architecture.md) | See how the app, signal builder, Simulink plant, and labs fit together |
| [app.md](app.md) | Change the main MSE window (tabs, sidebar, Simulink wiring) |
| [signal-builder.md](signal-builder.md) | Change the forcing-function UI, add a new signal type, or switch force vs mm reference |
| [signals.md](signals.md) | Change how a forcing waveform is computed |
| [labs-and-plant.md](labs-and-plant.md) | Work on `MSE_PLANT`, hardware parameters, or lab live scripts |

MATLAB class files use the same header style as `SignalBuilderModel`: a short description plus a `%{ Example usage %}` block you can paste into the Command Window to run that class alone.
