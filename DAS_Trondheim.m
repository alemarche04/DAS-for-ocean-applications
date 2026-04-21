%% CLEAR VARIABLES
clc
clear all
close all

%% LOAD DATA FROM DATASET
% add directories to Matlab search path
addpath('Dataset', 'Dataset_Norway', 'Filters', 'Plots', 'SetupAndConfiguration');

% Dataset available:
%		Norway
% Dataset filenames:
%		Norway
%			- "122403.hdf5"

dataset_name	= 'Norway';
DAS				= feval(str2func(dataset_name + "_cfg"));
	EllyCable	= ellyandcable();
data			= DAS.load_data("122403.hdf5");
% -----------------------------------------------------------------------%

%% ELLY AND CABLE: PLOT RUN 1
EllyCable.plot_run1();
% -----------------------------------------------------------------------%

%% ELLY AND CABLE: PLOT RUN 2
EllyCable.plot_run2();
% -----------------------------------------------------------------------%

%% ELLY AND CABLE: PLOT RUN 3
EllyCable.plot_run3();
% -----------------------------------------------------------------------%

%% ELLY AND CABLE: SOURCE POSITION
EllyCable.plot_source_pos(data.time_and_date);
% -----------------------------------------------------------------------%

%% ELLY AND CABLE: CHANNEL POSITION
channel_no = 210;
EllyCable.plot_channel_pos(channel_no);

% clear variables
clear channel_no
% -----------------------------------------------------------------------%

%% ELLY AND CABLE: SOURCE AND CHANNEL POSITION
channel_no = 210;
EllyCable.plot_source_channel(data.time_and_date, channel_no);

% clear variables
clear channel_no
% -----------------------------------------------------------------------%

%% ELLY AND CABLE: CHANNEL-SOURCE DISTANCE
channel_no = 207;
EllyCable.get_distance(channel_no, data.time_and_date);

% clear variables
clear channel_no
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

%% MATCHED FILTER
preamble_filename = 'preamble-B_4-25000.wav';
strain_matched_filtered = matched_filter(strain_filtered, preamble_filename);

% strain_filt_no_match = strain_filtered;
% strain_filtered = strain_matched_filtered;
%% TIME-SPACE PLOT WITH MATCHED FILTER
% parameters
tx = DAS.tx_plot();

% time-space plot
time_space_plot = get_time_space_plot( ...
strain_matched_filtered(50:end, :), ...
data.time, ...
data.distance_m(50:end), ...
'subtitle', data.time_and_date, ...
'time_lim', tx.time_lim, ...
'distance_lim', tx.distance_lim, ...
'strain_lim', tx.strain_lim, ...
'norm', true);

% export plot as png
exportgraphics( ...
time_space_plot, ...
fullfile(dataset_name, ['tx_matched_filt_plot_' dataset_name  '.png']));

% % draw channel position
% channel_no = 178;
% channel_position_m = channel_no * data.channel_distance_m;
% hold on;
% yline(channel_position_m*1e-3, '--', 'channel','LineWidth', 1, 'Color', '#FFD1DF');
% hold off;

% clear variables
clear preamble_filename tx time_space_plot  channel_no channel_position_m
% -----------------------------------------------------------------------%
%% TIME-SPACE PLOT
% parameters
tx = DAS.tx_plot();

% time-space plot
time_space_plot = get_time_space_plot( ...
	strain_filtered(50:end, :), ...
	data.time, ...
	data.distance_m(50:end), ...
	'subtitle', data.time_and_date, ...
    'time_lim', tx.time_lim, ...
	'distance_lim', tx.distance_lim, ...
	'strain_lim', tx.strain_lim, ...
	'norm', true);

% draw propagation speed lines on time-space plot
speedline = false;
if speedline
	hold on;
	draw_prop_speed_lines( ...
		data.time, ...
		data.propagation_speed, ...
		tx.p1, ...
		tx.cpa_m, ...
		tx.channel_position_m);
	hold off;
end

% export plot as png
exportgraphics( ...
	time_space_plot, ...
	fullfile(dataset_name, ['time_space_plot_' dataset_name  '.png']));

% clear variables
clear tx speedline time_space_plot
% -----------------------------------------------------------------------%

%% STRAIN WAVEFORM (SINGLE CHANNEL)
% parameters
wf = DAS.waveform();

% plot strain waveform channel of interest
strain_waveform = get_strain_waveform( ...
	strain_filtered, ...
	data.distance_m, ...
	data.time, ...
	wf.channel_position_m, ...
	wf.filename_audio, ...
	data.sampling_frequency_Hz, ...
	'subtitle', data.time_and_date, ...
	'time_lim', wf.time_lim, ...
	'strain_lim', wf.strain_lim);

% export plot as png
exportgraphics( ...
	strain_waveform, ...
	fullfile(dataset_name, ['strain_waveform_' dataset_name  '.png']));

% clear variables
clear wf strain_waveform
% -----------------------------------------------------------------------%

%% SPECTROGRAM (SINGLE CHANNEL)
% parameters
sg = DAS.spectrogram();

