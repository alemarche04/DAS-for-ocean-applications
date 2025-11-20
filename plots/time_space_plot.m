% Time-space representation (t-x plot) of the strain data

% --- INPUT ---
% data : [channel x time sample] data matrix (dB scale)
% timestamp : time info
% distance_km : distance axis [km]

% --- OPTIONAL PARAMETERS ---
% time_start : start time of plot time interval [s]
% time_end : end time of plot time interval[s]
% distance_min : minimum plot distance [km]
% distance_max : maximum plot distance [km]
% strain_min : minimum plot strain (dB)
% strain_max : minimum plot strain (dB)

function fig = time_space_plot(data, time, distance, varargin)

    % validate input and set up optional parameters
    params = parse_inputs(data, time, distance, varargin{:});

    time_start = params.time_start;
    time_end = params.time_end;
    distance_min = params.distance_min;
    distance_max = params.distance_max;
    strain_min = params.strain_min;
    strain_max = params.strain_max;
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
    %

    % plot limits configuration
    if ~isempty(time_start) & ~isempty(time_end)
    xlim([time_start time_end]);
    end

    if ~isempty(distance_min) & ~isempty(distance_max)
    ylim([distance_min distance_max]);
    end

    if ~isempty(strain_min) & ~isempty(strain_max)
        clim([strain_min strain_max]);
    end
    %

end


% function for input validation
    function results = parse_inputs(data, time, distance, varargin)
    p = inputParser;

    valid = @(x)validateattributes(x,{'numeric'},{'nonempty'});
    addRequired(p, 'data', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'vector'});
    addRequired(p, 'time', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'nonnegative', 'vector'});
    addRequired(p, 'distance', valid);

    valid = @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 0);
    addParameter(p, 'time_start', [], valid);
    addParameter(p, 'time_end', [], valid);
    addParameter(p, 'distance_min', [], valid);
    addParameter(p, 'distance_max', [], valid);

    valid = @(x) isempty(x) || (isnumeric(x) && isscalar(x));
    addParameter(p, 'strain_min', [], valid);
    addParameter(p, 'strain_max', [], valid);

    parse(p, data, time, distance, varargin{:});


    results = p.Results;
    end
    %