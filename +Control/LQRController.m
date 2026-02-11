classdef LQRController < Control.IController
    % LQRController  u = -K*(x - x_ref) with K from continuous-time LQR at equilibrium.

    properties
        K       (1,4) double   % gain matrix (row vector for u = -K*x)
        x_ref   (4,1) double   % reference state (default upright)
    end

    methods
        function obj = LQRController(model, Q, R)
            % LQRController(model, Q, R)  Q 4x4, R scalar. Linearize at upright equilibrium.
            if nargin < 2, Q = eye(4); end
            if nargin < 3, R = 1; end
            x_eq = [pi; 0; 0; 0];
            [A, B] = model.linearizePoint(x_eq);
            [K, ~, ~] = lqr(A, B, Q, R);
            obj.K = K;  % row vector so u = -K*(x - x_ref)
            obj.x_ref = x_eq;
        end

        function u = computeControl(obj, ~, state)
            x = state(:);
            u = -obj.K * (x - obj.x_ref);
        end
    end
end
