# 🎯 Double Pendulum Sim

A **MATLAB** simulation of a double pendulum with full nonlinear dynamics, optional LQR control, and an RL-ready environment. Perfect for chaos exploration, control design, or reinforcement learning.

---

## 🚀 Quick Start

1. **Open** the project folder in MATLAB.
2. **Run** the main script:
   ```matlab
   main
   ```
3. **Configure** (optional): use the config window to set masses, lengths, initial angles, time span, and whether to use LQR control.
4. **Click Start** and watch:
   - 🎬 Real-time pendulum animation  
   - 📈 State plots (angles, velocities, control)  
   - 🗺️ Poincaré map (phase space)

---

## 📁 Project Structure

```
Double Pendulum/
├── main.m                 # Entry point: GUI → simulation → visualization
├── +Core/                 # Physics & simulation engine
│   ├── DoublePendulumModel.m   # EOM, linearization
│   └── Simulator.m             # Stepping, observer pattern (solver from +Integration)
├── +Integration/          # ODE solvers (pluggable)
│   ├── ISolver.m                # Abstract interface
│   ├── EulerSolver.m            # Explicit Euler
│   ├── RK4Solver.m              # Runge–Kutta 4
│   ├── ODE45Solver.m            # MATLAB ode45
│   └── SolverFactory.m          # getSolver("euler"|"rk4"|"ode45")
├── +Control/              # Controllers
│   ├── IController.m           # Abstract interface
│   ├── NullController.m        # No control (free swing)
│   ├── LQRController.m         # LQR around upright
│   └── RLPolicyController.m    # Wrapper for RL agent actions
├── +Env/                  # RL environment
│   └── DoublePendulumEnv.m     # reset/step API, reward, bounds
├── +Vis/                  # Visualization
│   ├── VisualizerManager.m     # Coordinates all visualizers
│   ├── PendulumAnimator.m      # 2D animation
│   ├── StatePlotter.m          # Time-series plots
│   └── PoincareMap.m           # Phase-space plot
├── +UI/                   # User interface
│   └── ConfigWindow.m          # Config GUI (uifigure)
└── +Utils/                # Helpers
    ├── ConfigLoader.m          # Default config
    └── normalizeAngle.m       # Angle normalization
```

| Folder | Role |
|--------|------|
| **+Core** | Physics model (Euler–Lagrange), simulator (solver from +Integration). |
| **+Integration** | Pluggable ODE solvers: Euler, RK4, ode45; switch via `SolverType`. |
| **+Control** | Null, LQR, or RL policy; all implement `computeControl(t, state)`. |
| **+Env** | RL interface: `reset()`, `step(action)`, reward and clipping. |
| **+Vis** | Animation, state plots, Poincaré map; attached to simulator. |
| **+UI** | Config window for parameters and initial conditions. |
| **+Utils** | Config loading, angle utils. |

---

## ⚙️ What You Can Do

- **Free swing** (no control): see chaotic motion and Poincaré maps.  
- **LQR control**: stabilize around the upright equilibrium (toggle in config).  
- **RL training**: use `Env.DoublePendulumEnv` with `reset`/`step` and plug into the MATLAB RL Toolbox or your own agent.

---

## 🔬 Physics Summary

- **State:** \(x = [\theta_1,\, \theta_2,\, \dot{\theta}_1,\, \dot{\theta}_2]^T\) (rad, rad/s).  
- **Control:** Single torque \(u\) at the shoulder; second joint is unactuated.  
- **Dynamics:** Full nonlinear equations from the Lagrangian; optional damping. No small-angle approximation.

---

## 🤖 Using the RL Environment

`Env.DoublePendulumEnv` provides a standard `reset` / `step` API:

- **Observation:** 4D state vector \(x\).  
- **Action:** Scalar torque, clipped to `[-MaxTorque, MaxTorque]` (default 10 N·m).  
- **Step:** `[next_state, reward, done, info] = env.step(action)` (fixed step, default 0.02 s).  
- **Reset:** `[state, info] = env.reset()` or `env.reset(initial_state)`.

**Default reward:** \(r = -(x - x_{\text{goal}})^T Q (x - x_{\text{goal}}) - R\,u^2\) with goal upright `[0; 0; 0; 0]`. Tune via `Q`, `R`, `GoalState`, `MaxTorque`, `MaxSteps`.

**Minimal loop (no GUI):**

```matlab
model = Core.DoublePendulumModel(struct('m1',1,'m2',1,'L1',1,'L2',1,'g',9.81));
env = Env.DoublePendulumEnv(model, struct('MaxTorque', 10, 'MaxSteps', 500));
[state, info] = env.reset();
for k = 1:500
    u = 0;  % or u = your_policy(state);
    [state, reward, done, info] = env.step(u);
    if done, break; end
end
```

You can wrap this env in the MATLAB Reinforcement Learning Toolbox (e.g. `rlFunctionEnv` or a custom `rl.env.MATLABEnvironment` subclass).

---

## 📋 Requirements

- **MATLAB** R2023b+ (R2020b+ for UI; R2023b+ recommended).  
- No extra toolboxes required for basic simulation; RL Toolbox only if you use it for training.

---

## 📄 License

See [LICENSE](LICENSE). For more design and math details, see [Docs.md](Docs.md).
