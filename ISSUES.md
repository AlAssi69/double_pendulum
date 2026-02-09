# 🔍 Codebase Issues & Inconsistencies

Audit of the Double Pendulum project. Each issue is documented as: **Problem** | **Where** | **Current behavior** | **True behavior** | **Suggested solution**.

---

## 🔴 CRITICAL — Physics & Correctness Bugs

### 1. Sign error in Coriolis term (C2)

| | |
|---|---|
| **Problem** | The centrifugal/Coriolis contribution for the second equation of motion has the wrong sign. |
| **Where** | `+Core/DoublePendulumModel.m`, lines 62–63 |
| **Current behavior** | `C2 = m2*L1*L2*s2*w1^2` (positive). This term is added to the RHS of the second EOM. |
| **True behavior** | From Euler–Lagrange (or standard robot dynamics $M\ddot{q}+C\dot{q}+g=\tau$), the Coriolis term for the second equation should be **negative**: $-m_2 L_1 L_2 \sin(\theta_2) \dot\theta_1^2$. Energy is not conserved; the second arm responds in the wrong direction to centrifugal effects. |
| **Suggested solution** | Change line 63 to: `C2 = -m2*L1*L2*s2*w1^2;` |

---

### 2. LQR captures eigenvalues instead of gain matrix

