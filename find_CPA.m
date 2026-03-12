%% CLEAR VARIABLES
clc
clear all
close all

%% LOAD DATA FROM DATASET
% add directories to Matlab search path
addpath('Dataset', 'Dataset_Norway', 'Filters', 'Plots', 'SetupAndConfiguration');

% Dataset available:	
%		DAS4Whale
%		DAS4Tracking
%		Norway
%		OOI_Wilcock
% Dataset filenames:
%		DAS4Whale
%			- "20200627_052441_ch10001_to_ch15000_whale_raw_L160s.mat"
%			- "20200716_154302_ch21001_to_ch22000_whale_raw_L720s.mat"
%		DAS4Tracking
%			- "20220822_114507_to_114837_ch9803_to_ch24509_sample_Freq_78_Hz.mat"
%			- "20220822_122707_to_123037_ch9803_to_ch24509_sample_Freq_78_Hz.mat"
%			- "20220906_165106_to_165436_ch2450_to_ch9191_sample_Freq_125_Hz.mat"
%			- "20220906_175106_to_175436_ch2450_to_ch9191_sample_Freq_125_Hz_outer.mat"
%			- "20220906_175107_to_175437_ch2450_to_ch9191_sample_Freq_125_Hz_inner.mat"
%		Norway
%			- "122403.hdf5"
%		OOI_Wilcock
%			- "North-C2-HF-P1kHz-GL30m-Sp2m-FS500Hz_2021-11-03T015731Z.h5"

dataset_name	= 'DAS4Whale';
DAS				= feval(str2func(dataset_name + "_cfg"));
if strcmp(dataset_name, 'Norway')
	EllyCable	= ellyandcable();
end
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

% plot correlogram
correlogram = get_correlogram( ...
	strain_filtered, ...
	data.sampling_frequency_Hz, ...
	data.distance_m, ...
    xcorr.channel_position_m, ...
	xcorr.offset_m, ...
	xcorr.time_lag, ...
	xcorr.time_interval, ...
	'subtitle', data.time_and_date, ...
	'resample_factor', 10);

% plot correlation statistics and export data to csv file
[correlation_statistics, xcorr_plot] = get_correlation_statistics( ...
	strain_filtered, ...
	data.sampling_frequency_Hz, ...
	data.distance_m, ...
	data.channel_distance_m, ...
	xcorr.channel_position_m, ...
	xcorr.offset_m, ...
	xcorr.time_lag, ...
	xcorr.time_interval, ...
	"cross_corr_stats.csv", ...
	'subtitle', data.time_and_date, ...
	'offset_step', 2, ...
	'resample_factor', 10);

%% FIND CPA
% In a selected range of distance, use each channel in said range as CPA compute
% the R estimate. The channel that minimizes the misalignment on the linear 
% regression of R is the best CPA candidate 

% cross-correlation parameters
xcorr = DAS.correlation();

% compute cross-correlation between a reference channel and adjacent
% channels in a defined range of distance
[correlation_statistics, ~] = get_correlation_statistics( ...
	strain_filtered, ...
	data.sampling_frequency_Hz, ...
	data.distance_m, ...
	data.channel_distance_m, ...
	xcorr.channel_position_m, ...
	xcorr.offset_m, ...
	xcorr.time_lag, ...
	xcorr.time_interval, ...
	"cross_corr_stats.csv", ...
	'subtitle', data.time_and_date, ...
	'offset_step', 2, ...
	'resample_factor', 10);
%

% select distance range in which test the channels to find the CPA
dist1 = 42450;
dist2 = 43000;

[dist1_channel_m , dist1_idx] = min(abs(data.distance_m - dist1));
[dist2_channel_m , dist2_idx] = min(abs(data.distance_m - dist2));

CPA_interval = data.distance_m(dist1_idx:dist2_idx);
%

% get parameters to compute R estimate
channel_dist_12 = correlation_statistics(:, 1); % cross-correlation offset [m]
time_peak = correlation_statistics(:, 3); % peak time of cross correlations
c = data.propagation_speed;
%

% preallocation for iterative search of CPA
LR_misalignment = zeros(1, size(CPA_interval, 2));
%

