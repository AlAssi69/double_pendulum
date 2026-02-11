classdef PlaybackSim < handle
    % PlaybackSim  Mock simulator for playback: exposes Time, CurrentState (interpolated), Model, Controller.
    % Used to drive existing visualizers from saved or in-memory time series at arbitrary playback time.

    properties
        Time (1,1) double = 0   % playback time (set each frame)
    end

    properties (Dependent)
        CurrentState (4,1) double
    end

    properties (SetAccess = immutable)
        Model      (1,1) Core.DoublePendulumModel
        Controller   % Control.PlaybackController; untyped to avoid default-construct (requires tVec, uVec)
    end

    properties (Access = private)
        tVec (:,1) double
        statesMat (:,4) double   % Nx4
    end

    methods
        function obj = PlaybackSim(results)
            % PlaybackSim(results)  results struct with .t, .states, .u, .params
            obj.tVec = results.t(:);
            obj.statesMat = results.states;
            if isfield(results, 'params')
                obj.Model = Core.DoublePendulumModel(results.params);
            else
                obj.Model = Core.DoublePendulumModel(struct('m1',1,'m2',1,'L1',1,'L2',1,'g',9.81,'beta1',0,'beta2',0));
            end
            obj.Controller = Control.PlaybackController(results.t, results.u);
        end

        function s = get.CurrentState(obj)
            if isempty(obj.tVec) || isempty(obj.statesMat)
                s = zeros(4, 1);
                return
            end
            s = interp1(obj.tVec, obj.statesMat, obj.Time, 'linear', 'extrap')';
        end
    end
end
