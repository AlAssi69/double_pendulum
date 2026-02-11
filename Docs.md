# Project: DoublePendulumSim

**Version:** 1.0.0
**Language:** MATLAB (R2023b+)
**Paradigm:** Object-Oriented Programming (OOP) with Package-based Architecture

## 1. Overview

This project simulates the chaotic dynamics of a double pendulum system. It features a modular architecture that separates physics calculation, control logic, and visualization. The system includes a graphical user interface (GUI) for runtime configuration, real-time animation, state trajectory plotting, and Poincaré map analysis.

---

## 2. Package Architecture

The project is organized into MATLAB packages (`+folder`) to enforce namespace separation.

| Package | Responsibility |
| --- | --- |
| **`+Core`** | Handles the physics and equations of motion (EOM); simulation uses the Integration package for stepping. |
| **`+Integration`** | ODE solver abstraction: `ISolver`, Euler, RK4, ode45; switch via `SolverType` ("euler" \| "rk4" \| "ode45"). |
| **`+Control`** | Contains abstract controller interfaces and concrete implementations (e.g., LQR). |
| **`+Vis`** | Manages all visualization strategies (Animation, Plots, Phase Plane). |
| **`+UI`** | Manages the Configuration GUI and user interaction events. |
| **`+Utils`** | Helper functions (config loaders, angle normalization). |

---

## 3. Class Design & Separation of Concerns

### A. The Core Layer (`+Core`)

**`Core.DoublePendulumModel`**

* **Role:** The "Truth" of the system. Stores physical parameters () and calculates the state derivatives.
* **Key Methods:**
* `getDerivatives(state, u)`: Computes  using Lagrangian mechanics.
* `linearizePoint(equilibrium_state)`: Returns  and  matrices for control design.



**`Core.Simulator`**

* **Role:** The engine. Orchestrates the simulation loop. It decouples the math model from the time-stepping logic; the integration engine is provided by the **`+Integration`** package (Euler, RK4, or ode45).
* **Key Properties:** `CurrentState`, `Time`, `SolverType` ("euler" \| "rk4" \| "ode45"), `StepSize`, `Debug` (when true, prints solver and step size once at run start).
* **Key Methods:** `step(dt, u)`, `run(timeSpan)`.

**`Core.SimulationRecorder`**

* **Role:** Observer that records time, state, and control each step (no graphics). Use `getResults()` after `run()` to obtain the time series for saving or playback.

**`Core.PlaybackSim`**

* **Role:** Mock simulator for smooth playback from saved or in-memory data. Exposes `Time`, `CurrentState` (interpolated), `Model`, and `Controller` so existing visualizers can drive from recorded data.

**`Integration` package**

* **Role:** Pluggable ODE solvers. `ISolver` defines the interface; `EulerSolver`, `RK4Solver`, `ODE45Solver` implement it. Use `Integration.SolverFactory.getSolver(name)` to obtain a solver; the Simulator uses this to advance state each step.

### B. The Control Layer (`+Control`)

**`Control.IController` (Abstract Interface)**

* **Role:** Defines the contract for all controllers.
* **Method:** `u = computeControl(t, state)`

**`Control.LQRController < Control.IController`**

* **Role:** Implements the Linear-Quadratic Regulator.
* **Logic:** Computes gain matrix  based on linearized dynamics and computes .

**`Control.PlaybackController < Control.IController`**

* **Role:** Returns control `u` interpolated at the current time from a recorded series. Used by `PlaybackSim` for smooth visualization from saved results.

### C. The Visualization Layer (`+Vis`)

**`Vis.VisualizerManager`**

* **Role:** Observer pattern implementation. Subscribes to the `Simulator` and updates all active visualization modules synchronously.

**`Vis.PendulumAnimator`**

* **Role:** Renders the "nice and colorful" 2D animation.
* **Features:** Traces path history, uses distinct colors for masses, updates at 60 FPS.

**`Vis.StatePlotter`**

* **Role:** Time-series visualization.
* **Plots:** Subplots for Angles (), Velocities (), and Control Input ().

**`Vis.PoincareMap`**

* **Role:** Phase-space visualization.
* **Features:**
* Scatter plot that updates continuously.
* Configurable axes (default: x-axis , y-axis ).



### D. The UI Layer (`+UI`)

**`UI.ConfigWindow`**

* **Role:** Entry point GUI (built with `uifigure`). Blocking until user clicks Start; exposes edited config via properties.
* **Fields:** Model params (m1, m2, L1, L2), Initial state (θ1, θ2), Time span, **Solver** (dropdown: euler \| rk4 \| ode45), **Step size dt**, Enable LQR control, LQR Q/R (when control enabled).
* **Properties:** `Params`, `InitialState`, `TimeSpan`, `SolverType`, `StepSize`, `EnableControl`, `Q`, `R`.

---

## 4. Mathematical Foundation

The system dynamics are derived using the Euler-Lagrange equation:


Where the state vector is defined as:


The `Core.DoublePendulumModel` implementation ensures conservation of energy (in un-damped, un-forced mode) to validate solver accuracy.

---

## 5. Implementation Workflow (Pseudo-code)

### Main Entry Point (`main.m`)

```matlab
% 1. Initialize Default Configuration
config = Utils.ConfigLoader.loadDefault();

% 2. Launch GUI to allow user overrides (Params, InitialState, TimeSpan, Solver, Step size, LQR, Q, R)
app = UI.ConfigWindow(config);
waitfor(app.Fig); % Block until user clicks 'Start'

% 3. Instantiate Core
model = Core.DoublePendulumModel(app.Params);

% 4. Instantiate Controller (Strategy Pattern)
if app.EnableControl
    ctrl = Control.LQRController(model, app.Q, app.R);
else
    ctrl = Control.NullController();
end

% 5. Setup Visualization (when config.Visual)
if config.Visual
    vizManager = Vis.VisualizerManager();
    vizManager.add(Vis.PendulumAnimator());
    vizManager.add(Vis.StatePlotter());
    vizManager.add(Vis.PoincareMap('XVar', config.PoincareXVar, 'YVar', config.PoincareYVar));
end

% 6. Run Simulation (no live visualization; recorder only for speed)
recorder = Core.SimulationRecorder();
sim = Core.Simulator(model, ctrl);
sim.attachObserver(recorder);
sim.run(app.TimeSpan);

% 7. Save time series to config.ResultsDir (e.g. results/double_pendulum_YYYYMMDD_HHMMSS.mat)
% 8. If config.Visual: smooth playback at config.PlaybackFps (e.g. 30 fps)
```

**Run without visualization:** Set `config.Visual = false` in `Utils.ConfigLoader.loadDefault()` to skip playback entirely (simulation still runs and results are saved).

**Load and visualize later:** Run `playback_saved.m` to load the most recent saved run from the `results` folder and play it back at the configured frame rate.

---

## 6. Visualization Specs

### 1. Real-time Animator

* **Style:** White background with clean, high-contrast aesthetics.
* **Link 1:** Red thick line.
* **Link 2:** Blue thick line.
* **Masses:** Filled circular markers (red and blue) with black edge outlines.
* **Trace:** Blue semi-transparent tail showing the trajectory of mass 2.

### 2. Poincaré Map

* **Description:** A stroboscopic map or continuous phase plot.
* **Configuration:** Dropdown menu in the plot window allows changing axes on the fly (e.g., switch from  vs  to  vs ).

---

## 7. Future Extensions

* **Energy Plot:** Real-time graph of Kinetic vs. Potential energy to verify symplectic integration.
* **Export:** Option to save the animation as `.mp4`.
