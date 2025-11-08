% Correlogram

% --- INPUT ---
% data : data matrix [channel x time sample]
% sampling_frequency : sampling frequency
% distance_m : : distance axis [m]
% channel_reference_position_km : reference channel distance [km]
% offset_xcorr : maximum offset [m]
% max_lag : maximum time lag [s]

function correlogram(data, sampling_frequency, distance_m, ...
    channel_reference_position_km, offset_xcorr, max_lag)

    max_lag_samples = round(max_lag * sampling_frequency);

    % closest channel to 44.2 km
    channel_position_m = channel_reference_position_km * 1e3;
    [~, channel_reference_idx] = min(abs(distance_m - channel_position_m)); % index of the closest channel to channel_reference_distance_km
    actual_channel_distance = distance_m(channel_reference_idx); % distance of the closest channel to channel_reference_distance_km
    channel_reference = data(channel_reference_idx, :);
    
    % channels in maximum offset range
    distance_from_reference_channel = abs(distance_m - actual_channel_distance);
    nearby_idx = find(distance_from_reference_channel <= offset_xcorr); % indexes of channels within max offset

    % create cross-correlation matrix
    nb_channels = length(nearby_idx); % number of channels within max offset
    nb_lags = 2 * max_lag_samples + 1;
    correlation_matrix = zeros(nb_channels, nb_lags);

    for i = 1:nb_channels
        current_channel_idx = nearby_idx(i);
        current_channel_data = data(current_channel_idx, :);
        [correlation_matrix(i, :), lags] = xcorr(channel_reference, current_channel_data, max_lag_samples);
    end

    time_lags = lags/sampling_frequency;
    offset_axis = distance_m(nearby_idx) - actual_channel_distance;
    
    figure;
    imagesc(time_lags, offset_axis, correlation_matrix);
    axis xy;
    colormap(redblue);
    xlim([-max_lag, max_lag]);
    ylim([-offset_xcorr offset_xcorr]);
    c = colorbar;
    ylabel(c, 'Correlation');
    
    ylabel('Distance from reference (m)');
    xlabel('Time lag (s)');
    title(sprintf('Cross-correlation (Ref: %.3f km, max offset: %d m)', ...
        actual_channel_distance .* 1e-3, offset_xcorr), 'FontSize', 16, 'FontWeight', 'bold');



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

end