function fig = get_time_space_plot(data, time, distance, varargin)
% GET_TIME_SPACE_PLOT Generate time-space (t-x) visualization of strain data
%
%   fig = GET_TIME_SPACE_PLOT(data, time, distance) creates a time-space 
%   domain plot showing strain variation across channels and time.
%
%   fig = GET_TIME_SPACE_PLOT(..., 'Name', Value) specifies optional
%   parameters using name-value pairs.
%
%   Inputs:
%       data     - [channels x time] data matrix (dB scale)
%       time     - Time axis vector (s)
%       distance - Distance axis vector (km)
%
%   Optional Parameters:
%       'time_lim'     - [1x2] vector [tmin, tmax] time axis limits (s)
%       'distance_lim' - [1x2] vector [dmin, dmax] distance axis limits (km)
%       'strain_lim'   - [1x2] vector [min, max] strain amplitude limits (dB)
%
%   Output:
%       fig - Figure handle containing time-space plot
%
%   Example:
%       % Create t-x plot with custom axes limits
%       fig = get_time_space_plot(strain_data, time_vector, distance, ...
%                                'time_lim', [0 30], 'distance_lim', [4 6], ...
%                                'strain_lim', [-100 -40]);
%
%   See also GET_WATERFALL_PLOT, IMAGESC, PCOLOR

    % validate input and set up optional parameters
    params = parse_inputs(data, time, distance, varargin{:});

    time_lim = params.time_lim;
    distance_lim = params.distance_lim;
    strain_lim = params.strain_lim;
    %

    % plot figure
    fig = figure;
    imagesc(time, distance, data);
    axis xy;
    colormap(parula);
    c = colorbar;
    title('Time-Space plot', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('Time (s)', 'FontSize', 12);
    ylabel('Distance (km)', 'FontSize', 12);
    c.Label.String = 'Strain (dB)';

	try
        time_and_date = evalin('caller', 'data.time_and_date');
        subtitle(time_and_date, "FontSize", 12);
    catch
        warning('Unable to create subtitle: time and date not found');
	end
    %

    % plot limits configuration
    if ~isempty(time_lim)
    xlim(time_lim);
    end

    if ~isempty(distance_lim)
    ylim(distance_lim);
    end

    if ~isempty(strain_lim)
        clim(strain_lim);
    end
    %

end


% function for input validation
function results = parse_inputs(data, time, distance, varargin)
	p = inputParser;
	
	% required parameters
	valid = @(x)validateattributes(x,{'numeric'},{'nonempty'});
	addRequired(p, 'data', valid);
	
	valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'vector'});
	addRequired(p, 'time', valid);
	
	valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'nonnegative', 'vector'});
	addRequired(p, 'distance', valid);
	
	% optional parameters
	valid = @(x) isempty(x) || (isnumeric(x) && isvector(x) && all(x >= 0));
	addParameter(p, 'time_lim', [], valid);
	addParameter(p, 'distance_lim', [], valid);
	
	valid = @(x) isempty(x) || (isnumeric(x) && isvector(x));
	addParameter(p, 'strain_lim', [], valid);
	
	parse(p, data, time, distance, varargin{:});
	
	results = p.Results;
end
%