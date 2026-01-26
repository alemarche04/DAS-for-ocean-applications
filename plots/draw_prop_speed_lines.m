function draw_prop_speed_lines(time, prop_speed_km_s, speed_line_points, cpa_km, channel_position_km)

	parse_inputs(time, prop_speed_km_s, speed_line_points, cpa_km, channel_position_km);

	% propagation speed line
	c = prop_speed_km_s; % propagation speed [km/s]
	x_p = speed_line_points(1);
	y_p = speed_line_points(2);
	prop_speed_line = ( c .* (time - x_p) ) + y_p;
	plot(time, prop_speed_line, 'w--', 'LineWidth', 1);
	prop_speed_txt = ['c = ', num2str(c * 1e3), ' [m/s]  '];
	text(x_p, y_p, prop_speed_txt, 'Color', 'white', 'FontSize', 12, 'HorizontalAlignment','right');
	
	% position of interest
	yline(cpa_km, '--', 'CPA','LineWidth', 1, 'Color', '#FFD1DF');
	yline(channel_position_km, '--', 'far from CPA', 'LineWidth', 1, 'Color', '#D1FFBD');

end

% function for input validation
function parse_inputs(time, prop_speed_km_s, speed_line_points, cpa_km, channel_position_km)
	p = inputParser;
	
	% required parameters
	valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'nonnegative', 'vector'});
	addRequired(p, 'time', valid);

	valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'nonnegative', 'scalar'});
	addRequired(p, 'prop_speed_km_s', valid);
	
	valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'vector'});
	addRequired(p, 'speed_line_points', valid);
	
	valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'nonnegative', 'scalar'});
	addRequired(p, 'cpa_km', valid);
	addRequired(p, 'channel_position_km', valid);
	
	parse(p, time, prop_speed_km_s, speed_line_points, cpa_km, channel_position_km);
end
%