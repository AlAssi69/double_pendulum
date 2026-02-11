classdef Simulator < handle
    % Simulator  Orchestrates simulation: holds model, controller, state, time.
    % step(dt, u) advances one fixed step using the configured Integration solver.
    % SolverType: "euler" | "rk4" | "ode45" (see Integration.SolverFactory).

    properties
        Model       (1,1) Core.DoublePendulumModel
        Controller  (1,1) Control.IController = Control.NullController()
        CurrentState (4,1) double = [0; 0; 0; 0]
        Time        (1,1) double = 0
        StepSize    (1,1) double = 0.02    % fixed step for run() and fixed-step solvers
        StepCount   (1,1) double = 0       % total steps in last run (for debugging)
        Debug       (1,1) logical = false  % if true, print solver info once at run start
    end

    properties (Dependent)
        SolverType  (1,1) string   % "euler" | "rk4" | "ode45"
    end

    properties (Access = private)
        SolverType_ (1,1) string = "rk4"   % backing store for SolverType
        Observers   = {}   % cell of listeners / callback handles
        Solver_     (1,1) Integration.ISolver = Integration.RK4Solver()  % integration engine (created from SolverType)
    end

    methods
        function obj = Simulator(model, controller)
            obj.Model = model;
            obj.Controller = controller;
            obj.Solver_ = Integration.SolverFactory.getSolver(obj.SolverType);
        end

        function val = get.SolverType(obj)
            val = obj.SolverType_;
        end

        function set.SolverType(obj, name)
            obj.SolverType_ = name;
            obj.Solver_ = Integration.SolverFactory.getSolver(name);
        end

        function attachObserver(obj, observer)
            % attachObserver(obj, observer)  observer can be handle with update(sim) or similar.
            obj.Observers{end+1} = observer;
        end

        function step(obj, dt, u)
            % step(obj, dt, u)  Advance by dt with constant torque u using current solver.
            obj.CurrentState = obj.Solver_.step(obj.Model, obj.CurrentState, u, dt);
            obj.Time = obj.Time + dt;
        end

        function run(obj, timeSpan)
            % run(obj, timeSpan)  Integrate from Time to timeSpan(2) using controller; notify observers each step.
            if obj.Debug
                fprintf('  Integration: %s (dt = %.6g s)\n', obj.SolverType, obj.StepSize);
            end
            tEnd = timeSpan(end);
            dt = obj.StepSize;
            obj.StepCount = 0;
            obj.notifyObservers();  % draw initial state
            while obj.Time < tEnd
                u = obj.Controller.computeControl(obj.Time, obj.CurrentState);
                stepDt = min(dt, tEnd - obj.Time);
                obj.step(stepDt, u);
                obj.StepCount = obj.StepCount + 1;
                obj.notifyObservers();
            end
        end

        function setState(obj, state, t)
            obj.CurrentState = state(:);
            if nargin >= 3
                obj.Time = t;
            end
        end
    end

    methods (Access = private)
        function notifyObservers(obj)
            for i = 1:numel(obj.Observers)
                obs = obj.Observers{i};
                if isobject(obs) && ismethod(obs, 'update')
                    obs.update(obj);
                elseif isa(obs, 'function_handle')
                    obs(obj);
                end
            end
        end
    end
end
