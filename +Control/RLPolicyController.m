classdef RLPolicyController < Control.IController
    % RLPolicyController  Forwards a single action (e.g. from an RL agent). Set Action before each step.
    properties
        Action (1,1) double = 0
    end
    methods
        function u = computeControl(obj, ~, ~)
            u = obj.Action;
        end
    end
end
