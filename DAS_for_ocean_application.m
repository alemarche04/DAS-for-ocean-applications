%%
clc
clear all
close all

%% load data from dataset
addpath('Dataset', 'filters', 'plots');

% Dataset available: DAS4Whale_bou22, DAS4Tracking_ror23
cfg =		ConfigManager('DAS4Whale_bou22');
data =		cfg.data; % load data from dataset

%% butterworth bandpass filter
cfg =		cfg.reload_params();	% loads any changes in the configuration file
bpFilter =	cfg.params.bpFilter;	% bandpass filter parameters

strain_bp_filtered = butterworth_bp_filter(data.strain, ...
	bpFilter.cutoff_freq, ...
	bpFilter.order, ...
	data.sampling_frequency_Hz);

%% fk filtering
cfg =		cfg.reload_params();	% loads any changes in the configuration file
fkFilter =	cfg.params.fkFilter;	% fk filter parameters

fk_filter =	fk_filter_design(data.dimensions, ...
	data.channel_distance_m, ...
	data.sampling_interval_s, ...
	'c_range', fkFilter.c_range);

strain_fk_filtered = fk_filter_filt(strain_bp_filtered, ...
	fk_filter);

%% dB scale
strain_dB = 20*log10(abs(strain_fk_filtered) ./ max(abs(strain_fk_filtered), [], "all"));

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
yline(txPlot.cpa_km, '--', 'CPA','LineWidth', 1, 'Color', '#FFA500');
yline(txPlot.channel_position_km, '--', 'far from CPA', 'LineWidth', 1, 'Color', '#B2EC5D');

hold off;

% export plot as png
exportgraphics(time_space_plot, txPlot.filename);

%% strain waveform of a single channel
cfg =		cfg.reload_params();	% loads any changes in the configuration file
waveform =	cfg.params.waveform;	% strain waveform parameters

% function parameters
channel_position_km =	waveform.channel_position_km;	% position of target channel [km]
time_lim =				waveform.time_lim;				% [1x2] start and end time of plot time interval [s]
strain_lim =			waveform.strain_lim;			% [1x2] lower and higher amplitude limit

% plot strain waveform channel of interest
strain_waveform = get_strain_waveform(strain_fk_filtered, ...
	data.distance_km, ...
	data.time, ...
	channel_position_km, ...
	'time_lim', time_lim, ...
	'strain_lim', strain_lim);

% export plot as png
exportgraphics(strain_waveform, waveform.filename_plot);

% export audio file
audiowrite(waveform.filename_audio, strain_fk_filtered(channel_position_idx, :), round(data.sampling_frequency_Hz*3));

%% spectrogram of a single channel
cfg =			cfg.reload_params();		% loads any changes in the configuration file
spectrogram =	cfg.params.spectrogram;		% spectrogram parameters

% function parameters
channel_position_km =	spectrogram.channel_position_km;	% position of target channel [km]
time_lim =				spectrogram.time_lim;				% [1x2] start and end time of plot time interval [s]
frequency_lim =			spectrogram.frequency_lim;			% [1x2] minimum and maximum plot frequency [Hz]
strain_lim =			spectrogram.strain_lim;				% [1x2] minimum and maximum plot strain [dB]

% plot spectrogram
spectrogram_plot = get_spectrogram(strain_fk_filtered, ...
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
space_frequency_plot = get_space_frequency_plot(strain_fk_filtered, ...
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
crossCorr =		cfg.params.crossCorr;	% corss-correlation analysis parameters

% function parameters
channel_position_km =	crossCorr.channel_position_km;	% position of target channel [km]
offset_m =				crossCorr.offset_m;				% offset for correlation analysis
time_lag =				crossCorr.time_lag;				% time lag for correlation analysis
time_interval =			crossCorr.time_interval;		% time interval for correlation analysis

% plot correlogram
correlogram = get_correlogram(strain_fk_filtered, ...
	data.sampling_frequency_Hz, ...
	data.distance_m, ...
    channel_position_km, ...
	offset_m, ...
	time_lag, ...
	time_interval);

% export plot as png
exportgraphics(correlogram, crossCorr.filename_corrlogram);

% plot correlation statistics and export data to txt file
correlation_statistics = get_correlation_statistics(strain_fk_filtered, ...
	data.sampling_frequency_Hz, ...
	data.distance_m, ...
	data.channel_distance_m, ...
	channel_position_km, ...
	offset_m, ...
	time_lag, ...
	time_interval, ...
	crossCorr.filename);

% export plot as png
exportgraphics(correlation_statistics, filename_export);