classdef NullController < Control.IController
    % NullController  No control: u = 0 always.
    methods
        function u = computeControl(~, ~, ~)
            u = 0;
        end
    end
end
