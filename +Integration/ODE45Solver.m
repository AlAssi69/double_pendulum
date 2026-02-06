classdef ODE45Solver < Integration.ISolver
    % ODE45Solver  MATLAB ode45 for one step. High accuracy ("ground truth").

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
