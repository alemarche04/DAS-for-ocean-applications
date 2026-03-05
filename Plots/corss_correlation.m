function [peak_lag, fig] = corss_correlation(data, sampling_frequency, distance_m, channel_distance_m, ...
    channel1_position_m, channel2_position_m, max_lag, time_interval, varargin)
% CROSS_CORRELATION Computes and plot cross-correlation between two channels.
%
%   [PEAK_LAG, FIG] = CROSS_CORRELATION(DATA, SAMPLING_FREQUENCY, ...) 
%   calculates the cross correlation of two channels at specific positions 
%	along the FO cable and computes the TDOA of the acoustic signal.
%
%   Input Arguments: 
%       data                 - 2D matrix of DAS data [channels x samples].
%       sampling_frequency   - System sampling rate [Hz].
%       distance_m           - Vector of spatial coordinates for channels [m].
%       channel_distance_m   - Nominal spacing between channels [m].
%       channlel1_position_m - Position of the first channel [m].
%       channlelw_position_m - Position of the second channel [m].
%       max_lag              - Maximum time lag for correlation [s].
%       time_interval        - 2-element vector [start end] for data segment [s].
%
%   Optional Parameters (Name-Value Pairs):
%       'subtitle'           - Plot subtitle string (typically time and date).
%       'resample_factor'    - Upsampling factor.
%
%   Output Arguments:
%       peak_lag             - TDOA of the acoustic signal.
%       fig                  - Handle to the tiled layout figure.
%
%   See also: XCORR, RESAMPLE, GET_CORRELOGRAM, GET_CORRELATION_STATISTICS

	% parse input parameters
    params = parse_inputs(data, sampling_frequency, distance_m, channel_distance_m, ...
    channel1_position_m, channel2_position_m, max_lag, time_interval, varargin{:});

	% select signals in time interval
    t_start_idx = max(1, round(time_interval(1) * sampling_frequency));
    t_end_idx = min(size(data, 2), round(time_interval(2) * sampling_frequency));
    data_corr = data(:, t_start_idx:t_end_idx);
	%
    
    % get channel1
    [~, channel1_idx] = min(abs(distance_m - channel1_position_m)); % index of the closest channel to channel1_position_m
    actual_channel1_distance = distance_m(channel1_idx); % distance of the closest channel to channel1_position_m
    channel1_trace = data_corr(channel1_idx, :);
	%

	% get channel2
    [~, channel2_idx] = min(abs(distance_m - channel2_position_m)); % index of the closest channel to channel2_position_m
    actual_channel2_distance = distance_m(channel2_idx); % distance of the closest channel to channel2_position_m
    channel2_trace = data_corr(channel2_idx, :);
	%

	% upsampling of channel1 and channel2 signals
	if ~isempty(params.resample_factor)
		sampling_frequency = round(params.resample_factor*sampling_frequency);
		channel1_trace = resample(channel1_trace, params.resample_factor, 1);
		channel2_trace = resample(channel2_trace, params.resample_factor, 1);
	end
	%

	% number of samples
	max_lag_samples = round(max_lag * sampling_frequency);

	% compute cross correlation
	[corss_correlation, lags_xcorr] = xcorr(channel1_trace, channel2_trace, max_lag_samples);
        time_lags_xcorr = lags_xcorr / sampling_frequency;
		distance_channels_12 = abs(actual_channel1_distance - actual_channel2_distance);
	%

	% plot cross correlation
	fig = figure(Name="Corss-Correlation", NumberTitle="off");
	plot(time_lags_xcorr, corss_correlation);
	title("Cross-correlation between two channels", "FontSize", 16);
	xlabel("Time lag (s)");
	%

	% plot correlation peak line
	[max_peak , max_peak_idx] = max(corss_correlation);
	peak_lag = time_lags_xcorr(max_peak_idx);
	hold on
	xline(peak_lag, '-r');
	peak_lag_txt = sprintf(" peak time lag = %.5f s", peak_lag);
	text(peak_lag, max_peak, peak_lag_txt, 'Color', 'r', 'FontSize', 12, 'HorizontalAlignment','left');
	hold off
	%

	% apply optional subtitle
	if ~isempty(params.subtitle)
		subtitle([sprintf("Channel 1: %.2f m | Channel 2: %.2f m", actual_channel1_distance, actual_channel2_distance) ...
			sprintf("Distance between channels: %.2f m", distance_channels_12), params.subtitle], "FontSize", 12);
	else
		subtitle([sprintf("Channel 1: %.2f m | Channel 2: %.2f m", actual_channel1_distance, actual_channel2_distance) ...
			sprintf("Distance between channels: %.2f m", distance_channels_12)], "FontSize", 12);
	end

end


	%% INPUT PARSING
function results = parse_inputs(data, sampling_frequency, distance_m, channel_distance_m, ...
    channel1_position_m, channel2_position_m, max_lag, time_interval, varargin)
	p = inputParser;
	
	% required parameters
	addRequired(p, 'data', @isnumeric);
    addRequired(p, 'sampling_frequency', @(x) isnumeric(x) && isscalar(x) && x>0);
    addRequired(p, 'distance', @(x) isnumeric(x) && isvector(x));
    addRequired(p, 'channel_distance_m', @(x) isnumeric(x) && isscalar(x) && x>=0);
    addRequired(p, 'channel1_position_m', @(x) isnumeric(x) && isscalar(x) && x>=0);
    addRequired(p, 'channel2_position_m', @(x) isnumeric(x) && isscalar(x) && x>=0);
    addRequired(p, 'max_lag', @(x) isnumeric(x) && isscalar(x) && x>=0 );
    addRequired(p, 'time_interval', @(x) isnumeric(x) && isvector(x) && all(x>=0));

	% optional parameters
	addParameter(p, 'subtitle', [], @(x) isempty(x) || ischar(x) || isstring(x));
	addParameter(p, 'resample_factor', [], @(x) isempty(x) || isnumeric(x) || isinteger(x));
	
	parse(p, data, sampling_frequency, distance_m, channel_distance_m, ...
    channel1_position_m, channel2_position_m, max_lag, time_interval, varargin{:});
	results = p.Results;
end