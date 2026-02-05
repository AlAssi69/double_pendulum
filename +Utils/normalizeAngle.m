function a = normalizeAngle(a, center)
% normalizeAngle(a, center)  Wrap angle to [center-pi, center+pi). Default center = 0.
if nargin < 2, center = 0; end
a = mod(a - center + pi, 2*pi) + center - pi;
end
