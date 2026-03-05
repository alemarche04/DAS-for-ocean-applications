function [correlation_statistics, fig] = get_correlation_statistics( ...
	data, sampling_frequency, distance, channel_distance_m, ...
    channel_reference_position_m, offset_m, max_lag, time_interval, ...
	filename_xcorr_table, varargin)
% GET_CORRELATION_STATISTICS Quantifies cross-correlation peaks across the array.
%
%   [STATS, FIG] = GET_CORRELATION_STATISTICS(DATA, SAMPLING_FREQUENCY, ...) 
%   calculates the auto-correlation of a reference channel and the 
%   cross-correlation of surrounding channels at specific spatial steps. 
%   It identifies the time-lag of the maximum correlation peak for each 
%   channel and exports the results to a CSV table.
%
%   Input Arguments: 
%       data                 - 2D matrix of DAS data [channels x samples].
%       sampling_frequency   - System sampling rate [Hz].
%       distance             - Vector of spatial coordinates for channels [m].
%       channel_distance_m   - Nominal spacing between channels [m].
%       channel_reference_position_m - Target position for the reference [m].
%       offset_m             - Maximum distance from reference to analyze [m].
%       max_lag              - Maximum time lag for correlation [s].
%       time_interval        - 2-element vector [start end] for data segment [s].
%       filename_xcorr_table - Filename (string) for the output CSV table.
%
%   Optional Parameters (Name-Value Pairs):
%       'subtitle'           - Plot subtitle string (typically time and date).
%       'offset_step'        - Spatial sample rate.
%		'use_hilbert'        - Logical (true/false) for Hilbert tranform (envelope).
%		'resample_factor'    - Upsampling factor.
%
%   Output Arguments:
%       correlation_statistics - Matrix [Offset, Peak Value, Time Lag].
%       fig                    - Handle to the tiled layout figure.
%
%   Notes:
%       - The function uses an 'offset_step' of 2, skipping every other 
%         channel to optimize processing and visualization.
%       - Red vertical lines in the plots indicate the identified peak lag.
%
%   See also: XCORR, WRITETABLE, GET_CORRELOGRAM

    % parse input parameters
    params = parse_inputs(data, sampling_frequency, distance, channel_distance_m, ...
        channel_reference_position_m, offset_m, max_lag, time_interval, ...
		filename_xcorr_table, varargin{:});
	offset_step = params.offset_step;
	use_hilbert = params.use_hilbert;
    
    % select signals in time interval
    t_start_idx = max(1, round(time_interval(1) * sampling_frequency));
    t_end_idx = min(size(data, 2), round(time_interval(2) * sampling_frequency));
    data_corr = data(:, t_start_idx:t_end_idx);

	% new sampling frequency (if there is a resample factor)
	if ~isempty(params.resample_factor)
		sampling_frequency = round(params.resample_factor*sampling_frequency);
	end
    
    % number of samples
    max_lag_samples = round(max_lag * sampling_frequency);
    
    % closest channel to reference channel
    [~, channel_reference_idx] = min(abs(distance - channel_reference_position_m)); % index of the closest channel to channel_reference_position_m
    actual_channel_distance = distance(channel_reference_idx); % distance of the closest channel to channel_reference_position_m
    channel_reference = data_corr(channel_reference_idx, :);

	% resample channel signal
	if ~isempty(params.resample_factor)
		channel_reference = resample(channel_reference, params.resample_factor, 1);
	end
        
    % subplots steup
    nb_subplots = 2 * round(offset_m/(offset_step * channel_distance_m)) + 1;
    nb_columns = floor(sqrt(nb_subplots));
    nb_rows = ceil(nb_subplots / nb_columns);
    
    % open figure
    fig = figure('units','normalized','outerposition',[0 0 1 1], Name="Corss-Correlation", NumberTitle="off");
    t = tiledlayout(nb_rows,nb_columns,'TileSpacing','Compact', 'Padding', 'compact');
    
	% ------------------------- AUTOCORRELATION ------------------------- %
    % (auto)correlation of refernce channel signal
    [acorr_result, lags_auto] = xcorr(channel_reference, max_lag_samples);
    auto_time_lags = lags_auto/sampling_frequency;
	
	% use hilbert tranform if required
	if use_hilbert
        auto_correlation = abs(hilbert(acorr_result));
	else
		auto_correlation = acorr_result;
	end
    
    % parameters for plot scaling
    min_correlation = min(auto_correlation);
    min_correlation = min_correlation + min_correlation/4;
    max_correlation = max(auto_correlation);
    max_correlation = max_correlation + max_correlation/4;

	% ------------------------------------------------------------------- %
    
	% correlation statistics matrix pre-allocation
    correlation_statistics = zeros(nb_subplots, 3); % [offset, max_value, time]
	csv_position = 1;

	% -------------------- NEGATIVE CROSSCORRELATION -------------------- %
	for i = (ceil(nb_subplots/2) -1):-1:1
    
        % check on array limits
        idx_plus = channel_reference_idx + i * offset_step;
        idx_minus = channel_reference_idx - i * offset_step;
        
        if idx_plus > size(data_corr, 1) || idx_minus < 1
            break;
		end

		% get channel signal
		channel_i = data_corr((channel_reference_idx - i * offset_step), :);

		% resample channel signal
		if ~isempty(params.resample_factor)
			channel_i = resample(channel_i, params.resample_factor, 1);
		end
        
        % (cross)correlation with negative offset
        [xcorr_result, lags_xcorr_negative_offset] = xcorr(channel_reference, channel_i, max_lag_samples);
        time_lags_xcorr_negative_offset = lags_xcorr_negative_offset / sampling_frequency;
		offset_from_reference = distance(channel_reference_idx - i * offset_step) - actual_channel_distance;

		% use hilbert tranform if required
		if use_hilbert
            xcorr_negative_offset = abs(hilbert(xcorr_result));
		else
			xcorr_negative_offset = xcorr_result;
		end
        
        % plot result 
        nexttile
        plot(time_lags_xcorr_negative_offset, xcorr_negative_offset);
        ylim([min_correlation max_correlation]); xlim([-max_lag max_lag]);
        xlabel('Time lag (s)');
        title(sprintf('dx = %0.2f m', offset_from_reference));

		% find peak
        [max_peak, max_peak_idx] = max(xcorr_negative_offset);
		hold on
		xline(time_lags_xcorr_negative_offset(max_peak_idx), '-r');
		hold off
		
        % save results
        correlation_statistics(csv_position, 1) = offset_from_reference;
        correlation_statistics(csv_position, 2) = max_peak;
        correlation_statistics(csv_position, 3) = time_lags_xcorr_negative_offset(max_peak_idx);

		csv_position = csv_position + 1;
        
	end
	% ------------------------------------------------------------------- %

	% ------------------------- AUTOCORRELATION ------------------------- %
    nexttile

    plot(auto_time_lags, auto_correlation);
    ylim([min_correlation max_correlation]); xlim([-max_lag max_lag]);
    xlabel('Time lag (s)');
    title('Auto-correlation', 'Color', 'r');
    
    % writes (auto)correlation result on csv file
	[~, max_auto_correlation_idx] = max(auto_correlation);	
	correlation_statistics(csv_position, 1) = 0; % offset
	correlation_statistics(csv_position, 2) = auto_correlation(max_auto_correlation_idx);
	correlation_statistics(csv_position, 3) = auto_time_lags(max_auto_correlation_idx);
	csv_position = csv_position + 1;
	% ------------------------------------------------------------------- %

	% -------------------- POSITIVE CROSSCORRELATION -------------------- %
	for i = 1:(ceil(nb_subplots/2) -1)
    
        % check on array limits
        idx_plus = channel_reference_idx + i * offset_step;
        idx_minus = channel_reference_idx - i * offset_step;
        
        if idx_plus > size(data_corr, 1) || idx_minus < 1
            break;
		end

		% get channel signal
		channel_i = data_corr((channel_reference_idx + i * offset_step), :);

		% resample channel signal
		if ~isempty(params.resample_factor)
			channel_i = resample(channel_i, params.resample_factor, 1);
		end
            
        % (cross)correlation with positive offset
        [xcorr_result, lags_xcorr_positive_offset] = xcorr(channel_reference, channel_i, max_lag_samples);
        time_lags_xcorr_positive_offset = lags_xcorr_positive_offset / sampling_frequency;
		offset_from_reference = distance(channel_reference_idx + i * offset_step) - actual_channel_distance;

		% use hilbert tranform if required
		if use_hilbert
            xcorr_positive_offset = abs(hilbert(xcorr_result));
		else
			xcorr_positive_offset = xcorr_result;
		end
        
        % plot result 
        nexttile
        plot(time_lags_xcorr_positive_offset, xcorr_positive_offset);
        ylim([min_correlation max_correlation]); xlim([-max_lag max_lag]);
        xlabel('Time lag (s)');
        title(sprintf('dx = %0.2f m', offset_from_reference));
   
		% find peak
		[max_peak, max_peak_idx] = max(xcorr_positive_offset);
		hold on
		xline(time_lags_xcorr_negative_offset(max_peak_idx), '-r');
		hold off

        % save results
        correlation_statistics(csv_position, 1) = offset_from_reference;
        correlation_statistics(csv_position, 2) = max_peak;
        correlation_statistics(csv_position, 3) = time_lags_xcorr_positive_offset(max_peak_idx);

		csv_position = csv_position + 1;
        
	end
	% ------------------------------------------------------------------- %

	correlation_table = array2table(correlation_statistics, ...
    	'VariableNames', {'Offset', 'Peak_value', 'Time'});
	
	writetable(correlation_table, filename_xcorr_table);
	fprintf('Events saved to: %s\n', filename_xcorr_table);

	% apply optional subtitle
	if ~isempty(params.subtitle)
		 sgtitle({sprintf('Cross-correlation (Ref: %.3f km, max offset: %d m)', channel_reference_position_m, offset_m), ...
        sprintf('Signals duration: from %.2f s to %.2f s', time_interval), params.subtitle});
	end
    %
