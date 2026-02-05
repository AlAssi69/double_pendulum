classdef DoublePendulumEnv < handle
    % DoublePendulumEnv  RL-friendly interface: reset(), step(action), reward and bounds.
    % State x = [theta1; theta2; theta1_dot; theta2_dot]. Action u = scalar torque (clipped).

    properties
        Model       (1,1) Core.DoublePendulumModel
        State       (4,1) double
        Time        (1,1) double = 0
        StepSize    (1,1) double = 0.02
        MaxTorque   (1,1) double = 10
        GoalState   (4,1) double = [0; 0; 0; 0]
        Q           (4,4) double = eye(4)
        R           (1,1) double = 0.01
        MaxSteps    (1,1) double = Inf
        StepCount   (1,1) double = 0
    end

    properties (Access = private)
        Simulator   (1,1) Core.Simulator
    end

    methods
        function obj = DoublePendulumEnv(model, opts)
            % DoublePendulumEnv(model) or DoublePendulumEnv(model, opts)
            % opts: StepSize, MaxTorque, GoalState, Q, R, MaxSteps, InitialState
            obj.Model = model;
            obj.Simulator = Core.Simulator(model, Control.NullController());
            obj.State = [0; 0; 0; 0];
            if nargin >= 2 && isstruct(opts)
                if isfield(opts, 'StepSize'),   obj.StepSize   = opts.StepSize; end
                if isfield(opts, 'MaxTorque'), obj.MaxTorque  = opts.MaxTorque; end
                if isfield(opts, 'GoalState'), obj.GoalState  = opts.GoalState(:); end
                if isfield(opts, 'Q'),         obj.Q          = opts.Q; end
                if isfield(opts, 'R'),         obj.R          = opts.R; end
                if isfield(opts, 'MaxSteps'),  obj.MaxSteps   = opts.MaxSteps; end
                if isfield(opts, 'InitialState'), obj.State   = opts.InitialState(:); end
            end
        end

        function [state, info] = reset(obj, initial_state)
            % [state, info] = reset(obj) or reset(obj, initial_state)
            if nargin >= 2 && ~isempty(initial_state)
                obj.State = initial_state(:);
            else
                obj.State = [0; 0; 0; 0];
            end
            obj.Time = 0;
            obj.StepCount = 0;
            state = obj.State;
            info = struct('time', obj.Time);
        end

        function [next_state, reward, done, info] = step(obj, action)
            % [next_state, reward, done, info] = step(obj, action)
            % action = scalar torque; clipped to [-MaxTorque, MaxTorque].
            u = max(-obj.MaxTorque, min(obj.MaxTorque, action));
            obj.Simulator.setState(obj.State, obj.Time);
            obj.Simulator.step(obj.StepSize, u);
            obj.State = obj.Simulator.CurrentState;
            obj.Time = obj.Simulator.Time;
            obj.StepCount = obj.StepCount + 1;

            next_state = obj.State;
            err = next_state - obj.GoalState;
            reward = -(err' * obj.Q * err + obj.R * u^2);
            done = obj.StepCount >= obj.MaxSteps;
            info = struct('time', obj.Time, 'energy', obj.Model.totalEnergy(next_state));
        end

        function obs = getObservation(obj)
            % obs = getObservation(obj)  Same as state (4D). Optionally extend with cos/sin for wrap.
            obs = obj.State;
        end
    end
end
