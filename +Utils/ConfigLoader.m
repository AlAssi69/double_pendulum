classdef ConfigLoader
    % ConfigLoader  Central configuration for the double-pendulum project.
    % All default parameters live here. Call loadDefault() to get the full config struct.

    methods (Static)
        function config = loadDefault()
            % loadDefault()  Returns struct with every config/parameter used in the project.
            % Edit this file to change defaults; GUI (ConfigWindow) overrides only the fields it displays.

            config = struct();

            % --- Run / UI flags ---
            config.Debug  = true;   % Print config, setup, and full end summary to command window
            config.Visual = true;   % Show figures (animator, state plot, Poincaré map)

            % --- Random number generator ---
            config.RngSeed = 0;     % Set for reproducible runs (use [] to leave RNG unchanged)

            % --- Model parameters (physical) ---
            config.Params = struct( ...
                'm1', 1, ...       % mass of first bob (kg)
                'm2', 1, ...       % mass of second bob (kg)
                'L1', 1, ...       % length of first arm (m)
                'L2', 1, ...       % length of second arm (m)
                'g', 9.81, ...     % gravity (m/s^2)
                'beta1', 0, ...    % viscous damping at joint 1
                'beta2', 0 ...     % viscous damping at joint 2
            );

            % --- Simulation (initial state and time) ---
            config.InitialState = [pi/2; pi/2; 0; 0];   % [theta1; theta2; omega1; omega2]
            config.TimeSpan     = [0 10];               % [tStart, tEnd] in seconds

            % --- Simulator (solver) ---
            config.StepSize  = 0.005;   % Fixed step (s); smaller = smoother, slower
            config.SolverType = "rk4";  % "euler" | "rk4" | "ode45" (Integration package)

            % --- Control (LQR); only used when EnableControl is true ---
            config.EnableControl = false;
            config.Q = eye(4);   % State cost matrix (4x4)
            config.R = 1;        % Control cost scalar

            % --- Visualization (Poincaré map axes, angle display) ---
            config.PoincareXVar = "theta1";
            config.PoincareYVar = "theta2";
            config.AngleUnit = "radian";   % "radian" | "degree" for all GUIs and plots

            % --- Environment (RL / DoublePendulumEnv); used when creating env from config ---
            config.Env = struct( ...
                'StepSize', 0.02, ...
                'MaxTorque', 10, ...
                'GoalState', [0; 0; 0; 0], ...
                'MaxSteps', Inf ...
            );
        end
    end
end
