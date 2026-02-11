classdef ODE45Solver < Integration.ISolver
    % ODE45Solver  MATLAB ode45 for one step. High accuracy ("ground truth").
    %
    % NOTE: Each call to step() creates a new function handle, options struct,
    % and invokes ode45 from scratch. This per-step overhead is a known
    % trade-off of the pluggable fixed-step solver API. For long simulations
    % where performance matters, consider using RK4Solver instead. A "batch"
    % mode that runs ode45 once over the full time span could be added as a
    % future optimization if needed.

    methods
        function xnext = step(obj, model, state, u, dt)
            tspan = [0, dt];
            ode_fun = @(t, x) model.getDerivatives(x, u);
            options = odeset('RelTol', 1e-6, 'AbsTol', 1e-6);
            [~, x_trajectory] = ode45(ode_fun, tspan, state(:), options);
            xnext = x_trajectory(end, :)';
        end
    end
end
