%% Correlation statistics

% --- INPUT ---
% data : data matrix [channel x time sample]
% sampling_frequency : sampling frequency
% distance_m : : distance axis [m]
% channel_distance : distance between adjacent channels (m)
% channel_referece_distance_km : reference channel distance [km]
% offset_xcorr : maximum offset [m]
% max_lag : maximum time lag [s]
% time_start : start time of plot time interval [s]
% time_end : end time of plot time interval[s]
% file_name : name of output file

function fig = correlation_statistics(data, sampling_frequency, distance_m, channel_distance, ...
    channel_reference_distance_km, offset_xcorr, max_lag, time_start, time_end, file_name)

    % parse input parameters
    parse_inputs(data, sampling_frequency, distance_m, channel_distance, ...
        channel_reference_distance_km, offset_xcorr, max_lag, time_start, time_end, file_name);
    %

    % number of samples
    max_lag_samples = round(max_lag * sampling_frequency);
    %

    % closest channel to channel reference km
    channel_distance_m = channel_reference_distance_km * 1e3;
    [~, channel_reference_idx] = min(abs(distance_m - channel_distance_m)); % index of the closest channel to channel_reference_distance_km
    actual_channel_distance = distance_m(channel_reference_idx); % distance of the closest channel to channel_reference_distance_km
    channel_reference = data(channel_reference_idx, :);
    %
    
    % sets up subplots
    offset_step = 2; % calculates cross correlation every 2 channels (⁓8.16m)
    nb_subplots = 2 * round(offset_xcorr/(offset_step * channel_distance)) + 1;
    nb_columns = floor(sqrt(nb_subplots));
    nb_rows = ceil(nb_subplots / nb_columns);
    %

    % open figure
    fig = figure('units','normalized','outerposition',[0 0 1 1]);
    t = tiledlayout(nb_rows,nb_columns,'TileSpacing','Compact', 'Padding', 'compact');
    %

    % (auto)correlation of refernce channel signal
    [auto_correlation, lags_auto] = xcorr(channel_reference, max_lag_samples);
    auto_time_lags = lags_auto/sampling_frequency;
    %

    % parameters for plot scaling
    min_correlation = min(auto_correlation);
    min_correlation = min_correlation + min_correlation/2;

    max_correlation = max(auto_correlation);
    max_correlation = max_correlation + max_correlation/2;
    %

    % plot auto-correlation
    nexttile
    plot(auto_time_lags, auto_correlation);
    ylim([min_correlation max_correlation]);
    xlabel('Time lag (s)');
    %ylabel('Auto-correlation');
    title('Auto-correlation');
    %

    % opens text file with correlation results
    fileID = fopen(file_name,'w');
    %
    
    % writes (auto)correlation result on txt file
    fprintf(fileID, "\n_____ Cross-Correlation Statistics _____\n");
    fprintf(fileID, "\nMax auto-correlation: %0.3f \n", max(auto_correlation));
    %

    for i = 1:(nb_subplots/2)
    
        % check on array limits
        idx_plus = channel_reference_idx + i * offset_step;
        idx_minus = channel_reference_idx - i * offset_step;
        
        if idx_plus > size(data, 1) || idx_minus < 1
            break;
        end
        %
    
        % (cross)correlation with positive offset
        [x_corr1, lags_xcorr_1] = xcorr(channel_reference, data((channel_reference_idx + i * offset_step), :), max_lag_samples);
        time_lags_xcorr_1 = lags_xcorr_1 / sampling_frequency;
        %

        % plot result 
        nexttile
        plot(time_lags_xcorr_1, x_corr1);
        ylim([min_correlation max_correlation]);
        %ylabel('Correlation');
        xlabel('Time lag (s)');
        title(sprintf('Δx= %0.2f m', distance_m(channel_reference_idx + i * offset_step) - actual_channel_distance));
        %

        % writes (cross)correlation result on txt file
        [max_xcorr1, max_xcorr1_idx] = max(x_corr1);
        fprintf(fileID, "\nMax correlation at offset %0.2f m: %0.3d \n", ...
            (distance_m(channel_reference_idx + i * offset_step) - actual_channel_distance), max_xcorr1);
        fprintf(fileID, "at time lag %0.5f s\n", time_lags_xcorr_1(max_xcorr1_idx));
        %
        

        % (cross)correlation with positive offset
        [x_corr2, lags_xcorr_2] = xcorr(channel_reference, data((channel_reference_idx - i * offset_step), :), max_lag_samples);
        time_lags_xcorr_2 = lags_xcorr_2 / sampling_frequency;
        %

        % plot result 
        nexttile
        plot(time_lags_xcorr_2, x_corr2);
        ylim([min_correlation max_correlation]);
        %ylabel('Correlation');
        xlabel('Time lag (s)');
        title(sprintf('Δx= %0.2f m', distance_m(channel_reference_idx - i * offset_step) - actual_channel_distance));
        %

        % writes (cross)correlation result on txt file
        [max_xcorr2, max_xcorr2_idx] = max(x_corr2);
        fprintf(fileID, "\nMax correlation at offset %0.2f m: %0.3d \n", ...
            (distance_m(channel_reference_idx - i * offset_step) - actual_channel_distance), max_xcorr2);
        fprintf(fileID, "at time lag %0.5f s\n", time_lags_xcorr_2(max_xcorr2_idx));
        %

    end

    fclose(fileID);

end


% validates and parses input arguments
    function results = parse_inputs(data, sampling_frequency, distance_m, channel_distance, ...
    channel_reference_distance_km, offset_xcorr, max_lag, time_start, time_end, file_name)
    p = inputParser;

    valid = @(x)validateattributes(x,{'numeric'},{'nonempty'});
    addRequired(p, 'data', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'positive', 'scalar'});
    addRequired(p, 'sampling_frequency', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'vector'});
    addRequired(p, 'distance_m', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'nonnegative', 'scalar'});
    addRequired(p, 'channel_distance', valid);
    addRequired(p, 'channel_reference_position_km', valid);
    addRequired(p, 'offset_xcorr', valid);
    addRequired(p, 'max_lag', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'nonnegative', 'scalar'});
    addRequired(p, 'time_start', valid);
    addRequired(p, 'time_end', valid);

    valid = @(x) ~isempty(x) & isstring(x) || ischar(x) || iscell(c);
    addRequired(p, 'file_name', valid);    

    parse(p, data, sampling_frequency, distance_m, channel_distance, ...
    channel_reference_distance_km, offset_xcorr, max_lag, time_start, time_end, file_name);

    results = p.Results;
    end
    %