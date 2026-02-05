% DoublePendulumSim main entry: config GUI, then run simulation with optional LQR control.

clc;
clear;
close all force;

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
sim.StepSize = 0.02;
sim.run(app.TimeSpan);
