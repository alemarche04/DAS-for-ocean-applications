function fig = get_strain_waveform(data, distance_km, time, channel_position_km, filename_audio, sampling_frequency_Hz, varargin)
% GET_STRAIN_WAVEFORM Plot strain waveform for a single channel
%
%   fig = GET_STRAIN_WAVEFORM(data, distance_km, time, channel_position_km) 
%   creates a time-domain waveform plot for a specified channel in the DAS data.
%
%   fig = GET_STRAIN_WAVEFORM(..., 'Name', Value) specifies optional
%   parameters using name-value pairs.
%
%   Inputs:
%       data                - [channels x time] data matrix (dB scale)
%       distance_km         - Distance axis vector (km)
%       time                - Time axis vector (s)
%       channel_position_km - Position of target channel (km)
%
%   Optional Parameters:
%       'time_lim'   - [1x2] vector [tmin, tmax] time axis limits (s)
%       'strain_lim' - [1x2] vector [min, max] amplitude axis limits
%
%   Output:
%       fig - Figure handle containing strain waveform plot
%
%   Example:
%       % Plot waveform for channel at 5.2 km with custom time window
%       fig = get_strain_waveform(strain_data, distance, time_vector, 5.2, ...
%                                'time_lim', [10 20], 'strain_lim', [-5 5]);
%
%   See also GET_WATERFALL_PLOT, PLOT

    % validate input and set up optional parameters
    params = parse_inputs(data, distance_km, time, channel_position_km, varargin{:});

    time_lim = params.time_lim;
    strain_lim = params.strain_lim;
    %

	% extract the channel data for the specified position
    [~, channel_position_idx] = min(abs(distance_km - channel_position_km));
	channelData = data(channel_position_idx, :);
    
    % plot figure
    fig = figure;
    plot(time, channelData)
    xlabel('Time (s)', 'FontSize', 12);
    ylabel('Strain Amplitude', 'FontSize', 12);
    title('Strain Waveform', 'FontSize', 14, 'FontWeight', 'bold');

	try
        time_and_date = evalin('caller', 'data.time_and_date');
        subtitle({sprintf("Channel at km %.2f", channel_position_km), time_and_date}, "FontSize", 12);
    catch
        warning('Unable to create subtitle: time and date not found');
	end

    %
    
    % plot limits configuration
    if ~isempty(time_lim)
        xlim(time_lim);
    else
        xlim([time(1) time(end)]);
    end

    if ~isempty(strain_lim)
        ylim(strain_lim);
    end
    %

	% export audio file
	audiowrite(filename_audio, (channelData .* 1e9), round(sampling_frequency_Hz*3));
    

end


% function for input validation
    function results = parse_inputs(data, distance_km, time, channel_position_km, varargin)
    p = inputParser;

    % required parameters
    valid = @(x)validateattributes(x,{'numeric'},{'nonempty'});
    addRequired(p, 'data', valid);
	addRequired(p, 'distance_km', valid);

	valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'vector'});
    addRequired(p, 'time', valid);

	valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'nonnegative', 'scalar'});
    addRequired(p, 'channel_position_km', valid);    

	valid = @(x)validateattributes(x,{'char'},{'nonempty'});
    addRequired(p, 'filename_audio', valid); 

	valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'nonnegative', 'scalar'});
    addRequired(p, 'sampling_frequency_Hz', valid); 

    % optional parameters
    valid = @(x) isempty(x) || (isnumeric(x) && isvector(x) && all(x >= 0));
    addParameter(p, 'time_lim', [], valid);

    valid = @(x) isempty(x) || (isnumeric(x) && isvector(x));
    addParameter(p, 'strain_lim', [], valid);

    parse(p, data, distance_km, time, channel_position_km, varargin{:});

    results = p.Results;
    end
    %