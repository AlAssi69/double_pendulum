classdef EulerSolver < Integration.ISolver
    % EulerSolver  Explicit Euler integration: x_new = x + dx*dt.
    % Fast, low accuracy; suitable for quick prototyping or RL with small dt.

    methods
        function xnext = step(obj, model, state, u, dt)
            x = state(:);
            xdot = model.getDerivatives(x, u);
            xnext = x + xdot * dt;
        end
    end
end
