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

%% MEDIAN FILTER 2D (3X3 SYMMETRIC)
% parameters
medFilt = DAS.medFilt();

% apply filter
strain_filtered = median_filter_2D( ...
	strain_filtered, ...
	medFilt.dim);

% clear variables
clear medFilt
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
	'use_hilbert',false, ...
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
	"cross_corr_stats_medFilt.csv", ...
	'subtitle', data.time_and_date, ...
	'offset_step', 2, ...
	'use_hilbert', false, ...
	'resample_factor', 10);

distance_from_CPA = (xcorr.cpa_m - xcorr.channel_position_m); % distance btw reference channel and CPA
xcorr_offset_m = correlation_statistics(:, 1); % cross-correlation offset [m]
time_peak = correlation_statistics(:, 3); % peak time of cross correlations

c = data.propagation_speed;

R = sqrt(((distance_from_CPA^2 + (time_peak.^2).*c^2 - (distance_from_CPA - xcorr_offset_m).^2) ...
	./ (2.*time_peak.*c)).^2 - distance_from_CPA^2);
R = abs(R);

figure;
plot(xcorr_offset_m, R, '-*');

% figure(correlogram);
dt= -0.2:0.002:0.2;
distance_from_CPA = 800;

R_med = median(R, 'omitnan');

d1 = sqrt( ( sqrt(R_med^2+distance_from_CPA^2) - dt*c ).^2 - R_med^2 );
dsh = distance_from_CPA-d1;
% hold on
% plot(dt,dsh,'k--','LineWidth', 1)
% ylabel('Distance from reference, dx [m]')
% hold off

fprintf('Estimate value of R: %d [m]\n', R_med);

% clear variables
clear xcorr correlogram correlation_statistics xcorr_plot
% -----------------------------------------------------------------------%

%% Cross-correlation between two channels
% Define the channels for cross-correlation
CPA = 42800;
channel_dist_12 = data.gauge_length_m;

channel1_position = 42000;
channel2_position = 42000 + channel_dist_12;

channel_dist_1CPA = abs(CPA-channel1_position);

c = 1475; % [m/s]
max_lag = 300 / c;
time_interval = [47 50];

[peak_lag, cross_corr] = corss_correlation(strain_filtered, data.sampling_frequency_Hz, data.distance_m, data.channel_distance_m, ...
    channel1_position, channel2_position, max_lag, time_interval, 'subtitle', data.time_and_date);

R = sqrt(((channel_dist_1CPA^2 + (peak_lag.^2).*c^2 - (channel_dist_1CPA - channel_dist_12).^2) ...
		./ (2.*peak_lag.*c)).^2 - channel_dist_1CPA^2);

fprintf("\nR = %.2f\n", R);