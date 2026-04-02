%% CLEAR VARIABLES
clc
clear all
close all

%% LOAD DATA FROM DATASET
% add directories to Matlab search path
addpath('Dataset', 'Dataset_Norway', 'Filters', 'Plots', 'SetupAndConfiguration');

dataset_name	= 'DAS4Whale';
DAS				= feval(str2func(dataset_name + "_cfg"));
data			= DAS.load_data("20200627_052441_ch10001_to_ch15000_whale_raw_L160s.mat");
% -----------------------------------------------------------------------%

%% BUTTERWORTH BANDPASS FILTER
% parameters
bp = DAS.bandpass();

% apply filter
strain_filtered = butterworth_bp_filter( ...
	data.strain, ...
	bp.cutoff_freq, ...
	bp.order, ...
	data.sampling_frequency_Hz);

% clear variables
clear bp
% -----------------------------------------------------------------------%

%% FK FILTERING
% parameters
fkFilt = DAS.fkFilt();

% design fk filter
fk_filter =	fk_filter_design( ...
	data.dimensions, ...
	data.channel_distance_m, ...
	data.sampling_interval_s);

% apply fk filter
strain_filtered = fk_filter_filt( ...
	strain_filtered, ...
	fk_filter);

% clear variables
clear fkFilt fk_filter
% -----------------------------------------------------------------------%

%% CROSS-CORRELATION STATISTICS
% parameters
xcorr = DAS.correlation();

channel_position = 42000; % reference channel position [m]
offset = 300; % maximum spatial offset from reference channel [m]
max_time_lag = 0.2; % time limits for correlation analysis [s]
time_interval = [47 50]; % time interval of signal [s]
cpa = 42800; % CPA position [m]

% plot correlogram
correlogram = get_correlogram( ...
	strain_filtered, ...
	data.sampling_frequency_Hz, ...
	data.distance_m, ...
    channel_position, ...
	offset, ...
	max_time_lag, ...
	time_interval, ...
	'subtitle', data.time_and_date, ...
	'resample_factor', 10);

export_plot = false;

if export_plot
	% export plot as png
	exportgraphics( ...
		correlogram, "Correlogram_Analysis/exp_correlogram.png");
end

% plot correlation statistics and export data to csv file
[correlation_statistics, xcorr_plot] = get_correlation_statistics( ...
	strain_filtered, ...
	data.sampling_frequency_Hz, ...
	data.distance_m, ...
	data.channel_distance_m, ...
	channel_position, ...
	offset, ...
	max_time_lag, ...
	time_interval, ...
	"Correlogram_Analysis/exp_correlation_statistics.csv", ...
	'subtitle', data.time_and_date, ...
	'offset_step', 2, ...
	'resample_factor', 10);

%% Estimate R

distance_from_CPA = (cpa - channel_position); % distance btw reference channel and CPA
channel_dist_12 = correlation_statistics(:, 1); % distance btw reference channel and another within the max offset [m]
time_peak = correlation_statistics(:, 3); % peak time of cross correlations
c = data.propagation_speed;

d12 = channel_dist_12;
pc = time_peak.*c;
d0 = distance_from_CPA;

% A = (pc.^2 + 2.*d0.*d12 - d12.^2) ./ (2 .* pc);
% R = sqrt(A.^2 - d0^2);

R = sqrt(((d0^2 + (time_peak.^2).*c^2 - (d0 - d12).^2) ...
	./ (2.*time_peak.*c)).^2 - d0^2);
R(imag(R) ~= 0) = NaN;

figure('Name', "SourceDistance", 'NumberTitle','off');
plot(d12, R, '-*');
title("Source distance (estimate)");
xlabel("Distance between channels");
ylabel("Distance (m)");

% linear regression
valid_idx = ~isnan(R) & (d12 ~= 0); % remove problematic points
valid_channel_dist_12 = d12(valid_idx); % get valid elements
R_valid = R(valid_idx); % get valid elements

beta = robustfit(valid_channel_dist_12, R_valid); 
R_LR = beta(1) + beta(2) * valid_channel_dist_12;

hold on 
plot(valid_channel_dist_12, R_LR, 'Color', "r");
legend("R estimate", "Linear regression");
hold off

figure(correlogram);
dt = -0.2:data.sampling_interval_s:0.2;

R_med = median(R, 'omitnan');

d1 = sqrt( ( sqrt(R_med^2 + distance_from_CPA^2) - dt*c ).^2 - R_med^2 );

if distance_from_CPA < 0
	dx = distance_from_CPA + d1;
else
	dx = distance_from_CPA - d1;
end

hold on
plot(dt, dx, 'k--', 'LineWidth', 1)
hold off

fprintf('Median value of R: %d [m]\n', R_med);