function [correlation_statistics, fig] = get_correlation_statistics( ...
	data, sampling_frequency, distance_m, channel_distance_m, ...
    channel_reference_position_km, offset_m, max_lag, time_interval, filename_xcorr_table)

    % parse input parameters
    parse_inputs(data, sampling_frequency, distance_m, channel_distance_m, ...
        channel_reference_position_km, offset_m, max_lag, time_interval, filename_xcorr_table);
    
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
        [xcorr_negative_offset, lags_xcorr_negative_offset] = xcorr(channel_reference, data_corr((channel_reference_idx - i * offset_step), :), max_lag_samples);
        time_lags_xcorr_negative_offset = lags_xcorr_negative_offset / sampling_frequency;
		offset_from_reference = distance_m(channel_reference_idx - i * offset_step) - actual_channel_distance;
        
        % plot result 
        nexttile
        plot(time_lags_xcorr_negative_offset, xcorr_negative_offset);
        ylim([min_correlation max_correlation]);
        xlabel('Time lag (s)');
        title(sprintf('dx= %0.2f m', offset_from_reference));

        [max_val, rel_idx] = max(abs(xcorr_negative_offset));
		hold on
		xline(time_lags_xcorr_negative_offset(rel_idx), '-r');
		hold off
		
        % save results
        correlation_statistics(csv_position, 1) = offset_from_reference;
        correlation_statistics(csv_position, 2) = max_val;
        correlation_statistics(csv_position, 3) = time_lags_xcorr_negative_offset(rel_idx);

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
        [xcorr_positive_offset, lags_xcorr_positive_offset] = xcorr(channel_reference, data_corr((channel_reference_idx + i * offset_step), :), max_lag_samples);
        time_lags_xcorr_positive_offset = lags_xcorr_positive_offset / sampling_frequency;
		offset_from_reference = distance_m(channel_reference_idx + i * offset_step) - actual_channel_distance;
        
        % plot result 
        nexttile
        plot(time_lags_xcorr_positive_offset, xcorr_positive_offset);
        ylim([min_correlation max_correlation]);
        xlabel('Time lag (s)');
        title(sprintf('dx= %0.2f m', offset_from_reference));
   
        [max_val, rel_idx] = max(abs(xcorr_positive_offset));
		hold on
		xline(time_lags_xcorr_positive_offset(rel_idx), '-r');
		hold off

        % save results
        correlation_statistics(csv_position, 1) = offset_from_reference;
        correlation_statistics(csv_position, 2) = max_val;
        correlation_statistics(csv_position, 3) = time_lags_xcorr_positive_offset(rel_idx);
		csv_position = csv_position + 1;
        
	end

	correlation_table = array2table(correlation_statistics, ...
    	'VariableNames', {'Offset', 'Peak value', 'Time'});
	
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
	channel_reference_position_km, offset_m, max_lag, time_interval, filename_xcorr_table)
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
	channel_reference_position_km, offset_m, max_lag, time_interval, filename_xcorr_table);
	
	results = p.Results;
end