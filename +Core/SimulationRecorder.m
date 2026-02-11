classdef SimulationRecorder < handle
    % SimulationRecorder  Observer that records time, state, and control each step (no graphics).
    % Use getResults() after sim.run() to get time series for saving or playback.

    properties (Access = private)
        TList = []
        StatesList = []   % each row = one state [theta1, theta2, omega1, omega2]
        UList = []
    end

    methods
        function update(obj, sim)
            obj.TList(end+1, 1) = sim.Time;
            obj.StatesList(end+1, :) = sim.CurrentState(:)';
            u = sim.Controller.computeControl(sim.Time, sim.CurrentState);
            obj.UList(end+1, 1) = u;
        end

        function out = getResults(obj)
            % getResults()  Returns struct with t (Nx1), states (Nx4), u (Nx1).
            out = struct();
            out.t = obj.TList;
            out.states = obj.StatesList;
            out.u = obj.UList;
        end
    end
end