% plot spectrogram
spectrogram_plot = get_spectrogram( ...
	strain_filtered, ...
	data.distance_m, ...
	data.sampling_frequency_Hz, ...
	sg.channel_position_m, ...
	sg.nfft, ...
	sg.window_len, ...
	sg.window, ...
	sg.overlap_pct, ...
	'subtitle', data.time_and_date, ...
	'time_lim', sg.time_lim, ...
	'frequency_lim', sg.frequency_lim, ...
	'strain_lim', sg.strain_lim);

% export plot as png
exportgraphics( ...
	spectrogram_plot, ...
	fullfile(dataset_name, ['spectrogram_' dataset_name  '.png']));

% clear variables
clear sg spectrogram_plot
% -----------------------------------------------------------------------%

%% SPACE-FREQUENCY PLOT
% parameters
fx = DAS.fx_plot();

% plot spatio-spectral representation
space_frequency_plot = get_space_frequency_plot( ...
	strain_filtered, ...
	data.distance_m, ...
	data.sampling_frequency_Hz, ...
	fx.nfft, ...
	fx.time_window, ...
	fx.time_interval, ...
	fx.filename_animation, ...
	'subtitle', data.time_and_date, ...
	'frequency_lim', fx.frequency_lim, ...
	'strain_lim', fx.strain_lim, ...
	'get_animation', true);

% export plot as png
exportgraphics( ...
	space_frequency_plot, ...
	fullfile(dataset_name, ['fx_plot_' dataset_name  '.png']));

% clear variables
clear fx space_frequency_plot
% -----------------------------------------------------------------------%

%% CROSS-CORRELATION STATISTICS
% parameters
xcorr = DAS.correlation();
% to use strain with matched filtering (Trondheim dataset):
% strain_filt_no_match = strain_filtered;
% strain_filtered = strain_matched_filtered;

% plot correlogram
correlogram = get_correlogram( ...
	strain_matched_filtered, ...
	data.sampling_frequency_Hz, ...
	data.distance_m, ...
    xcorr.channel_position_m, ...
	xcorr.offset_m, ...
	xcorr.time_lag, ...
	xcorr.time_interval, ...
	'subtitle', data.time_and_date, ...
	'use_hilbert',false);

% export plot as png
exportgraphics( ...
	correlogram, ...
	fullfile(dataset_name, ['correlogram_' dataset_name  '.png']));

% plot correlation statistics and export data to csv file
[correlation_statistics, xcorr_plot] = get_correlation_statistics( ...
	strain_matched_filtered, ...
	data.sampling_frequency_Hz, ...
	data.distance_m, ...
	data.channel_distance_m, ...
	xcorr.channel_position_m, ...
	xcorr.offset_m, ...
	xcorr.time_lag, ...
	xcorr.time_interval, ...
	xcorr.filename_table, ...
	'subtitle', data.time_and_date, ...
	'offset_step', 1, ...
	'use_hilbert', false);

% export plot as png
exportgraphics( ...
	xcorr_plot, ...
	fullfile(dataset_name, ['cross_corr_stats_' dataset_name  '.png']));
% -----------------------------------------------------------------------%

%% R estimate
CPA_position = xcorr.cpa_m;
reference_channel_position = xcorr.channel_position_m;

distance_ref_CPA = (CPA_position - reference_channel_position); % distance btw reference channel and CPA
distance_ref_k = correlation_statistics(:, 1); % distance btw reference channel and another within the max offset [m]
time_peaks = correlation_statistics(:, 3); % peak time of cross correlations
c = data.propagation_speed;

d12 = distance_ref_k;
pc = time_peaks.*c;
d0 = distance_ref_CPA;

figure('Name', "TDOA * c", 'NumberTitle','off');
plot(d12, pc, '-*');
legend("TDOA * c");

R = sqrt(((d0^2 + (time_peaks.^2).*c^2 - (d0 - d12).^2) ...
	./ (2.*time_peaks.*c)).^2 - d0^2);
R(imag(R) ~= 0) = NaN;

R_med = median(R, 'omitnan');

figure('Name', "SourceDistance", 'NumberTitle','off');
plot(d12, R, '-*');
title("Source distance (estimate)");
subtitle(['Median value of R: ' num2str(R_med)]);
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


d1 = sqrt( ( sqrt(R_med^2 + distance_ref_CPA^2) - dt*c ).^2 - R_med^2 );
if distance_ref_CPA < 0
	dx = distance_ref_CPA + d1;
else
	dx = distance_ref_CPA - d1;
end
hold on
plot(dt, dx, 'k--', 'LineWidth', 1)
hold off

% % export plot as png
% exportgraphics(correlogram, ...
% ['Correlogram_tests/correlogram_' ...
% num2str(time_interval(1)) '_' ...
% num2str(time_interval(2)) '_' ...
% 'ref_' num2str(reference_channel_position) ...
% '_band_' ...
% num2str(bp_cutoff_frequency(1)) '_' ...
% num2str(bp_cutoff_frequency(2)) '_' ...
% 'with_R_line.png']);

fprintf('Median value of R: %d [m]\n', R_med);