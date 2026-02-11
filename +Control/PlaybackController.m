classdef PlaybackController < Control.IController
    % PlaybackController  Returns control u interpolated at current time from recorded series.
    % Used by PlaybackSim for smooth visualization from saved results.

    properties (Access = private)
        tVec (:,1) double
        uVec (:,1) double
    end

    methods
        function obj = PlaybackController(tVec, uVec)
            obj.tVec = tVec(:);
            obj.uVec = uVec(:);
        end

        function u = computeControl(obj, t, ~)
            if isempty(obj.tVec) || isempty(obj.uVec)
                u = 0;
                return
            end
            u = interp1(obj.tVec, obj.uVec, t, 'linear', 'extrap');
        end
    end
end
