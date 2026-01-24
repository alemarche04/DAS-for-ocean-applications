function [correlation_statistics, fig] = get_correlation_statistics(data, sampling_frequency, distance_m, channel_distance_m, ...
    channel_reference_position_km, offset_m, max_lag, time_interval, filename_xcorr_table)

    % parse input parameters
    parse_inputs(data, sampling_frequency, distance_m, channel_distance_m, ...
        channel_reference_position_km, offset_m, max_lag, time_interval);
    
    % signal in time interval
    t_start_idx = round(time_interval(1) * sampling_frequency);
    t_end_idx = round(time_interval(2) * sampling_frequency);
    data_corr = data(:, t_start_idx:t_end_idx);
    
    % number of samples
    max_lag_samples = round(max_lag * sampling_frequency);
    
    % closest channel to channel reference km
    channel_reference_position_m = channel_reference_position_km * 1e3;
    [~, channel_reference_idx] = min(abs(distance_m - channel_reference_position_m)); % index of the closest channel to channel_reference_position_km
    actual_channel_distance = distance_m(channel_reference_idx); % distance of the closest channel to channel_reference_position_km
    channel_reference = data_corr(channel_reference_idx, :);
        
    % sets up subplots
    offset_step = 2; % calculates cross correlation every 2 channels (⁓8.16m)
    nb_subplots = 2 * round(offset_m/(offset_step * channel_distance_m)) + 1;
    nb_columns = floor(sqrt(nb_subplots));
    nb_rows = ceil(nb_subplots / nb_columns);
    
    % open figure
    fig = figure('units','normalized','outerposition',[0 0 1 1]);
    t = tiledlayout(nb_rows,nb_columns,'TileSpacing','Compact', 'Padding', 'compact');
    
    % (auto)correlation of refernce channel signal
    [auto_correlation, lags_auto] = xcorr(channel_reference, max_lag_samples);
    auto_time_lags = lags_auto/sampling_frequency;
    
    % parameters for plot scaling
    min_correlation = min(auto_correlation);
    min_correlation = min_correlation + min_correlation/2;
    max_correlation = max(auto_correlation);
    max_correlation = max_correlation + max_correlation/2;
    
	% correlation statistics matrix
    correlation_statistics = zeros(nb_subplots, 3); % [offset, max_value, time]
	csv_position = 1;

	for i = (ceil(nb_subplots/2) -1):-1:1
    
        % check on array limits
        idx_plus = channel_reference_idx + i * offset_step;
        idx_minus = channel_reference_idx - i * offset_step;
        
        if idx_plus > size(data_corr, 1) || idx_minus < 1
            break;
        end
        
        % (cross)correlation with negative offset
        [x_corr2, lags_xcorr_2] = xcorr(channel_reference, data_corr((channel_reference_idx - i * offset_step), :), max_lag_samples);
        time_lags_xcorr_2 = lags_xcorr_2 / sampling_frequency;
        
        % plot result 
        nexttile
        plot(time_lags_xcorr_2, x_corr2);
        ylim([min_correlation max_correlation]);
        xlabel('Time lag (s)');
        title(sprintf('dx= %0.2f m', distance_m(channel_reference_idx - i * offset_step) - actual_channel_distance));

		% main lobe moving speed
		c = 1600;
		% time lag difference of main lobe
		lag_diff = (distance_m(channel_reference_idx - i * offset_step) - actual_channel_distance) / c;
		
		% get time indexes in interval of +-0.01 = main lobe amplitude
		time_min = max([(lag_diff - 0.01), time_lags_xcorr_2(1)]); 
		time_max = lag_diff + 0.01;

		% get cross-correlation peak in selected time interval
		time_idx = (time_lags_xcorr_2 >= time_min) & (time_lags_xcorr_2 <= time_max);
		hold on 
		xline(lag_diff, '-r');
		xline(time_min, '-b');
		xline(time_max, '-b');
		hold off

        % writes (cross)correlation result on txt file
		% extract data in selected time interval
        subset_data = x_corr2(time_idx);
        subset_lags = time_lags_xcorr_2(time_idx);
        [max_val, rel_idx] = max(subset_data);
        % save results
        correlation_statistics(csv_position, 1) = (distance_m(channel_reference_idx - i * offset_step) - actual_channel_distance);
        correlation_statistics(csv_position, 2) = max_val;
        correlation_statistics(csv_position, 3) = subset_lags(rel_idx);

		csv_position = csv_position + 1;
        
	end

	% plot auto-correlation
    nexttile
    plot(auto_time_lags, auto_correlation);
    ylim([min_correlation max_correlation]);
    xlabel('Time lag (s)');
    title('Auto-correlation');
    
    % writes (auto)correlation result on csv file
	[~, max_auto_correlation_idx] = max(auto_correlation);	
	correlation_statistics(csv_position, 1) = 0; % offset
	correlation_statistics(csv_position, 2) = auto_correlation(max_auto_correlation_idx);
	correlation_statistics(csv_position, 3) = auto_time_lags(max_auto_correlation_idx);
	csv_position = csv_position + 1;

	for i = 1:(ceil(nb_subplots/2) -1)
    
        % check on array limits
        idx_plus = channel_reference_idx + i * offset_step;
        idx_minus = channel_reference_idx - i * offset_step;
        
        if idx_plus > size(data_corr, 1) || idx_minus < 1
            break;
        end
            
        % (cross)correlation with positive offset
        [x_corr1, lags_xcorr_1] = xcorr(channel_reference, data_corr((channel_reference_idx + i * offset_step), :), max_lag_samples);
        time_lags_xcorr_1 = lags_xcorr_1 / sampling_frequency;
        
        % plot result 
        nexttile
        plot(time_lags_xcorr_1, x_corr1);
        ylim([min_correlation max_correlation]);
        xlabel('Time lag (s)');
        title(sprintf('dx= %0.2f m', distance_m(channel_reference_idx + i * offset_step) - actual_channel_distance));

		% main lobe moving speed
		c = 1770;
		% time lag difference of main lobe
		lag_diff = (distance_m(channel_reference_idx + i * offset_step) - actual_channel_distance) / c;

		% get time indexes in interval of +-0.01 = main lobe amplitude
		time_min =(lag_diff - 0.01);
		time_max = min([(lag_diff + 0.01), time_lags_xcorr_1(end)]);

		% get cross-correlation peak in selected time interval
		time_idx = (time_lags_xcorr_1 >= time_min) & (time_lags_xcorr_1 <= time_max);
		hold on 
		xline(lag_diff, '-r');
		xline(time_min, '-b');
		xline(time_max, '-b');
		hold off

		% writes (cross)correlation result on txt file
		% extract data in selected time interval
        subset_data = x_corr1(time_idx);
        subset_lags = time_lags_xcorr_1(time_idx);
        [max_val, rel_idx] = max(subset_data);
        % save results
        correlation_statistics(csv_position, 1) = (distance_m(channel_reference_idx + i * offset_step) - actual_channel_distance);
        correlation_statistics(csv_position, 2) = max_val;
        correlation_statistics(csv_position, 3) = subset_lags(rel_idx);
		csv_position = csv_position + 1;

        
	end

	correlation_table = array2table(correlation_statistics, ...
    	'VariableNames', {'Offset', 'Max_Value', 'Time'});
	
	writetable(correlation_table, filename_xcorr_table);
	fprintf('Events saved to: %s\n', filename_xcorr_table);

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

	valid = @(x)validateattributes(x,{'char'},{'nonempty'});
	addRequired(p, 'filename_xcorr_table', valid);
	
	parse(p, data, sampling_frequency, distance_m, channel_distance_m, ...
	channel_reference_position_km, offset_m, max_lag, time_interval);
	
	results = p.Results;
end