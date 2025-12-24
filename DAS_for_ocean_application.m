%%
clc
clear all
close all

%% load data from dataset
addpath('Dataset', 'filters', 'plots');

% Dataset available:	DAS4Whale_Bou22
%						DAS4Tracking_Ror23
%						DAS4Tracking_airgun_inner
%						DAS4Tracking_airgun_outer
%						Norway

cfg =		ConfigManager('Norway');
data =		cfg.data; % load data from dataset

%% butterworth bandpass filter
cfg =		cfg.reload_params();	% loads any changes in the configuration file
bpFilter =	cfg.params.bpFilter;	% bandpass filter parameters

% filter parameters
cutoff_frequency = bpFilter.cutoff_freq;

% apply filter
strain_filtered = butterworth_bp_filter(data.strain, ...
	cutoff_frequency, ...
	bpFilter.order, ...
	data.sampling_frequency_Hz);

%% median filter 2D 3x3 symmetric
cfg =				cfg.reload_params();		% loads any changes in the configuration file
medianFilter2D =	cfg.params.medianFilter2D;	% fk filter parameters

% filter parameters
filter_dimensions = medianFilter2D.dimensions;

% apply filter
strain_filtered = median_filter_2D(strain_filtered, filter_dimensions);

%% fk filtering
cfg =		cfg.reload_params();	% loads any changes in the configuration file
fkFilter =	cfg.params.fkFilter;	% fk filter parameters

fk_filter =	fk_filter_design(data.dimensions, ...
	data.channel_distance_m, ...
	data.sampling_interval_s, ...
	'c_range', fkFilter.c_range);

strain_filtered = fk_filter_filt(strain_filtered, ...
	fk_filter);

%% dB scale
strain_dB = 20*log10(abs(strain_filtered) ./ max(abs(strain_filtered), [], "all"));

%% time-space plot
cfg =		cfg.reload_params();	% loads any changes in the configuration file
txPlot =	cfg.params.txPlot;		% time-space plot parameters

% function parameters
time_lim =		txPlot.time_lim;		% [1x2] start and end time of plot time interval [s]
distance_lim =	txPlot.distance_lim;	% [1x2] minimum and maximum plot distance [km]
strain_lim =	txPlot.strain_lim;		% [1x2] minimum and maximum plot strain [dB]

% time-space plot
time_space_plot = get_time_space_plot(strain_dB, ...
	data.time, ...
	data.distance_km, ...
    'time_lim', time_lim, ...
	'distance_lim', distance_lim, ...
	'strain_lim', strain_lim);

hold on;

% propagation speed line
c = txPlot.prop_speed_km_s; % propagation speed [km/s]
x_p = txPlot.speed_line_points(1);
y_p = txPlot.speed_line_points(2);
prop_speed = ( c .* (data.time - x_p) ) + y_p;
plot(data.time, prop_speed, 'w--', 'LineWidth', 1);
prop_speed_txt = ['c = ', num2str(c * 1e3), ' [m/s]  '];
text(x_p, y_p, prop_speed_txt, 'Color', 'white', 'FontSize', 12, 'HorizontalAlignment','right');

% position of interest
yline(txPlot.cpa_km, '--', 'CPA','LineWidth', 1, 'Color', '#FFD1DF');
yline(txPlot.channel_position_km, '--', 'far from CPA', 'LineWidth', 1, 'Color', '#D1FFBD');

hold off;

% export plot as png
%exportgraphics(time_space_plot, txPlot.filename);

%% strain waveform of a single channel
cfg =		cfg.reload_params();	% loads any changes in the configuration file
waveform =	cfg.params.waveform;	% strain waveform parameters

% function parameters
channel_position_km =	waveform.channel_position_km;	% position of target channel [km]
time_lim =				waveform.time_lim;				% [1x2] start and end time of plot time interval [s]
strain_lim =			waveform.strain_lim;			% [1x2] lower and higher amplitude limit

% plot strain waveform channel of interest
strain_waveform = get_strain_waveform(strain_filtered, ...
	data.distance_km, ...
	data.time, ...
	channel_position_km, ...
	'time_lim', time_lim, ...
	'strain_lim', strain_lim);

% export plot as png
exportgraphics(strain_waveform, waveform.filename_plot);

%% spectrogram of a single channel
cfg =			cfg.reload_params();		% loads any changes in the configuration file
spectrogram =	cfg.params.spectrogram;		% spectrogram parameters

