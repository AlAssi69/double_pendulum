# Double Pendulum Sim

MATLAB simulation of a double pendulum with **full nonlinear dynamics** (Euler–Lagrange), **shoulder-only torque control**, and an **RL-friendly** interface.

## Quick start

1. Open the project folder in MATLAB and run:
   ```matlab
   main
   ```
2. Adjust parameters in the config window (optional) and click **Start**.
3. Watch the animation, state plots, and Poincaré map.

## Packages

| Package   | Contents |
|----------|----------|
| **+Core**   | `DoublePendulumModel` (physics, `getDerivatives`, `linearizePoint`), `Simulator` (step/run with RK4). |
| **+Control**| `IController`, `NullController`, `LQRController`. |
| **+Env**    | `DoublePendulumEnv` – reset/step API for reinforcement learning. |
| **+Vis**    | `VisualizerManager`, `PendulumAnimator`, `StatePlotter`, `PoincareMap`. |
| **+UI**     | `ConfigWindow` – config GUI. |
| **+Utils**  | `ConfigLoader`, `normalizeAngle`. |

## Physics

- **State:** \(x = [\theta_1,\, \theta_2,\, \dot{\theta}_1,\, \dot{\theta}_2]^T\) (rad, rad/s).
- **Control:** Single scalar \(u\) = torque at the shoulder (first joint); second joint is unactuated.
- **Dynamics:** Full nonlinear EOM from Lagrangian; optional viscous damping at each joint. No small-angle approximation.

## RL interface (`+Env`)

Use `Env.DoublePendulumEnv` for training or evaluation:

- **Observation/state:** 4D vector \(x\) (same as above). Use `getObservation()` if you add cos/sin later.
- **Action:** Scalar torque, clipped to `[-MaxTorque, MaxTorque]` (default 10 N·m).
- **Step:** `[next_state, reward, done, info] = env.step(action)` – one fixed step (default 0.02 s) with RK4.
- **Reset:** `[state, info] = env.reset()` or `env.reset(initial_state)`.

**Reward** (default): \(r = -(x - x_{\text{goal}})^T Q (x - x_{\text{goal}}) - R\,u^2\). Goal is upright: `[0; 0; 0; 0]`. Tune via env properties `Q`, `R`, `GoalState`, `MaxTorque`, `MaxSteps`.

**Example loop (no GUI):**

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

## Using the MATLAB Reinforcement Learning Toolbox

You can wrap `DoublePendulumEnv` in a custom environment that implements the Toolbox interface (e.g. `rlFunctionEnv` or a custom `rl.env.MATLABEnvironment` subclass) so that `step` and `reset` call the env and map state/action/reward accordingly. The same dynamics and reward are used as above.

## Requirements

- MATLAB R2023b+ (or R2020b+ for UI components; R2023b+ recommended per docs).
