classdef ConfigLoader
    % ConfigLoader  Load default configuration for double-pendulum sim.
    methods (Static)
        function config = loadDefault()
            config = struct();
            config.Params = struct('m1', 1, 'm2', 1, 'L1', 1, 'L2', 1, 'g', 9.81, 'beta1', 0, 'beta2', 0);
            config.InitialState = [pi/2; pi/2; 0; 0];
            config.TimeSpan = [0 10];
            config.EnableControl = false;
            config.Q = eye(4);
            config.R = 1;
        end
    end
end
