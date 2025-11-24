function fig = get_correlation_statistics(data, sampling_frequency, distance_m, channel_distance_m, ...
    channel_reference_position_km, offset_m, max_lag, time_interval)
% GET_CORRELATION_STATISTICS Compute and visualize correlation statistics of strain data
%
%   fig = GET_CORRELATION_STATISTICS(data, sampling_frequency, distance_m, 
%   channel_distance_m, channel_reference_position_km, offset_m, max_lag, 
%   time_interval, file_name) computes spatial and temporal correlation 
%   statistics for DAS strain data and generates visualization plots.
%
%   Inputs:
%       data                         - [channels x time] data matrix
%       sampling_frequency           - Sampling frequency (Hz)
%       distance_m                   - Distance axis vector (m)
%       channel_distance_m           - Spacing between adjacent channels (m)
%       channel_reference_position_km - Reference channel position (km)
%       offset_m                     - Maximum spatial offset for correlation (m)
%       max_lag                      - Maximum time lag for correlation (s)
%       time_interval                - [1x2] vector [start, end] time interval (s)
%
%   Output:
%       fig - Figure handle containing correlation statistics plots
%
%   Example:
%       % Compute correlation statistics for 1 km offset and 0.5s lag
%       fig = get_correlation_statistics(strain_data, 1000, distance, 10, ...
%                                        5.0, 1000, 0.5, [0 10], 'corr_stats');
%
%   See also XCORR, CORRCOEF

    % parse input parameters
    parse_inputs(data, sampling_frequency, distance_m, channel_distance_m, ...
        channel_reference_position_km, offset_m, max_lag, time_interval, file_name);
    %

    % signal in time interval
    t_start_idx = round(time_interval(1) * sampling_frequency);
    t_end_idx = round(time_interval(2) * sampling_frequency);
    data_corr = data(:, t_start_idx:t_end_idx);
    %

    % number of samples
    max_lag_samples = round(max_lag * sampling_frequency);
    %

    % closest channel to channel reference km
    channel_reference_position_m = channel_reference_position_km * 1e3;
    [~, channel_reference_idx] = min(abs(distance_m - channel_reference_position_m)); % index of the closest channel to channel_reference_position_km
    actual_channel_distance = distance_m(channel_reference_idx); % distance of the closest channel to channel_reference_position_km
    channel_reference = data_corr(channel_reference_idx, :);
    %
    
    % sets up subplots
    offset_step = 2; % calculates cross correlation every 2 channels (⁓8.16m)
    nb_subplots = 2 * round(offset_m/(offset_step * channel_distance_m)) + 1;
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
	try
        filename_statistics = evalin('caller', 'crossCorr.filename');
        fileID = fopen(filename_statistics,'w');
    catch
        warning('Unable to find name for correlation statistics file: used default file name correlation_statistics.txt');
		fileID = fopen('correlation_statistics.txt','w');
	end
    %
    
    % writes (auto)correlation result on txt file
    fprintf(fileID, "\n_____ Cross-Correlation Statistics _____\n");
    fprintf(fileID, "\nMax auto-correlation: %0.3f \n", max(auto_correlation));
    %

    for i = 1:(nb_subplots/2)
    
        % check on array limits
        idx_plus = channel_reference_idx + i * offset_step;
        idx_minus = channel_reference_idx - i * offset_step;
        
        if idx_plus > size(data_corr, 1) || idx_minus < 1
            break;
        end
        %
    
        % (cross)correlation with positive offset
        [x_corr1, lags_xcorr_1] = xcorr(channel_reference, data_corr((channel_reference_idx + i * offset_step), :), max_lag_samples);
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
        [x_corr2, lags_xcorr_2] = xcorr(channel_reference, data_corr((channel_reference_idx - i * offset_step), :), max_lag_samples);
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

    try
        time_and_date = evalin('caller', 'data.time_and_date');
        sgtitle({sprintf('Cross-correlation (Ref: %.3f km, max offset: %d m)', channel_reference_position_km, offset_m), ...
        sprintf('Signals duration: from %.2f s to %.2f s', time_interval), time_and_date});
    catch
        warning('Unable to create subtitle: time and date not found');
    end

end


% validates and parses input arguments
    function results = parse_inputs(data, sampling_frequency, distance_m, channel_distance_m, ...
    channel_reference_position_km, offset_m, max_lag, time_interval)
    p = inputParser;

    valid = @(x)validateattributes(x,{'numeric'},{'nonempty'});
    addRequired(p, 'data', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'positive', 'scalar'});
    addRequired(p, 'sampling_frequency', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'vector'});
    addRequired(p, 'distance_m', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'nonnegative', 'scalar'});
    addRequired(p, 'channel_distance_m', valid);
    addRequired(p, 'channel_reference_position_km', valid);
    addRequired(p, 'offset_m', valid);
    addRequired(p, 'max_lag', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'nonnegative', 'vector'});
    addRequired(p, 'time_interval', valid); 

    parse(p, data, sampling_frequency, distance_m, channel_distance_m, ...
    channel_reference_position_km, offset_m, max_lag, time_interval);

    results = p.Results;
    end
    %