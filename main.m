% DoublePendulumSim main entry: config GUI, then run simulation with optional LQR control.
% All configuration defaults are in Utils.ConfigLoader.loadDefault().

clc;
clear;
close all force;

% 1. Load central config (single source of parameters)
config = Utils.ConfigLoader.loadDefault();
if ~isempty(config.RngSeed)
    rng(config.RngSeed);
end

% 2. Config GUI (edits Params, InitialState, TimeSpan, EnableControl, Q, R)
app = UI.ConfigWindow(config);
waitfor(app.Fig);

% 3. Build model and controller
model = Core.DoublePendulumModel(app.Params);
if app.EnableControl
    ctrl = Control.LQRController(model, app.Q, app.R);
else
    ctrl = Control.NullController();
end

% 4. Visualization (only when config.Visual is on)
if config.Visual
    vizManager = Vis.VisualizerManager();
    vizManager.add(Vis.PendulumAnimator());
    vizManager.add(Vis.StatePlotter());
    vizManager.add(Vis.PoincareMap('XVar', config.PoincareXVar, 'YVar', config.PoincareYVar));
end

% 5. Simulator and run (solver and step size from config GUI)
sim = Core.Simulator(model, ctrl);
sim.StepSize = app.StepSize;
sim.SolverType = app.SolverType;
sim.Debug = config.Debug;
if config.Visual
    sim.attachObserver(vizManager);
end
sim.setState(app.InitialState, 0);

if config.Debug
    debugPrintConfig(app, model, ctrl);
    debugPrintSimSetup(app);
end
sim.run(app.TimeSpan);
debugPrintEnd(sim, config.Debug, config.Visual);

%% -------------------------------------------------------------------------
%% Debug / summary print helpers
%% -------------------------------------------------------------------------
function debugPrintConfig(app, model, ctrl)
    fprintf('\n');
    fprintf('========================================================================\n');
    fprintf('  CONFIGURATION\n');
    fprintf('========================================================================\n');
    fprintf('  Model parameters:\n');
    fprintf('    m1 = %.4g kg   m2 = %.4g kg   L1 = %.4g m   L2 = %.4g m\n', ...
        model.m1, model.m2, model.L1, model.L2);
    fprintf('    g = %.4g m/s^2   beta1 = %.4g   beta2 = %.4g\n', ...
        model.g, model.beta1, model.beta2);
    fprintf('  Initial state: [theta1, theta2, omega1, omega2] =\n');
    fprintf('    [ %.6g, %.6g, %.6g, %.6g ] rad, rad, rad/s, rad/s\n', ...
        app.InitialState(1), app.InitialState(2), app.InitialState(3), app.InitialState(4));
    fprintf('  Time span: [ %.4g, %.4g ] s\n', app.TimeSpan(1), app.TimeSpan(2));
    fprintf('  Solver: %s   Step size dt = %.6g s\n', app.SolverType, app.StepSize);
    fprintf('  Control: %s\n', iif(app.EnableControl, 'LQR ON', 'OFF (null)'));
    if app.EnableControl
        fprintf('  LQR weights: Q = diag(...)  R = %.4g\n', app.R);
        fprintf('    (Q matrix 4x4 not printed; check ConfigWindow)\n');
    end
    fprintf('------------------------------------------------------------------------\n\n');
end

function debugPrintSimSetup(app)
    % Print the exact config values used for the run (from GUI / app).
    fprintf('========================================================================\n');
    fprintf('  SIMULATION SETUP\n');
    fprintf('========================================================================\n');
    fprintf('  Solver: %s   Step size dt = %.6g s\n', app.SolverType, app.StepSize);
    t0 = app.TimeSpan(1);
    tEnd = app.TimeSpan(end);
    fprintf('  Run: t = %.4g -> %.4g s', t0, tEnd);
    if app.StepSize > 0 && numel(app.TimeSpan) >= 2
        nSteps = (tEnd - t0) / app.StepSize;
        fprintf('   (approx %.0f steps)\n', nSteps);
    else
        fprintf('\n');
    end
    fprintf('------------------------------------------------------------------------\n\n');
end

% Print at end of run: full block if DEBUG; else one-line summary only when no visualization
function debugPrintEnd(sim, debug, visual)
    if debug
        fprintf('\n');
        fprintf('========================================================================\n');
        fprintf('  SIMULATION COMPLETE\n');
        fprintf('========================================================================\n');
        fprintf('  Final time t = %.6g s\n', sim.Time);
        fprintf('  Final state: [theta1, theta2, omega1, omega2] =\n');
        fprintf('    [ %.6g, %.6g, %.6g, %.6g ]\n', ...
            sim.CurrentState(1), sim.CurrentState(2), sim.CurrentState(3), sim.CurrentState(4));
        fprintf('  Total steps: %d\n', sim.StepCount);
        fprintf('========================================================================\n\n');
    elseif ~visual
        % No visualization: give minimal feedback so user knows run finished
        x = sim.CurrentState;
        fprintf('Simulation complete: t = %.4g s, %d steps. Final state [th1, th2, om1, om2] = [%.4g, %.4g, %.4g, %.4g]\n', ...
            sim.Time, sim.StepCount, x(1), x(2), x(3), x(4));
    end
end

function out = iif(cond, a, b)
    if cond, out = a; else, out = b; end
end
