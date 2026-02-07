classdef DoublePendulumModel < handle
    % DoublePendulumModel  Full nonlinear double-pendulum dynamics via Euler-Lagrange.
    % State x = [theta1; theta2; theta1_dot; theta2_dot].
    % theta1 = angle of first arm from downward vertical.
    % theta2 = angle of second arm relative to the first (so second arm from vertical = theta1 + theta2).
    % Control u = scalar torque at shoulder (first joint) only.
    % Optional viscous damping at each joint.

    properties
        m1      (1,1) double {mustBePositive} = 1.0   % mass of first bob (kg)
        m2      (1,1) double {mustBePositive} = 1.0   % mass of second bob (kg)
        L1      (1,1) double {mustBePositive} = 1.0   % length of first arm (m)
        L2      (1,1) double {mustBePositive} = 1.0   % length of second arm (m)
        g       (1,1) double {mustBePositive} = 9.81 % gravity (m/s^2)
        beta1   (1,1) double {mustBeNonnegative} = 0  % viscous damping at joint 1
        beta2   (1,1) double {mustBeNonnegative} = 0  % viscous damping at joint 2
    end

    methods
        function obj = DoublePendulumModel(params)
            % DoublePendulumModel(params) or DoublePendulumModel() with defaults.
            if nargin >= 1 && isstruct(params)
                if isfield(params, 'm1'), obj.m1 = params.m1; end
                if isfield(params, 'm2'), obj.m2 = params.m2; end
                if isfield(params, 'L1'), obj.L1 = params.L1; end
                if isfield(params, 'L2'), obj.L2 = params.L2; end
                if isfield(params, 'g'),  obj.g  = params.g;  end
                if isfield(params, 'beta1'), obj.beta1 = params.beta1; end
                if isfield(params, 'beta2'), obj.beta2 = params.beta2; end
            end
        end

        function xdot = getDerivatives(obj, state, u)
            % xdot = getDerivatives(obj, state, u)
            % state = [theta1; theta2; theta1_dot; theta2_dot], u = shoulder torque.
            % Returns 4x1 state derivative (no small-angle approximation).
            if nargin < 3, u = 0; end
            u = double(u);
            th1 = state(1);
            th2 = state(2);
            w1  = state(3);
            w2  = state(4);

            m1 = obj.m1;
            m2 = obj.m2;
            L1 = obj.L1;
            L2 = obj.L2;
            g  = obj.g;
            b1 = obj.beta1;
            b2 = obj.beta2;

            % Mass matrix M (2x2) for [theta1_ddot; theta2_ddot]
            c2 = cos(th2);
            M11 = (m1 + m2)*L1^2 + m2*L2^2 + 2*m2*L1*L2*c2;
            M12 = m2*L2^2 + m2*L1*L2*c2;
            M21 = M12;
            M22 = m2*L2^2;
            M = [M11 M12; M21 M22];

            % Coriolis/centrifugal (from d/dt of partial L/partial theta_dot)
            s2 = sin(th2);
            C1 = 2*m2*L1*L2*s2*w2*w1 + m2*L1*L2*s2*w2^2;
            C2 = m2*L1*L2*s2*w1^2;

            % Gravity
            G1 = -g*L1*(m1 + m2)*sin(th1) - m2*g*L2*sin(th1 + th2);
            G2 = -m2*g*L2*sin(th1 + th2);

            % Damping and control: torque only at first joint
            tau = [u; 0] - [b1*w1; b2*w2];
            rhs = [C1 + G1; C2 + G2] + tau;

            theta_ddot = M \ rhs;
            xdot = [w1; w2; theta_ddot(1); theta_ddot(2)];
        end

        function [A, B] = linearizePoint(obj, equilibrium_state)
            % [A, B] = linearizePoint(obj, equilibrium_state)
            % Linearize at x_eq (4x1). Returns A (4x4), B (4x1) for dx = A*x + B*u
            % (with x relative to equilibrium if needed; here we use absolute x for simplicity).
            x_eq = equilibrium_state(:);
            u_eq = 0;
            eps = 1e-7;
            f0 = obj.getDerivatives(x_eq, u_eq);
            A = zeros(4, 4);
            for j = 1:4
                xp = x_eq;
                xp(j) = xp(j) + eps;
                A(:, j) = (obj.getDerivatives(xp, u_eq) - f0) / eps;
            end
            B = (obj.getDerivatives(x_eq, 1) - f0) / 1;
        end

        function E = totalEnergy(obj, state)
            % E = totalEnergy(obj, state)  Total mechanical energy (for validation).
            th1 = state(1);
            th2 = state(2);
            w1  = state(3);
            w2  = state(4);
            m1 = obj.m1;
            m2 = obj.m2;
            L1 = obj.L1;
            L2 = obj.L2;
            g  = obj.g;

            % Kinetic
            v1_sq = L1^2 * w1^2;
            v2_sq = L1^2*w1^2 + L2^2*(w1+w2)^2 + 2*L1*L2*cos(th2)*w1*(w1+w2);
            T = 0.5*m1*v1_sq + 0.5*m2*v2_sq;

            % Potential (y positive up: y1 = -L1*cos(th1), y2 = -L1*cos(th1)-L2*cos(th1+th2))
            V = -m1*g*L1*cos(th1) - m2*g*(L1*cos(th1) + L2*cos(th1+th2));
            E = T + V;
        end
    end
end
