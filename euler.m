function next_state = euler(current_state, action, params)
% EULER - Simple Euler integration for speed in RL training
%
% Inputs:
%   current_state - Current state vector [p; p_dot; theta; theta_dot]
%   action - Control input (force)
%   params - System parameters structure
%
% Outputs:
%   next_state - Next state after one time step
%
% Integration: x_new = x + dx * dt

dx = dynamics.cart_pole_dynamics(current_state, action, params);
next_state = current_state + dx * params.dt;

% Optional: Wrap angle to [-pi, pi] if needed
% next_state(3) = wrapToPi(next_state(3));
end