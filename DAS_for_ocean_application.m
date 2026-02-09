%%
clc
clear all
close all

%% load data from dataset
addpath('Dataset', 'Dataset_Norway', 'filters', 'plots', 'config');

% Dataset available:	
%		DAS4Whale_Bou22
%		Norway
% Dataset not yet available:
%		DAS4Tracking_Ror23
%		DAS4Tracking_airgun_inner
%		DAS4Tracking_airgun_outer


dataset_name	= 'DAS4Whale_Bou22';
DAS				= feval(str2func(dataset_name + "_cfg"));
data			= DAS.load_data();

%% cable geometry and source position

if strcmp(dataset_name, 'Norway')
	
	% plot cable geometry
	geo_origin = DAS.plot_cable_geometry_2D();
	exportgraphics( ...
	gcf, ...
	fullfile(dataset_name, ['cable_geometry_' dataset_name  '.png']));

	% source position first run
	t_start_run1 = duration(10, 59, 19);
	t_end_run1 = duration(11, 47, 29);
	source_run1 = DAS.sourcePos(t_start_run1, t_end_run1);
	
	% source position second run
	t_start_run2 = duration(12, 12, 23);
	t_end_run2 = duration(13, 00, 33);
	source_run2 = DAS.sourcePos(t_start_run2, t_end_run2);

	% source position third run
	t_start_run3 = duration(13, 09, 50);
	t_end_run3 = duration(13, 47, 10);
	source_run3 = DAS.sourcePos(t_start_run3, t_end_run3);

	% plot cable geometry and rouce postion 2D
	DAS.plot_source_pos_all_2D(source_run1, source_run2, source_run3, geo_origin);

	exportgraphics( ...
	gcf, ...
	fullfile(dataset_name, ['cable_source_' dataset_name  '.png']));

	% plot cable geometry and rouce postion 3D
	DAS.plot_calbe_source_3D(source_run1, source_run2, source_run3);
	
end

%% butterworth bandpass filter

% parameters
bp = DAS.bandpass();
bp_cutoff_freq		= bp.bp_cutoff_freq;
bp_order			= bp.bp_order;

% apply filter
strain_filtered = butterworth_bp_filter( ...
	data.strain, ...
	bp_cutoff_freq, ...
	bp_order, ...
	data.sampling_frequency_Hz);

%% median filter 2D 3x3 symmetric

% parameters
medFilt = DAS.medFilt();
med_filt2D_dim = medFilt.med_filt2D_dim;

% apply filter
strain_filtered = median_filter_2D( ...
	strain_filtered, ...
	med_filt2D_dim);

%% fk filtering

% parameters
fkFilt = DAS.fkFilt();
fk_velocity_range = fkFilt.fk_velocity_range;

fk_filter =	fk_filter_design( ...
	data.dimensions, ...
	data.channel_distance_m, ...
	data.sampling_interval_s);

strain_filtered = fk_filter_filt( ...
	strain_filtered, ...
	fk_filter);

%% dB scale
strain_dB = 20*log10(abs(strain_filtered) ./ max(abs(strain_filtered), [], "all"));

%% time-space plot

% parameters
tx = DAS.tx_plot();
tx_time_lim					= tx.tx_time_lim;
tx_distance_lim				= tx.tx_distance_lim;
tx_strain_lim				= tx.tx_strain_lim;
tx_prop_speed_km_s			= tx.tx_prop_speed_km_s;
tx_speed_line_points		= tx.tx_speed_line_points;
tx_channel_position_km		= tx.tx_channel_position_km;
tx_cpa_km					= tx.tx_cpa_km;

% time-space plot
time_space_plot = get_time_space_plot( ...
	strain_dB, ...
	data.time, ...
	data.distance_km, ...
	'subtitle', data.time_and_date, ...
    'time_lim', tx_time_lim, ...
	'distance_lim', tx_distance_lim, ...
	'strain_lim', tx_strain_lim);

% % draw propagation speed lines on time-space plot
% hold on;
% draw_prop_speed_lines( ...
% 	data.time, ...
% 	tx_prop_speed_km_s, ...
% 	tx_speed_line_points, ...
% 	tx_cpa_km, ...
% 	tx_channel_position_km);
% hold off;

% export plot as png
exportgraphics( ...
	time_space_plot, ...
	fullfile(dataset_name, ['time_space_plot_' dataset_name  '.png']));

%% strain waveform of a single channel