for i = 1:size(CPA_interval, 2)
	distance_from_CPA = (CPA_interval(i) - xcorr.channel_position_m); % distance btw reference channel and CPA
	
	d12 = channel_dist_12; % distance between reference channel and another
	d0 = distance_from_CPA; % distance between reference channel and CPA

	% compute R estimate for current CPA
	R = sqrt(((d0^2 + (time_peak.^2).*c^2 - (d0 - d12).^2) ...
		./ (2.*time_peak.*c)).^2 - d0^2);
	R(imag(R) ~= 0) = NaN; % remove imaginary parts
	%

	% linear regression
	valid_idx = ~isnan(R) & (d12 ~= 0); % remove problematic points
	valid_channel_dist_12 = d12(valid_idx); % get valid elements
	R_valid = R(valid_idx); % get valid elements
	
	beta = robustfit(valid_channel_dist_12, R_valid); 
	R_LR = beta(1) + beta(2) * valid_channel_dist_12;
	%

	% evaluate the misalignment
	LR_misalignment(i) = abs(R_LR(1) - R_LR(end));

end

% find the CPA that minimizes the misalignment
[min_LR_mis, min_LR_mis_idx] = min(LR_misalignment);
best_CPA = CPA_interval(min_LR_mis_idx);

fprintf('Best candidate for CPA: %.2f [m]\n', best_CPA);
%

% get parameters to compute R with best CPA
distance_from_CPA = (best_CPA - xcorr.channel_position_m); % distance btw reference channel and CPA
d12 = channel_dist_12; % distance between reference channel and another
d0 = distance_from_CPA; % distance between reference channel and CPA

% compute R estimate for best CPA
R = sqrt(((d0^2 + (time_peak.^2).*c^2 - (d0 - d12).^2) ...
	./ (2.*time_peak.*c)).^2 - d0^2);
R(imag(R) ~= 0) = NaN; % remove imaginary parts
%

% plot R
figure('Name', "Source distance", 'NumberTitle','off');
plot(d12, R, '-*');
title("Source distance (estimate)");
xlabel("Distance between channels");
ylabel("Distance (m)");
%

% linear regression
valid_idx = ~isnan(R) & (d12 ~= 0); % remove problematic points
valid_channel_dist_12 = d12(valid_idx); % get valid elements
R_valid = R(valid_idx); % get valid elements

beta = robustfit(valid_channel_dist_12, R_valid); 
R_LR = beta(1) + beta(2) * valid_channel_dist_12;
%

% plot linear regression
hold on 
plot(valid_channel_dist_12, R_LR, 'Color', "r");
legend("R estimate", "Linear regression");
hold off
%

% plot correlogram
correlogram = get_correlogram( ...
	strain_filtered, ...
	data.sampling_frequency_Hz, ...
	data.distance_m, ...
    xcorr.channel_position_m, ...
	xcorr.offset_m, ...
	xcorr.time_lag, ...
	xcorr.time_interval, ...
	'subtitle', data.time_and_date, ...
	'resample_factor', 10);

% plot on correlogram with median value of R
figure(correlogram);
dt = -xcorr.time_lag:data.sampling_interval_s:xcorr.time_lag; % time lag axis

R_med = median(R, 'omitnan'); % R median value
R_med_LR = median(R_LR, 'omitnan'); % R (Linear Regression) median value

d1 = sqrt( ( sqrt(R_med^2 + distance_from_CPA^2) - dt*c ).^2 - R_med^2 );
d1_LR = sqrt( ( sqrt(R_med_LR^2 + distance_from_CPA^2) - dt*c ).^2 - R_med_LR^2 );
if distance_from_CPA < 0
	dx = distance_from_CPA + d1;
	dx_LR = distance_from_CPA + d1_LR;
else
	dx = distance_from_CPA - d1;
	dx_LR = distance_from_CPA - d1_LR;
end

hold on
plot(dt, dx, 'k--', 'LineWidth', 1)
% plot(dt, dx_LR, 'g--', 'LineWidth', 1)
hold off

fprintf('Median value of R: %.2f [m]\n', R_med);
fprintf('Median value of R (Linear Regression): %.2f [m]\n', R_med_LR);

%% TIME-SPACE PLOT
% parameters
tx = DAS.tx_plot();

% time-space plot
time_space_plot = get_time_space_plot( ...
	strain_filtered, ...
	data.time, ...
	data.distance_m, ...
	'subtitle', data.time_and_date, ...
    'time_lim', tx.time_lim, ...
	'distance_lim', tx.distance_lim, ...
	'strain_lim', tx.strain_lim, ...
	'norm', true);

hold on;

yline(best_CPA, '--', 'CPA','LineWidth', 1, 'Color', '#FFD1DF');
yline(xcorr.channel_position_m, '--', 'reference channel', 'LineWidth', 1, 'Color', '#D1FFBD');

% -----------------------------------------------------------------------%