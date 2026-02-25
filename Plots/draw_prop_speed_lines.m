function c = draw_prop_speed_lines(time, p1, p2, cpa_m, channel_position_m)
% DRAW_PROP_SPEED_LINES Overlays velocity slopes and position markers on a t-x plot.
%
%   DRAW_PROP_SPEED_LINES(TIME, PROP_SPEED_KM_S, SPEED_LINE_POINTS, CPA_KM, CHANNEL_POSITION_KM)
%   calculates and plots a dashed line representing a specific propagation 
%   speed starting from a reference point. It also marks horizontal lines 
%   for the Closest Point of Approach (CPA) and a secondary channel of interest.
%
%   Input Arguments:
%       time                - Time vector used for the X-axis [s].
%       prop_speed_m_s      - Target propagation speed [m/s].
%       p1, p2              - Anchor points for the speed line.
%       cpa_m               - Distance coordinate for the CPA marker [m].
%       channel_position_m  - Distance coordinate for the second marker [m].
%
%   Output Arguments:
%       c                   - Propagation speed [m/s].
%
%   Notes:
%       The function uses 'w--' (white dashed) for the speed line and 
%       hex-coded colors for the horizontal position markers.
%
%   See also: YLINE, TEXT, GET_TIME_SPACE_PLOT

	parse_inputs(time, p1, p2, cpa_m, channel_position_m);

	x1 = p1(1);
	y1 = p1(2);

	x2 = p2(1);
	y2 = p2(2);

	% m = (y2-y1)/(x2-x1)
	c = (y2 - y1)/(x2 - x1);
	prop_speed_line = c*time + (y1-c*x1);
    
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
function parse_inputs(time, p1, p2, cpa_m, channel_position_m)
	p = inputParser;
	
	% required parameters
	addRequired(p, 'time', @(x) isnumeric(x) && isvector(x) && all(x>=0));
	addRequired(p, 'p1', @(x) isnumeric(x) && isvector(x));
	addRequired(p, 'p2', @(x) isnumeric(x) && isvector(x));
	addRequired(p, 'cpa_m', @(x) isnumeric(x) && isscalar(x) && x>=0);
	addRequired(p, 'channel_position_m', @(x) isnumeric(x) && isscalar(x) && x>=0);
	
	parse(p, time, p1, p2, cpa_m, channel_position_m);
end