| | |
|---|---|
| **Problem** | The third output of `lqr()` is used as the control gain; the first output (the actual gain) is discarded. |
| **Where** | `+Control/LQRController.m`, line 16 |
| **Current behavior** | `[~, ~, K] = lqr(A, B, Q, R);` — the third return value is the closed-loop poles (eigenvalues), not the gain matrix. The controller would use eigenvalues (often complex) as “gains,” producing nonsensical or complex control. |
| **True behavior** | `lqr(A,B,Q,R)` returns `[K, S, P]` where **K** = optimal gain, **S** = Riccati solution, **P** = closed-loop poles. The control law must use **K**. |
| **Suggested solution** | Use the first output: `[K, ~, ~] = lqr(A, B, Q, R);` (and keep the next line as `obj.K = K(:)';` after fixing the property size — see issue #3). |

---

### 3. K property dimension mismatch

| | |
|---|---|
| **Problem** | The `K` property is declared as `(4,1)` but the code assigns a `1×4` row vector; MATLAB property validation rejects this. |
| **Where** | `+Control/LQRController.m`, line 5 and line 17 |
| **Current behavior** | Property: `K (4,1) double`. Constructor: `obj.K = K(:)';` → 1×4. Assignment fails (size mismatch). Combined with issue #2, the LQR path errors at runtime when control is enabled. |
| **True behavior** | For $u = -K(x - x_{ref})$, **K** must be 1×4 (row) so that **K** × (4×1 state) = scalar. The property should allow a 1×4 row vector. |
| **Suggested solution** | Change the property to `K (1,4) double` and assign `obj.K = K(:)';` (or keep `obj.K = K;` if you already capture the first output from `lqr`, since `lqr` returns 1×4 for single-input). |

---

## 🟠 HIGH — Functional Issues

### 4. SolverType setter does not store the property value

| | |
|---|---|
| **Problem** | The custom setter for `SolverType` updates the internal solver but never assigns the new value to the property. |
| **Where** | `+Core/Simulator.m`, lines 29–31 |
| **Current behavior** | `set.SolverType(obj, name)` only sets `obj.Solver_`; it does not set `obj.SolverType`. The property keeps its previous value (e.g. `"rk4"`). Debug output and any code reading `sim.SolverType` always see the default. |
| **True behavior** | After the user (or main) sets `sim.SolverType = "euler"`, both the internal solver and the property should reflect `"euler"`. |
| **Suggested solution** | In the setter, after creating the solver, assign the property. In MATLAB you must do this explicitly in the setter, e.g. store the value in a private backing field if needed, or use: `obj.SolverType = name;` (check MATLAB version for setter recursion). Typically the setter is written to set both the backing solver and the public property (e.g. `obj.SolverType = name;` at the end of the setter). |

---

### 5. LQR linearizes at the wrong equilibrium

| | |
|---|---|
| **Problem** | LQR is intended to stabilize the **upright** equilibrium, but linearization is done at the **downward** equilibrium. |
| **Where** | `+Control/LQRController.m`, line 14 |
| **Current behavior** | `x_eq = [0; 0; 0; 0]` — both arms hanging down (stable equilibrium). LQR is computed for this point, so it only adds damping to an already stable system. |
| **True behavior** | Upright equilibrium (inverted) is $\theta_1 = \pi,\, \theta_2 = 0,\, \dot\theta_1 = \dot\theta_2 = 0$, i.e. `x_eq = [pi; 0; 0; 0]`. Linearization and LQR should be at this point for “stabilize upright” behavior. |
| **Suggested solution** | Set `x_eq = [pi; 0; 0; 0];` (and ensure reference `x_ref` is the same so that $u = -K(x - x_{ref})$ drives the state toward upright). |

---

### 6. PoincareMap.getVar references undefined obj

| | |
|---|---|
| **Problem** | The method signature discards the first argument with `~`, but the body uses `obj`, which is never defined. |
| **Where** | `+Vis/PoincareMap.m`, lines 125–128 |
| **Current behavior** | Calling `getVar(state, name)` causes “Undefined variable 'obj'”. The method appears unused (only `getVarVec` is used) but would crash if called. |
| **True behavior** | The first argument should be the instance (`obj`). The method should be callable as `obj.getVar(state, name)` and use `obj.varIndex(name)`. |
| **Suggested solution** | Change the signature to `function v = getVar(obj, state, name)` so `obj` is in scope. Alternatively, remove `getVar` if it is dead code. |

---

## 🟡 MEDIUM — Design & Inconsistencies

### 7. Documentation describes a different visual theme

| | |
|---|---|
| **Problem** | Docs say the animator uses a dark, neon style; the code uses a light theme and different colors. |
| **Where** | `Docs.md` (e.g. lines 158–162) vs `+Vis/PendulumAnimator.m` (e.g. lines 22–32) |
| **Current behavior** | Docs: “Dark mode background with neon aesthetics,” “Cyan thick line,” “Magenta thick line.” Code: white figure background, red and blue lines. |
| **True behavior** | Documentation should match the implementation, or the implementation should be updated to match the intended design. |
| **Suggested solution** | Either update `Docs.md` to describe the current white/red/blue theme, or change `PendulumAnimator.m` to use a dark background and cyan/magenta (or equivalent) line colors. |

---

### 8. Hardcoded axis limits in PendulumAnimator

| | |
|---|---|
| **Problem** | Axis limits are fixed at ±2.2 and do not scale with model lengths. |
| **Where** | `+Vis/PendulumAnimator.m`, lines 33–35 |
| **Current behavior** | `L = 2.2; xlim(obj.Ax, [-L L]); ylim(obj.Ax, [-L L]);` — works for L1=L2=1 (reach = 2) but clips when L1+L2 > 2.2. |
| **True behavior** | The visible range should accommodate the full reach of the pendulum (e.g. L1 + L2 plus a small margin). |
| **Suggested solution** | Compute limits from the model: e.g. `L = sim.Model.L1 + sim.Model.L2` (or pass model into the constructor) and use `L = L * 1.1` or similar for margin, then set `xlim`/`ylim`. Optionally update limits in `update()` if model can change. |

---

### 9. StatePlotter relies on fragile Children indexing

| | |
|---|---|
| **Problem** | Line data is updated by index into `get(obj.AxTh, 'Children')`, which depends on creation order. |
| **Where** | `+Vis/StatePlotter.m`, lines 74–81 |
| **Current behavior** | `kidsTh(1)` and `kidsTh(2)` are assumed to correspond to θ₂ and θ₁ respectively (reverse creation order). Adding plots or changing order can swap the series silently. |
| **True behavior** | Each series should be updated by a stable handle, not by position in Children. |
| **Suggested solution** | Store the line handles returned by `plot()` in properties (e.g. `obj.LineTh1`, `obj.LineTh2`) and use them in `update()` instead of indexing into `Children`. Same idea for velocity and control axes. |

---

### 10. normalizeAngle unused; RL env angles unbounded

| | |
|---|---|
| **Problem** | `Utils.normalizeAngle` exists but is never used. RL env state (and reward) use raw angles that can grow without bound. |
| **Where** | `+Utils/normalizeAngle.m` (defined); `+Env/DoublePendulumEnv.m` (angles not wrapped) |
| **Current behavior** | Observation and reward use `next_state` with angles that can exceed ±π after many rotations. Reward $-(x-x_{goal})^T Q (x-x_{goal}) - R u^2$ becomes huge even when the pendulum is physically near the goal. |
| **True behavior** | For RL, angles should typically be wrapped to a consistent interval (e.g. $[-\pi,\pi]$) so that reward and observations reflect “same physical state.” |
| **Suggested solution** | In `DoublePendulumEnv.step`, wrap angle components of `next_state` (and optionally of the observation) using `Utils.normalizeAngle` (e.g. wrap to $[-\pi,\pi]$). Optionally document or use `normalizeAngle` in visualization (e.g. Poincaré) where continuous unwrapped is desired. |

---

### 11. PoincareMap dropdowns don’t sync with config XVar/YVar

| | |
|---|---|
| **Problem** | The X/Y dropdowns are always initialized to “theta1” and “theta2”; they don’t reflect `config.PoincareXVar` / `config.PoincareYVar`. |
| **Where** | `+Vis/PoincareMap.m`, constructor and dropdown creation (e.g. lines 44–46) |
| **Current behavior** | If config sets `PoincareXVar = "omega1"`, the map uses omega1 for X, but the dropdown still shows “theta1” until the user changes it. |
| **True behavior** | Dropdown selection should match the axes actually used, which should match config when provided. |
| **Suggested solution** | When building the dropdowns, set `'Value'` from the index of `obj.XVar` and `obj.YVar` in the `vars` list (e.g. `find(vars == obj.XVar, 1)`), so the displayed selection matches the configured variables. |

---

### 12. ConfigWindow uses str2num for time span

| | |
|---|---|
| **Problem** | `str2num` is eval-based and can execute arbitrary code; it’s discouraged for parsing user input. |
| **Where** | `+UI/ConfigWindow.m`, e.g. line 124 and in `doClose` (e.g. line 191) |
| **Current behavior** | `ts = str2num(v);` parses the time-span string. If the string contained malicious code, it would run. |
| **True behavior** | Time span should be parsed without evaluating arbitrary expressions. |
| **Suggested solution** | Replace with a safe parser, e.g. `sscanf(v, '%f', [1 2])` or a small regex/tokenizer that only accepts numbers and spaces, then validate length and sign. |

---

### 13. ConfigWindow internal methods are public

| | |
|---|---|
| **Problem** | Many methods are only used internally by the GUI but are exposed as public. |
| **Where** | `+UI/ConfigWindow.m` — e.g. `setP`, `setState`, `setTS`, `editCallback`, `assignSolverType`, `setAngleUnit`, `setEnableControl`, `setStepSize`, `angleToDisplay`, `angleFromDisplay`, `refreshStateDisplay`, `doClose` |
| **Current behavior** | External code can call these methods, making the class contract larger than intended and allowing unintended usage. |
| **True behavior** | Only the constructor and the public properties (e.g. `Params`, `InitialState`, `Fig`) need to be part of the external API. |
| **Suggested solution** | Move all internal and callback methods into a `methods (Access = private)` block, leaving only the constructor (and any intended public API) in the default public methods. |

---

## 🟢 LOW — Performance & Gaps

### 14. O(n²) data accumulation in plotters

| | |
|---|---|
| **Problem** | StatePlotter and PoincareMap append to arrays every step and (in StatePlotter) call `unwrap` on the full history each time. |
| **Where** | `+Vis/StatePlotter.m` (e.g. lines 56–65); `+Vis/PoincareMap.m` (history append) |
| **Current behavior** | Each step does O(n) work (concat + full unwrap), so total cost is O(n²). Fine for short runs; slow for long or RL-length runs. |
| **True behavior** | For long runs, growth should be bounded or cost per step kept O(1) where possible. |
| **Suggested solution** | Cap history length (like `PendulumAnimator.MaxTracePoints`) and/or only unwrap new samples and merge with previous unwrapped tail. For PoincareMap, optionally cap `StateHistory`/`TimeHistory` length. |

---

### 15. No figure validity check during simulation

| | |
|---|---|
| **Problem** | If the user closes a figure mid-run, the next observer update touches deleted handles and can error. |
| **Where** | Simulator’s `notifyObservers()` and each visualizer’s `update()` (e.g. `+Vis/PendulumAnimator.m`, `+Vis/StatePlotter.m`, `+Vis/PoincareMap.m`) |
| **Current behavior** | No check that the figure/axes still exist. Closing a window causes errors and can stop the simulation. |
| **True behavior** | Updates should only run when the figure is still valid; closed figures should be skipped or detached. |
| **Suggested solution** | At the start of each visualizer’s `update()`, check `isvalid(obj.Fig)` (and optionally `obj.Ax`). If invalid, return immediately or remove self from the observer list if the manager supports it. |

---

### 16. GUI doesn’t expose g, beta1, beta2, or initial angular velocities

| | |
|---|---|
| **Problem** | Config window only exposes m1, m2, L1, L2, θ1, θ2, time span, solver, step size, LQR toggle. |
| **Where** | `+UI/ConfigWindow.m` and `+Utils/ConfigLoader.m` |
| **Current behavior** | Gravity (g) and damping (beta1, beta2) can only be changed in `ConfigLoader.m`. Initial ω1, ω2 are fixed (e.g. 0). |
| **True behavior** | Users may want to change g, damping, or initial angular velocities without editing source. |
| **Suggested solution** | Add optional GUI fields for g, beta1, beta2, and for initial omega1, omega2 (with sensible defaults and validation). Pass them through to `Params` and `InitialState` in the same way as existing fields. |

---

### 17. ODE45Solver per-step overhead

| | |
|---|---|
| **Problem** | Each call to `ODE45Solver.step` builds a new function handle, options, and calls `ode45` from scratch. |
| **Where** | `+Integration/ODE45Solver.m` |
| **Current behavior** | For the same accuracy, one full `ode45` call over the whole time span would be cheaper. The one-step interface forces re-initialization every step. |
| **True behavior** | This is a design trade-off (pluggable fixed-step API vs. adaptive solver efficiency). No bug, but a known limitation. |
| **Suggested solution** | Document the overhead. If needed, add an optional “batch” mode that runs `ode45` once over the full span and then samples at the requested step times, or keep as-is and recommend RK4 for long runs. |

---

### 18. DoublePendulumEnv doesn’t sync solver settings to internal Simulator

| | |
|---|---|
| **Problem** | The env’s internal `Simulator` is created with defaults; its `StepSize` and `SolverType` are never set from the env’s options. |
| **Where** | `+Env/DoublePendulumEnv.m`, constructor and `step()` |
| **Current behavior** | `step(obj.StepSize, u)` passes the env’s step size, so the actual step is correct. But `obj.Simulator.StepSize` and `obj.Simulator.SolverType` remain at defaults. Any code that reads them or calls `Simulator.run()` would use wrong settings. |
| **True behavior** | The internal Simulator’s step size and solver type should match the env’s configuration. |
| **Suggested solution** | After creating the Simulator, set `obj.Simulator.StepSize = obj.StepSize` and, if you add a `SolverType` (or similar) to the env options, set `obj.Simulator.SolverType` accordingly. |

---

## Summary

| Severity | Count | Focus |
|----------|-------|--------|
| 🔴 Critical | 3 | Physics (C2 sign), LQR gain and property size |
| 🟠 High | 3 | SolverType setter, LQR equilibrium, PoincareMap.getVar |
| 🟡 Medium | 7 | Docs, axis limits, Children indexing, angle wrapping, dropdown sync, str2num, method access |
| 🟢 Low | 5 | O(n²) plotters, figure validity, GUI gaps, ODE45 overhead, Env–Simulator sync |

Fix the three critical issues first so simulation and LQR control are correct; then address high and medium items for consistency and robustness.
