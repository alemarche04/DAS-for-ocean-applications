function fig = get_correlogram(data, sampling_frequency, distance_m, ...
	channel_reference_position_km, offset_m, max_lag, time_interval)
% GET_CORRELOGRAM Generate correlogram visualization of strain data
%
%   fig = GET_CORRELOGRAM(data, sampling_frequency, distance_m, 
%   channel_reference_position_km, offset_m, max_lag, time_interval) 
%   computes and visualizes the correlogram (cross-correlation as a function 
%   of spatial offset and time lag) for DAS strain data.
%
%   Inputs:
%       data                         - [channels x time] data matrix
%       sampling_frequency           - Sampling frequency (Hz)
%       distance_m                   - Distance axis vector (m)
%       channel_reference_position_km - Reference channel position (km)
%       offset_m                     - Maximum spatial offset for correlation (m)
%       max_lag                      - Maximum time lag for correlation (s)
%       time_interval                - [1x2] vector [start, end] time interval (s)
%
%   Output:
%       fig - Figure handle containing correlogram plot
%
%   Example:
%       % Generate correlogram for ±500m offset and ±0.2s lag
%       fig = get_correlogram(strain_data, 1000, distance, 5.0, ...
%                            500, 0.2, [10 20]);
%
%   See also GET_CORRELATION_STATISTICS, XCORR

    % validate input
    parse_inputs(data, sampling_frequency, distance_m, channel_reference_position_km, ...
        offset_m, max_lag, time_interval);

    % signal in time interval
    t_start_idx = round(time_interval(1) * sampling_frequency);
    t_end_idx = round(time_interval(2) * sampling_frequency);
    data_corr = data(:, t_start_idx:t_end_idx);
    
    % calculate lag samples
    max_lag_samples = round(max_lag * sampling_frequency);
    
    % get signal of closest channel to 44.2 km
    channel_position_m = channel_reference_position_km * 1e3;
    [~, channel_reference_idx] = min(abs(distance_m - channel_position_m)); % index of the closest channel to channel_reference_distance_km
    actual_channel_distance = distance_m(channel_reference_idx); % distance of the closest channel to channel_reference_distance_km
    channel_reference = data_corr(channel_reference_idx, :);
        
    % get indexes of channels in maximum offset range
    distance_from_reference_channel = abs(distance_m - actual_channel_distance);
    nearby_idx = find(distance_from_reference_channel <= offset_m); % indexes of channels within max offset
    
    % create cross-correlation matrix
    nb_channels = length(nearby_idx); % number of channels within max offset
    nb_lags = 2 * max_lag_samples + 1;
    correlation_matrix = zeros(nb_channels, nb_lags);
    
    % Compute cross-correlation for each channel
    for i = 1:nb_channels
        current_channel_idx = nearby_idx(i);
        current_channel_data = data_corr(current_channel_idx, :);
        [correlation_matrix(i, :), lags] = xcorr(channel_reference, current_channel_data, max_lag_samples);
    end
    
    % calculate axis
    time_lags = lags/sampling_frequency;
    offset_axis = distance_m(nearby_idx) - actual_channel_distance;
        
    % plot correlogram
    fig = figure;
    imagesc(time_lags, offset_axis, correlation_matrix);
    axis xy;
    colormap(redblue);
    xlim([-max_lag, max_lag]);
    ylim([-offset_m offset_m]);
    c = colorbar;
    ylabel(c, 'Correlation'); 
    ylabel('Distance from reference (m)');
    xlabel('Time lag (s)');
    title(sprintf('Cross-correlation (Ref: %.3f km, max offset: %d m)', ...
        actual_channel_distance .* 1e-3, offset_m), 'FontSize', 14, 'FontWeight', 'bold');

    try
        time_and_date = evalin('caller', 'data.time_and_date');
        subtitle({sprintf('Signals duration: from %.2f s to %.2f s', time_interval), time_and_date}, 'FontSize', 12);
    catch
        warning('Unable to create subtitle: time and date not found');
    end
    
end


% function for input validation
function results = parse_inputs(data, sampling_frequency, distance_m, channel_reference_position_km, ...
            offset_m, max_lag, time_interval)
    p = inputParser;

    valid = @(x)validateattributes(x,{'numeric'},{'nonempty'});
    addRequired(p, 'data', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'positive', 'scalar'});
    addRequired(p, 'sampling_frequency', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'vector'});
    addRequired(p, 'distance_m', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'nonnegative', 'scalar'});
    addRequired(p, 'channel_reference_position_km', valid);
    addRequired(p, 'offset_m', valid);
    addRequired(p, 'max_lag', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'nonnegative', 'vector'});
    addRequired(p, 'time_interval', valid);

    parse(p, data, sampling_frequency, distance_m, channel_reference_position_km, ...
        offset_m, max_lag, time_interval);

    results = p.Results;
end
    

% colormap function
function cmap = redblue(m)
    % Red Blue Colormap
    if nargin < 1
        m = size(get(gcf,'colormap'), 1);
    end
    
    if m == 1
        cmap = [1 1 1];
        return;
    end
    
    n_half = ceil(m/2);
    r_lower = linspace(0, 1, n_half)';
    g_lower = linspace(0, 1, n_half)';
    b_lower = ones(n_half, 1);
    
    n_upper = m - n_half;
    r_upper = ones(n_upper, 1);
    g_upper = linspace(1, 0, n_upper)';
    b_upper = linspace(1, 0, n_upper)';
    
    cmap = [r_lower, g_lower, b_lower; r_upper, g_upper, b_upper];
    
    cmap = cmap(1:m, :);
end