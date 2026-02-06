classdef Simulator < handle
    % Simulator  Orchestrates simulation: holds model, controller, state, time.
    % step(dt, u) advances one fixed step (RK4). run(timeSpan) runs with controller and notifies observers.

    properties
        Model       (1,1) Core.DoublePendulumModel
        Controller  (1,1) Control.IController = Control.NullController()
        CurrentState (4,1) double = [0; 0; 0; 0]
        Time        (1,1) double = 0
        SolverType  (1,1) string = "rk4"   % "rk4" or "ode45"
        StepSize    (1,1) double = 0.02    % used for run() fixed-step and for RK4
        StepCount   (1,1) double = 0       % total steps in last run (for debugging)
    end

    properties (Access = private)
        Observers   = {}   % cell of listeners / callback handles
    end

    methods
        function obj = Simulator(model, controller)
            obj.Model = model;
            obj.Controller = controller;
        end

        function attachObserver(obj, observer)
            % attachObserver(obj, observer)  observer can be handle with update(sim) or similar.
            obj.Observers{end+1} = observer;
        end

        function step(obj, dt, u)
            % step(obj, dt, u)  Advance by dt with constant torque u using RK4.
            x = obj.CurrentState;
            k1 = obj.Model.getDerivatives(x, u);
            k2 = obj.Model.getDerivatives(x + 0.5*dt*k1, u);
            k3 = obj.Model.getDerivatives(x + 0.5*dt*k2, u);
            k4 = obj.Model.getDerivatives(x + dt*k3, u);
            obj.CurrentState = x + (dt/6)*(k1 + 2*k2 + 2*k3 + k4);
            obj.Time = obj.Time + dt;
        end

        function run(obj, timeSpan)
            % run(obj, timeSpan)  Integrate from Time to timeSpan(2) using controller; notify observers each step.
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
