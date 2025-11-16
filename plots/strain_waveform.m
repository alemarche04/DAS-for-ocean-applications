% Strain waveform of one single channel

% --- INPUT ---
% channel : signal of a single channel
% time : time axis [s]

% --- OPTIONAL PARAMETERS ---
% time_start : start time of plot time interval [s]
% time_end : end time of plot time interval[s]
% amplitude_min : lower y-axis (amplitute) limit
% amplitude_max : higher y-axis (amplitute) limit

function fig = strain_waveform(data, time, varargin)

    % validate input and set up optional parameters
    params = parse_inputs(data, time, varargin{:});

    time_start = params.time_start;
    time_end = params.time_end;
    amplitude_min = params.amplitude_min;
    amplitude_max = params.amplitude_max;
    %
    
    % plot figure
    fig = figure;
    plot(time, data)
    xlabel('Time (s)', 'FontSize', 12);
    ylabel('Strain Amplitude', 'FontSize', 12);
    title('Strain Waveform', 'FontSize', 14, 'FontWeight', 'bold');
    %
    
    % plot limits configuration
    if ~isempty(time_start) & ~isempty(time_end)
        xlim([time_start time_end]);
    end

    if ~isempty(amplitude_min) & ~isempty(amplitude_max)
        ylim([amplitude_min amplitude_max]);
    end
    %

    % function for input validation
    function results = parse_inputs(data, time, varargin)
    p = inputParser;

    valid = @(x)validateattributes(x,{'numeric'},{'nonempty'});
    addRequired(p, 'data', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'vector'});
    addRequired(p, 'time', valid);

    valid = @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 0);
    addParameter(p, 'time_start', [], valid);
    addParameter(p, 'time_end', [], valid);

    valid = @(x) isempty(x) || (isnumeric(x) && isscalar(x));
    addParameter(p, 'amplitude_min', [], valid);
    addParameter(p, 'amplitude_max', [], valid);

    parse(p, data, time, varargin{:});


    results = p.Results;
    end
    %

end