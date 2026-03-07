function c = draw_prop_speed_lines(time, c, p1)
% DRAW_PROP_SPEED_LINES Overlays velocity slopes on a t-x plot.
%
%   DRAW_PROP_SPEED_LINES(TIME, PROP_SPEED_KM_S, SPEED_LINE_POINTS)
%   calculates and plots a dashed line representing a specific propagation 
%   speed starting from a reference point.
%
%   Input Arguments:
%       time                - Time vector used for the X-axis [s].
%       c                   - Propagation speed [m/s].
%       p1                  - Anchor point for the speed line.
%
%   Notes:
%       The function uses 'w--' (white dashed) for the speed line.
%
%   See also: TEXT, GET_TIME_SPACE_PLOT

	parse_inputs(time, c, p1);

	x1 = p1(1);
	y1 = p1(2);

	prop_speed_line = y1 + c.*(time - x1);
    
	plot(time, prop_speed_line, 'w--', 'LineWidth', 1);
	prop_speed_txt = ['c = ', num2str(c), ' [m/s]  '];
	text(x1, y1, prop_speed_txt, 'Color', 'white', 'FontSize', 12, 'HorizontalAlignment','right');

	c = abs(c);
end
% -----------------------------------------------------------------------%

%% INPUT PARSING
function parse_inputs(time, c, p1)
	p = inputParser;
	
	% required parameters
	addRequired(p, 'time', @(x) isnumeric(x) && isvector(x) && all(x>=0));
	addRequired(p, 'c', @(x) isnumeric(x) && isscalar(x));
	addRequired(p, 'p1', @(x) isnumeric(x) && isvector(x));
	
	parse(p, time, c, p1);
end