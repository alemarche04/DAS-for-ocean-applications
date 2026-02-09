function draw_prop_speed_lines(time, prop_speed_km_s, speed_line_points, cpa_km, channel_position_km)
% DRAW_PROP_SPEED_LINES Overlays velocity slopes and position markers on a t-x plot.
%
%   DRAW_PROP_SPEED_LINES(TIME, PROP_SPEED_KM_S, SPEED_LINE_POINTS, CPA_KM, CHANNEL_POSITION_KM)
%   calculates and plots a dashed line representing a specific propagation 
%   speed starting from a reference point. It also marks horizontal lines 
%   for the Closest Point of Approach (CPA) and a secondary channel of interest.
%
%   Input Arguments:
%       time                - Time vector used for the X-axis [s].
%       prop_speed_km_s     - Target propagation speed [km/s].
%       speed_line_points   - 2-element vector [t0, x0] defining the anchor 
%                             point for the speed line.
%       cpa_km              - Distance coordinate for the CPA marker [km].
%       channel_position_km - Distance coordinate for the second marker [km].
%
%   Notes:
%       The function uses 'w--' (white dashed) for the speed line and 
%       hex-coded colors for the horizontal position markers.
%
%   See also: YLINE, TEXT, GET_TIME_SPACE_PLOT

	parse_inputs(time, prop_speed_km_s, speed_line_points, cpa_km, channel_position_km);
    
	% propagation speed line
	c = prop_speed_km_s; % propagation speed [km/s]
	x_p = speed_line_points(1);
	y_p = speed_line_points(2);
    
    % Linear equation: distance = c*(t - t0) + d0
	prop_speed_line = ( c .* (time - x_p) ) + y_p;
    
	plot(time, prop_speed_line, 'w--', 'LineWidth', 1);
	prop_speed_txt = ['c = ', num2str(c * 1e3), ' [m/s]  '];
	text(x_p, y_p, prop_speed_txt, 'Color', 'white', 'FontSize', 12, 'HorizontalAlignment','right');
	
	% position of interest markers
	yline(cpa_km, '--', 'CPA','LineWidth', 1, 'Color', '#FFD1DF');
	yline(channel_position_km, '--', 'far from CPA', 'LineWidth', 1, 'Color', '#D1FFBD');
end
% -----------------------------------------------------------------------%

%% INPUT PARSING
function parse_inputs(time, prop_speed_km_s, speed_line_points, cpa_km, channel_position_km)
	p = inputParser;
	
	% required parameters
	addRequired(p, 'time', @(x) isnumeric(x) && isvector(x) && all(x>=0));
	addRequired(p, 'prop_speed_km_s', @(x) isnumeric(x) && isscalar(x) && x>=0);
	addRequired(p, 'speed_line_points', @(x) isnumeric(x) && isvector(x));
	addRequired(p, 'cpa_km', @(x) isnumeric(x) && isscalar(x) && x>=0);
	addRequired(p, 'channel_position_km', @(x) isnumeric(x) && isscalar(x) && x>=0);
	
	parse(p, time, prop_speed_km_s, speed_line_points, cpa_km, channel_position_km);
end