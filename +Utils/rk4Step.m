function xnext = rk4Step(model, state, u, dt)
% rk4Step(model, state, u, dt)  One RK4 step for model.getDerivatives(state, u).
x = state(:);
k1 = model.getDerivatives(x, u);
k2 = model.getDerivatives(x + 0.5*dt*k1, u);
k3 = model.getDerivatives(x + 0.5*dt*k2, u);
k4 = model.getDerivatives(x + dt*k3, u);
xnext = x + (dt/6)*(k1 + 2*k2 + 2*k3 + k4);
end