end
% -----------------------------------------------------------------------%

%% INPUT PARSING
function results = parse_inputs(data, sampling_frequency, distance, channel_distance_m, ...
	channel_reference_position_m, offset_m, max_lag, time_interval, ...
	filename_xcorr_table, varargin)
	p = inputParser;
	
	% required parameters
	addRequired(p, 'data', @isnumeric);
    addRequired(p, 'sampling_frequency', @(x) isnumeric(x) && isscalar(x) && x>0);
    addRequired(p, 'distance', @(x) isnumeric(x) && isvector(x));
    addRequired(p, 'channel_distance_m', @(x) isnumeric(x) && isscalar(x) && x>=0);
    addRequired(p, 'channel_reference_position_m', @(x) isnumeric(x) && isscalar(x) && x>=0);
    addRequired(p, 'offset_m', @(x) isnumeric(x) && isscalar(x) && x>=0);
    addRequired(p, 'max_lag', @(x) isnumeric(x) && isscalar(x) && x>=0 );
    addRequired(p, 'time_interval', @(x) isnumeric(x) && isvector(x) && all(x>=0));
	addRequired(p, 'filename_xcorr_table', @(x) (ischar(x) || isstring(x)));	

	% optional parameters
	addParameter(p, 'subtitle', [], @(x) isempty(x) || ischar(x) || isstring(x));
	addParameter(p, 'offset_step', 2, @(x) isempty(x) || isnumeric(x) && isscalar(x));
	addParameter(p, 'use_hilbert', false, @islogical);
	addParameter(p, 'resample_factor', [], @(x) isempty(x) || isnumeric(x) || isinteger(x));
	
	parse(p, data, sampling_frequency, distance, channel_distance_m, ...
	channel_reference_position_m, offset_m, max_lag, time_interval, ...
	filename_xcorr_table, varargin{:});
	results = p.Results;
end
