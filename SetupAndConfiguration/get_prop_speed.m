function c = get_prop_speed(p1, p2)
% GET_PROP_SPEED Compute propagation speed from two points on tx plot.
%
%   GET_PROP_SPEED(P1, P2) Calculates propagation speed of sound wave from
%   two point on the time-space plane
%
%   Input Arguments:
%       p1, p2              - Anchor points for the speed line.
%
%   Output Arguments:
%       c                   - Propagation speed [m/s].

	x1 = p1(1);
	y1 = p1(2);

	x2 = p2(1);
	y2 = p2(2);

	% m = (y2-y1)/(x2-x1)
	c = abs((y2 - y1)/(x2 - x1));
end