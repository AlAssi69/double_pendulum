classdef ISolver < handle
    % ISolver  Abstract interface for ODE integration (one step).
    % Any concrete solver must implement step(model, state, u, dt).
    % model must provide getDerivatives(state, u) returning state derivative.

    methods (Abstract)
        xnext = step(obj, model, state, u, dt)
        % xnext = step(obj, model, state, u, dt)
        % Advance state by one time step dt with constant control u.
        % model: object with getDerivatives(state, u)
        % state: current state vector (e.g. 4x1)
        % u: control input (scalar or vector)
        % dt: time step (scalar)
        % xnext: state after one step (same size as state)
    end
end
