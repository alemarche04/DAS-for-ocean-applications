function fig = get_correlogram(data, sampling_frequency, distance_m, ...
	channel_reference_position_km, offset_m, max_lag, time_interval, varargin)
% GET_CORRELOGRAM Computes and plots spatial cross-correlation (correlogram).
%
%   FIG = GET_CORRELOGRAM(DATA, SAMPLING_FREQUENCY, DISTANCE_M, ...
%          CHANNEL_REFERENCE_POSITION_KM, OFFSET_M, MAX_LAG, TIME_INTERVAL)
%   Selects a reference channel based on a km-position and correlates it 
%   with all channels within a specified offset range. The resulting 
%   correlogram highlights signal coherence and wave propagation slopes.
%
%   Input Arguments:
%       data                - 2D matrix of DAS data [channels x samples].
%       sampling_frequency  - System sampling rate [Hz].
%       distance_m          - Vector of spatial coordinates for channels [meters].
%       channel_reference_position_km - Target position for the reference [km].
%       offset_m            - Maximum distance from reference to correlate [m].
%       max_lag             - Maximum time lag for correlation [s].
%       time_interval       - 2-element vector [start end] for signal segment [s].
%
%   Optional Parameters (Name-Value Pairs):
%       'subtitle'          - Plot subtitle string (typically time and date)
%
%   Output Arguments:
%       fig                 - Handle to the generated figure.
%
%   Visualization:
%       Uses a 'Red-Blue' colormap where white typically represents zero 
%       correlation, emphasizing phase alignment.
%
%   See also: XCORR, IMAGESC, GET_TIME_SPACE_PLOT

    % validate input
    params = parse_inputs(data, sampling_frequency, distance_m, channel_reference_position_km, ...
        offset_m, max_lag, time_interval, varargin{:});

    % --- Signal Selection ---
    % ensure index is at least 1
    t_start_idx = max(1, round(time_interval(1) * sampling_frequency));
    t_end_idx = min(size(data, 2), round(time_interval(2) * sampling_frequency));
    data_corr = data(:, t_start_idx:t_end_idx);
    
    % calculate lag samples
    max_lag_samples = round(max_lag * sampling_frequency);
    
    % --- Reference Channel Selection ---
    channel_position_m = channel_reference_position_km * 1e3;
    [~, channel_reference_idx] = min(abs(distance_m - channel_position_m)); 
    actual_channel_distance = distance_m(channel_reference_idx); 
    channel_reference = data_corr(channel_reference_idx, :);
        
    % --- Spatial Subset Selection ---
    distance_from_reference_channel = abs(distance_m - actual_channel_distance);
    nearby_idx = find(distance_from_reference_channel <= offset_m); 
    
    % pre-allocate cross-correlation matrix
    nb_channels = length(nearby_idx);
    nb_lags = 2 * max_lag_samples + 1;
    correlation_matrix = zeros(nb_channels, nb_lags);
    
    % --- Computation ---
    % iterate through channels within the offset range
    for i = 1:nb_channels
        current_channel_idx = nearby_idx(i);
        current_channel_data = data_corr(current_channel_idx, :);
        % normalization is often useful here; currently using raw xcorr
        [correlation_matrix(i, :), lags] = xcorr(channel_reference, current_channel_data, max_lag_samples);
    end
    
    % axis Generation
    time_lags = lags/sampling_frequency;
    offset_axis = distance_m(nearby_idx) - actual_channel_distance;
        
    % --- Plotting ---
    fig = figure;
    imagesc(time_lags, offset_axis, correlation_matrix);
    axis xy;
    colormap(redblue);
    xlim([-max_lag, max_lag]);
    ylim([-offset_m offset_m]);
    c = colorbar;
    ylabel(c, 'Correlation Intensity'); 
    ylabel('Distance from reference (m)');
    xlabel('Time lag (s)');
    title(sprintf('Cross-correlation (Ref: %.3f km, max offset: %d m)', ...
        actual_channel_distance .* 1e-3, offset_m), 'FontSize', 14, 'FontWeight', 'bold');
	%
	% apply optional subtitle
	if ~isempty(params.subtitle)
		subtitle({sprintf('Signals duration: from %.2f s to %.2f s', time_interval), params.subtitle}, 'FontSize', 12);
	end
    %
end
% -----------------------------------------------------------------------%

%% INPUT PARSING
function results = parse_inputs(data, sampling_frequency, distance_m, channel_reference_position_km, ...
            offset_m, max_lag, time_interval, varargin)
    p = inputParser;

	% required parameters
    addRequired(p, 'data', @isnumeric);
    addRequired(p, 'sampling_frequency', @(x) isnumeric(x) && isscalar(x) && x>0);
    addRequired(p, 'distance_m', @(x) isnumeric(x) && isvector(x));
    addRequired(p, 'channel_reference_position_km', @(x) isnumeric(x) && isscalar(x) && x>=0);
    addRequired(p, 'offset_m', @(x) isnumeric(x) && isscalar(x) && x>=0);
    addRequired(p, 'max_lag', @(x) isnumeric(x) && isscalar(x) && x>=0 );
    addRequired(p, 'time_interval', @(x) isnumeric(x) && isvector(x) && all(x>=0));

	% optional parameters
	addParameter(p, 'subtitle', [], @(x) isempty(x) || ischar(x) || isstring(x));

    parse(p, data, sampling_frequency, distance_m, channel_reference_position_km, ...
        offset_m, max_lag, time_interval, varargin{:});
    results = p.Results;
end
% -----------------------------------------------------------------------%

%% COLORMAP
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