% function parameters
channel_position_km =	spectrogram.channel_position_km;	% position of target channel [km]
time_lim =				spectrogram.time_lim;				% [1x2] start and end time of plot time interval [s]
frequency_lim =			spectrogram.frequency_lim;			% [1x2] minimum and maximum plot frequency [Hz]
strain_lim =			spectrogram.strain_lim;				% [1x2] minimum and maximum plot strain [dB]

% plot spectrogram
spectrogram_plot = get_spectrogram(strain_filtered, ...
	data.distance_km, ...
	data.sampling_frequency_Hz, ...
	channel_position_km, ...
	spectrogram.nfft, ...
	spectrogram.window_len, ...
	spectrogram.window, ...
	spectrogram.overlap_pct, ...
	'time_lim', time_lim, ...
	'frequency_lim', frequency_lim, ...
	'strain_lim', strain_lim);

% export plot as png
exportgraphics(spectrogram_plot, spectrogram.filename);

%% space-frequency plot
cfg =		cfg.reload_params();	% loads any changes in the configuration file
fxPlot =	cfg.params.fxPlot;		% space-frequency plot parameters

% function parameters
time_window =		fxPlot.time_window;			% duration of each fx plot [s]
time_interval =		fxPlot.time_interval;		% [1x2] start and end time of plot time interval [s]
frequency_lim =		fxPlot.frequency_lim;		% [1x2] minimum and maximum plot frequency [Hz]
strain_lim =		fxPlot.strain_lim;			% [1x2] minimum and maximum plot strain [dB]

% plot spatio-spectral representation
space_frequency_plot = get_space_frequency_plot(strain_filtered, ...
	data.distance_km, ...
	data.sampling_frequency_Hz, ...
	fxPlot.nfft, ...
	time_window, ...
	time_interval, ...
	'frequency_lim', frequency_lim, ...
	'strain_lim', strain_lim);

% export plot as png
exportgraphics(space_frequency_plot, fxPlot.filename);

%% corss correlation statistics
cfg =			cfg.reload_params();	% loads any changes in the configuration file
correlation =	cfg.params.correlation;	% corss-correlation analysis parameters

% function parameters
channel_position_km =	correlation.channel_position_km;	% position of target channel [km]
offset_m =				correlation.offset_m;				% offset for correlation analysis
time_lag =				correlation.time_lag;				% time lag for correlation analysis
time_interval =			correlation.time_interval;			% time interval for correlation analysis

% plot correlogram
correlogram = get_correlogram(strain_filtered, ...
	data.sampling_frequency_Hz, ...
	data.distance_m, ...
    channel_position_km, ...
	offset_m, ...
	time_lag, ...
	time_interval);

% export plot as png
exportgraphics(correlogram, correlation.filename_correlogram);

% plot correlation statistics and export data to csv file
[correlation_statistics, xcorr_plot] = get_correlation_statistics(strain_filtered, ...
	data.sampling_frequency_Hz, ...
	data.distance_m, ...
	data.channel_distance_m, ...
	channel_position_km, ...
	offset_m, ...
	time_lag, ...
	time_interval);

% export plot as png
exportgraphics(xcorr_plot, correlation.filename_xcorr);

% estimates the distance btw the source and the CPA (at 42.8 km)
estimate_R = true;
if estimate_R
	distance_from_CPA = (cfg.params.txPlot.cpa_km - channel_position_km)*1e3; % distance btw reference channel and CPA
	xcorr_offset_m = correlation_statistics(:, 1); % cross-correlation offset [m]
	time_peak = correlation_statistics(:, 3); % peak time of cross correlations
	c = 1470;
	
	R = sqrt(((distance_from_CPA^2 + (time_peak.^2).*c^2 - (distance_from_CPA - xcorr_offset_m).^2) ...
		./ (2.*time_peak.*c)).^2 - distance_from_CPA^2);
	
	figure;
	plot(xcorr_offset_m, R)
	
	figure(correlogram);
	c = 1470;
	dt= -0.2:0.002:0.2;
	distance_from_CPA = 800;
	
	d1 = sqrt( ( sqrt(R.^2+distance_from_CPA^2) - dt*c ).^2 - R.^2 );
	dsh = distance_from_CPA-d1;
	hold on
	plot(dt,dsh,'k--','LineWidth', 1)
	ylabel('Distance from reference, dx [m]')
	hold off
end

%% event detection
cfg =				cfg.reload_params();		% loads any changes in the configuration file
eventDetection =	cfg.params.eventDetection;	% event detection parameters

[events_detected, events_plot] = event_detection(strain_filtered, ...
	data.time, ...
	data.distance_km);

% export plot as png
exportgraphics(events_plot, eventDetection.filename_plot);