% parameters
wf = DAS.waveform();
wf_channel_position_km		= wf.wf_channel_position_km;
wf_cpa_km					= wf.wf_cpa_km;
wf_time_lim					= wf.wf_time_lim;
wf_strain_lim				= wf.wf_strain_lim;
filename_audio				= wf.filename_audio;

% plot strain waveform channel of interest
strain_waveform = get_strain_waveform( ...
	strain_filtered, ...
	data.distance_km, ...
	data.time, ...
	wf_channel_position_km, ...
	filename_audio, ...
	data.sampling_frequency_Hz, ...
	'subtitle', data.time_and_date, ...
	'time_lim', wf_time_lim, ...
	'strain_lim', wf_strain_lim);

% export plot as png
exportgraphics( ...
	strain_waveform, ...
	fullfile(dataset_name, ['strain_waveform_' dataset_name  '.png']));

%% spectrogram of a single channel

% parameters
sg = DAS.spectrogram();
sg_channel_position_km		= sg.sg_channel_position_km;
sg_nfft						= sg.sg_nfft;
sg_window_len				= sg.sg_window_len;
sg_window					= sg.sg_window;
sg_overlap_pct				= sg.sg_overlap_pct;
sg_time_lim					= sg.sg_time_lim;
sg_frequency_lim			= sg.sg_frequency_lim;
sg_strain_lim				= sg.sg_strain_lim;


% plot spectrogram
spectrogram_plot = get_spectrogram( ...
	strain_filtered, ...
	data.distance_km, ...
	data.sampling_frequency_Hz, ...
	sg_channel_position_km, ...
	sg_nfft, ...
	sg_window_len, ...
	sg_window, ...
	sg_overlap_pct, ...
	'subtitle', data.time_and_date, ...
	'time_lim', sg_time_lim, ...
	'frequency_lim', sg_frequency_lim, ...
	'strain_lim', sg_strain_lim);

% export plot as png
exportgraphics( ...
	spectrogram_plot, ...
	fullfile(dataset_name, ['spectrogram_' dataset_name  '.png']));

%% space-frequency plot

% parameters
fx = DAS.fx_plot();
fx_nfft				= fx.fx_nfft;
fx_time_interval	= fx.fx_time_interval;
fx_time_window		= fx.fx_time_window;
fx_frequency_lim	= fx.fx_frequency_lim;
fx_strain_lim		= fx.fx_strain_lim;
filename_animation	= fx.filename_animation;

% plot spatio-spectral representation
space_frequency_plot = get_space_frequency_plot( ...
	strain_filtered, ...
	data.distance_km, ...
	data.sampling_frequency_Hz, ...
	fx_nfft, ...
	fx_time_window, ...
	fx_time_interval, ...
	filename_animation, ...
	'subtitle', data.time_and_date, ...
	'frequency_lim', fx_frequency_lim, ...
	'strain_lim', fx_strain_lim, ...
	'get_animation', true);

% export plot as png
exportgraphics( ...
	space_frequency_plot, ...
	fullfile(dataset_name, ['fx_plot_' dataset_name  '.png']));

%% corss correlation statistics

% parameters
xcorr = DAS.correlation();
corr_channel_position_km	= xcorr.corr_channel_position_km;
corr_offset_m				= xcorr.corr_offset_m;
corr_time_lag				= xcorr.corr_time_lag;
corr_time_interval			= xcorr.corr_time_interval;
corr_cpa_km					= xcorr.corr_cpa_km;
filename_xcorr_table		= xcorr.filename_xcorr_table;

% plot correlogram
correlogram = get_correlogram( ...
	strain_filtered, ...
	data.sampling_frequency_Hz, ...
	data.distance_m, ...
    corr_channel_position_km, ...
	corr_offset_m, ...
	corr_time_lag, ...
	corr_time_interval, ...
	'subtitle', data.time_and_date);

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
	corr_channel_position_km, ...
	corr_offset_m, ...
	corr_time_lag, ...
	corr_time_interval, ...
	filename_xcorr_table, ...
	'subtitle', data.time_and_date);

% export plot as png
exportgraphics( ...
	xcorr_plot, ...
	fullfile(dataset_name, ['cross_corr_stats_' dataset_name  '.png']));

% estimates the distance btw the source and the CPA (at 42.8 km)
estimate_R = false;

if estimate_R
	distance_from_CPA = (corr_cpa_km - corr_channel_position_km)*1e3; % distance btw reference channel and CPA
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

	fprintf('Estimate value of R: %d\n', R_med);
end

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