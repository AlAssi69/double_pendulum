classdef (Abstract) IController < handle
    % IController  Abstract interface for controllers: u = computeControl(t, state).
    methods (Abstract)
        u = computeControl(obj, t, state)
    end
end
