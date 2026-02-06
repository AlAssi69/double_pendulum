% DoublePendulumSim main entry: config GUI, then run simulation with optional LQR control.

clc;
clear;
close all force;

% Fix RNG seed for reproducible results
rng(0);

% 1. Default config and GUI
config = Utils.ConfigLoader.loadDefault();
app = UI.ConfigWindow(config);
waitfor(app.Fig);

% 2. Build model and controller
model = Core.DoublePendulumModel(app.Params);
if app.EnableControl
    ctrl = Control.LQRController(model, app.Q, app.R);
else
    ctrl = Control.NullController();
end

% 3. Visualization
vizManager = Vis.VisualizerManager();
vizManager.add(Vis.PendulumAnimator());
vizManager.add(Vis.StatePlotter());
vizManager.add(Vis.PoincareMap('XVar', 'theta1', 'YVar', 'theta2'));

% 4. Simulator and run
sim = Core.Simulator(model, ctrl);
sim.attachObserver(vizManager);
sim.setState(app.InitialState, 0);
sim.StepSize = 0.005;   % smaller step for smoother simulation
debugPrintConfig(app, model, ctrl);
debugPrintSimSetup(sim, app.TimeSpan);
sim.run(app.TimeSpan);
debugPrintSimEnd(sim);

%% -------------------------------------------------------------------------
%% Debug print helpers (clear, formatted)
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
    fprintf('  Control: %s\n', iif(app.EnableControl, 'LQR ON', 'OFF (null)'));
    if app.EnableControl
        fprintf('  LQR weights: Q = diag(...)  R = %.4g\n', app.R);
        fprintf('    (Q matrix 4x4 not printed; check ConfigWindow)\n');
    end
    fprintf('------------------------------------------------------------------------\n\n');
end

function debugPrintSimSetup(sim, timeSpan)
    fprintf('========================================================================\n');
    fprintf('  SIMULATION SETUP\n');
    fprintf('========================================================================\n');
    fprintf('  Solver: %s   Step size dt = %.6g s\n', sim.SolverType, sim.StepSize);
    fprintf('  Run: t = %.4g -> %.4g s   (approx %.0f steps)\n', ...
        timeSpan(1), timeSpan(end), (timeSpan(end) - timeSpan(1)) / sim.StepSize);
    fprintf('------------------------------------------------------------------------\n\n');
end

function debugPrintSimEnd(sim)
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
end

function out = iif(cond, a, b)
    if cond, out = a; else, out = b; end
end
