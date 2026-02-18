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

dataset_name	= 'Norway';
DAS				= feval(str2func(dataset_name + "_cfg"));
if strcmp(dataset_name, 'Norway')
	EllyCable	= ellyandcable();
end
data			= DAS.load_data("122403.hdf5");
% -----------------------------------------------------------------------%

%% ELLY AND CABLE: PLOT RUN 1
if strcmp(dataset_name, 'Norway')
	EllyCable.plot_run1();
end
% -----------------------------------------------------------------------%

%% ELLY AND CABLE: PLOT RUN 2
if strcmp(dataset_name, 'Norway')
	EllyCable.plot_run2();
end
% -----------------------------------------------------------------------%

%% ELLY AND CABLE: PLOT RUN 3
if strcmp(dataset_name, 'Norway')
	EllyCable.plot_run3();
end
% -----------------------------------------------------------------------%

%% ELLY AND CABLE: SOURCE POSITION
if strcmp(dataset_name, 'Norway')
	EllyCable.plot_source_pos(data.time_and_date);
end
% -----------------------------------------------------------------------%

%% ELLY AND CABLE: CHANNEL POSITION
if strcmp(dataset_name, 'Norway')
	channel_no = 210;
	EllyCable.plot_channel_pos(channel_no);

	% clear variables
	clear channel_no
end
% -----------------------------------------------------------------------%

%% ELLY AND CABLE: SOURCE AND CHANNEL POSITION
if strcmp(dataset_name, 'Norway')
	channel_no = 204;
	EllyCable.plot_source_channel(data.time_and_date, channel_no);

	% clear variables
	clear channel_no
end
% -----------------------------------------------------------------------%

%% ELLY AND CABLE: CHANNEL-SOURCE DISTANCE
if strcmp(dataset_name, 'Norway')
	channel_no = 178;
	EllyCable.get_distance(channel_no, data.time_and_date);

	% clear variables
	clear channel_no
end
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

%% MATCHED FILTER AND TIME-SPACE PLOT
if strcmp(dataset_name, 'Norway')
	preamble_filename = 'preamble-B_4-25000.wav';
	strain_matched_filtered = matched_filter(strain_filtered, preamble_filename);

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
	'strain_lim', tx.strain_lim);

	% export plot as png
	exportgraphics( ...
	time_space_plot, ...
	fullfile(dataset_name, ['tx_matched_filt_plot_' dataset_name  '.png']));

	% draw channel position
	channel_no = 178;
	channel_position_m = channel_no * data.channel_distance_m;
	hold on;
	yline(channel_position_m*1e-3, '--', 'channel','LineWidth', 1, 'Color', '#FFD1DF');
	hold off;

	% clear variables
	clear preamble_filename tx time_space_plot  channel_no channel_position_m
end
% -----------------------------------------------------------------------%
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
	'strain_lim', tx.strain_lim);

% draw propagation speed lines on time-space plot
speedline = false;
if speedline
	hold on;
	draw_prop_speed_lines( ...
		data.time, ...
		tx.p1, ...
		tx.p2, ...
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
% to use strain with matched filtering (Trondheim dataset):
% strain_filt_no_match = strain_filtered;
% strain_filtered = strain_matched_filtered;

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
% to use strain with matched filtering (Trondheim dataset):
% strain_filt_no_match = strain_filtered;
% strain_filtered = strain_matched_filtered;

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
	'strain_lim', sg.strain_lim, ...
	'norm', false);

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
	strain_filtered, ...
	data.sampling_frequency_Hz, ...
	data.distance_m, ...
    xcorr.channel_position_m, ...
	xcorr.offset_m, ...
	xcorr.time_lag, ...
	xcorr.time_interval, ...
	'subtitle', data.time_and_date, ...
	'use_hilbert',true);

% export plot as png
exportgraphics( ...
	correlogram, ...
	fullfile(dataset_name, ['correlogram_' dataset_name  '.png']));

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
	xcorr.filename_table, ...
	'subtitle', data.time_and_date, ...
	'offset_step', 1, ...
	'use_hilbert', true);

% export plot as png
exportgraphics( ...
	xcorr_plot, ...
	fullfile(dataset_name, ['cross_corr_stats_' dataset_name  '.png']));

% estimates the distance btw the source and the CPA (at 42800 m)
estimate_R = false;
if estimate_R
	distance_from_CPA = (xcorr.cpa_m - xcorr.channel_position_m); % distance btw reference channel and CPA
	xcorr_offset_m = correlation_statistics(:, 1); % cross-correlation offset [m]
	time_peak = correlation_statistics(:, 3); % peak time of cross correlations
	c = 1470;
	
	R = sqrt(((distance_from_CPA^2 + (time_peak.^2).*c^2 - (distance_from_CPA - xcorr_offset_m).^2) ...
		./ (2.*time_peak.*c)).^2 - distance_from_CPA^2);
	R = abs(R);
	
	figure;
	scatter(xcorr_offset_m, R)
	
	figure(correlogram);
	c = 1470;
	dt= -0.2:0.002:0.2;
	distance_from_CPA = 800;
	
	R_med = median(R, 'omitnan');

	d1 = sqrt( ( sqrt(R_med^2+distance_from_CPA^2) - dt*c ).^2 - R_med^2 );
	dsh = distance_from_CPA-d1;
	hold on
	plot(dt,dsh,'k--','LineWidth', 1)
	ylabel('Distance from reference, dx [m]')
	hold off

	fprintf('Estimate value of R: %d\n [m]', R_med);
end

% clear variables
clear xcorr correlogram correlation_statistics xcorr_plot estimate_R
% -----------------------------------------------------------------------%

%% EVENT DETECTION
% %% event detection
% cfg =				cfg.reload_params();		% loads any changes in the configuration file
% eventDetection =	cfg.params.eventDetection;	% event detection parameters
% 
% [events_detected, events_plot] = event_detection(strain_filtered, ...
% 	data.time, ...
% 	data.distance_km);
% 
% % export plot as png
% exportgraphics(events_plot, eventDetection.filename_plot);