function c = draw_prop_speed_lines(time, c, p1, cpa_m, channel_position_m)
% DRAW_PROP_SPEED_LINES Overlays velocity slopes and position markers on a t-x plot.
%
%   DRAW_PROP_SPEED_LINES(TIME, PROP_SPEED_KM_S, SPEED_LINE_POINTS, CPA_KM, CHANNEL_POSITION_KM)
%   calculates and plots a dashed line representing a specific propagation 
%   speed starting from a reference point. It also marks horizontal lines 
%   for the Closest Point of Approach (CPA) and a secondary channel of interest.
%
%   Input Arguments:
%       time                - Time vector used for the X-axis [s].
%       c                   - Propagation speed [m/s].
%       p1                  - Anchor point for the speed line.
%       cpa_m               - Distance coordinate for the CPA marker [m].
%       channel_position_m  - Distance coordinate for the second marker [m].
%
%   Notes:
%       The function uses 'w--' (white dashed) for the speed line and 
%       hex-coded colors for the horizontal position markers.
%
%   See also: YLINE, TEXT, GET_TIME_SPACE_PLOT

	parse_inputs(time, c, p1, cpa_m, channel_position_m);

	x1 = p1(1);
	y1 = p1(2);

	prop_speed_line = y1 + c.*(time - x1);
    
	plot(time, prop_speed_line, 'w--', 'LineWidth', 1);
	prop_speed_txt = ['c = ', num2str(c), ' [m/s]  '];
	text(x1, y1, prop_speed_txt, 'Color', 'white', 'FontSize', 12, 'HorizontalAlignment','right');
	
	% position of interest markers
	yline(cpa_m, '--', 'CPA','LineWidth', 1, 'Color', '#FFD1DF');
	yline(channel_position_m, '--', 'far from CPA', 'LineWidth', 1, 'Color', '#D1FFBD');

	c = abs(c);
end
% -----------------------------------------------------------------------%

%% INPUT PARSING
function parse_inputs(time, c, p1, cpa_m, channel_position_m)
	p = inputParser;
	
	% required parameters
	addRequired(p, 'time', @(x) isnumeric(x) && isvector(x) && all(x>=0));
	addRequired(p, 'c', @(x) isnumeric(x) && isscalar(x));
	addRequired(p, 'p1', @(x) isnumeric(x) && isvector(x));
	addRequired(p, 'cpa_m', @(x) isnumeric(x) && isscalar(x) && x>=0);
	addRequired(p, 'channel_position_m', @(x) isnumeric(x) && isscalar(x) && x>=0);
	
	parse(p, time, c, p1, cpa_m, channel_position_m);
end