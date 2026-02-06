classdef SolverFactory
    % SolverFactory  Creates integration solvers by name for seamless engine switching.

    methods (Static)
        function s = getSolver(name)
            % s = getSolver(name)  Returns an Integration.ISolver for the given name.
            % name: "euler" | "rk4" | "ode45" (case-insensitive).
            n = lower(string(name));
            switch n
                case "euler"
                    s = Integration.EulerSolver();
                case "rk4"
                    s = Integration.RK4Solver();
                case "ode45"
                    s = Integration.ODE45Solver();
                otherwise
                    error("Integration:SolverFactory:UnknownSolver", ...
                        "Unknown solver '%s'. Use 'euler', 'rk4', or 'ode45'.", char(name));
            end
        end
    end
end
