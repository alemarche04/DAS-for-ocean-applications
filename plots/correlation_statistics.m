% Correlation statistics

% --- INPUT ---
% data : data matrix [channel x time sample]
% sampling_frequency : sampling frequency
% distance_m : : distance axis [m]
% channel_distance : distance between adjacent channels (m)
% channel_referece_distance_km : reference channel distance [km]
% offset_xcorr : maximum offset [m]
% max_lag : maximum time lag [s]
% file_name : name of output file

function correlation_statistics(data, sampling_frequency, distance_m, ...
    channel_distance, channel_reference_distance_km, offset_xcorr, max_lag, file_name)

    max_lag_samples = round(max_lag * sampling_frequency);

    % closest channel to channel reference km
    channel_distance_m = channel_reference_distance_km * 1e3;
    [~, channel_reference_idx] = min(abs(distance_m - channel_distance_m)); % index of the closest channel to channel_reference_distance_km
    actual_channel_distance = distance_m(channel_reference_idx); % distance of the closest channel to channel_reference_distance_km
    channel_reference = data(channel_reference_idx, :);
    
    % sets up subplots
    offset_step = 2; % calculates cross correlation every 2 channels
    nb_subplots = round(offset_xcorr/(offset_step * channel_distance));
    nb_columns = floor(sqrt(nb_subplots));
    nb_rows = ceil(nb_subplots / nb_columns);

    % open figure
    figure;
    t = tiledlayout(nb_rows,nb_columns,'TileSpacing','Compact', 'Padding', 'compact');

    % Calculate auto-correlation for the reference channel
    [auto_correlation, lags_auto] = xcorr(channel_reference, max_lag_samples);
    auto_time_lags = lags_auto/sampling_frequency;

    % parameters for plot scaling
    min_correlation = min(auto_correlation, [], "all");
    min_correlation = min_correlation + min_correlation/4;

    max_correlation = max(auto_correlation, [], "all");
    max_correlation = max_correlation + max_correlation/4;
    
    % Plot auto-correlation
    nexttile

    plot(auto_time_lags, auto_correlation);
    ylim([min_correlation max_correlation]);
    xlabel('Time lag (s)');
    ylabel('Auto-correlation');
    title({'Auto-correlation', sprintf('(Channel: %.3f km)', actual_channel_distance .* 1e-3)});


    fileID = fopen(file_name,'w');

    fprintf(fileID, "\n_____ Cross-Correlation Statistics _____\n");
    fprintf(fileID, "\nMax auto-correlation: %0.3d \n", max(auto_correlation, [], "all"));


    for i = 1:(nb_subplots/2)

        [x_corr1, lags_xcorr_1] = xcorr(data((channel_reference_idx + i * offset_step), :), channel_reference, max_lag_samples);
        time_lags_xcorr_1 = lags_xcorr_1 / sampling_frequency;

        nexttile

        plot(time_lags_xcorr_1, x_corr1);
        ylim([min_correlation max_correlation]);
        ylabel('Correlation');
        xlabel('Time lag (s)');
        title({'Cross-correlation' , ...
            sprintf('offset %0.2f m', distance_m(channel_reference_idx + i * offset_step) - actual_channel_distance)});


        [max_xcorr1, max_xcorr1_idx] = max(x_corr1, [], "all");
        fprintf(fileID, "\nMax correlation at offset %0.2f m: %0.3d \n", ...
            (distance_m(channel_reference_idx + i * offset_step) - actual_channel_distance), max_xcorr1);
        fprintf(fileID, "at time lag %0.5f s\n", time_lags_xcorr_1(max_xcorr1_idx));


        [x_corr2, lags_xcorr_2] = xcorr(data((channel_reference_idx - i * offset_step), :), channel_reference, max_lag_samples);
        time_lags_xcorr_2 = lags_xcorr_2 / sampling_frequency;

        nexttile
        
        plot(time_lags_xcorr_2, x_corr2);
        ylim([min_correlation max_correlation]);
        ylabel('Correlation');
        xlabel('Time lag (s)');
        title({'Cross-correlation' , ...
            sprintf('offset %0.2f m', distance_m(channel_reference_idx - i * offset_step) - actual_channel_distance)});

        [max_xcorr2, max_xcorr2_idx] = max(x_corr2, [], "all");
        fprintf(fileID, "\nMax correlation at offset %0.2f m: %0.3d \n", ...
            (distance_m(channel_reference_idx - i * offset_step) - actual_channel_distance), max_xcorr2);
        fprintf(fileID, "at time lag %0.5f s\n", time_lags_xcorr_2(max_xcorr2_idx));

    end

    fclose(fileID);

end