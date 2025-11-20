% The DAS-recorded spatio-temporal strain data supporting this analysis is available at:
% https://doi.org/10.5281/zenodo.5823343

% DAS4Whale: Svalbard distributed acoustic sensing dataset for baleen whale monitoring
% author : Léa Bouffaut and Kittinat Taweesintananon
% year : 2022,
% publisher : Zenodo


%   Name                               Size                     Bytes  Class    
% 
%   data                            5000x103217            4128680000  double              
%   info_DAS_meta_raw                  1x1                     258991  struct              
%   info_GL_m                          1x1                          8  double              
%   info_SSI_m                         1x1                          8  double              
%   info_nsamples                      1x1                          8  int64               
%   info_ntraces                       1x1                          8  int64               
%   info_sample_interval_s             1x1                          8  double              
%   info_sampling_frequency_Hz         1x1                          8  double              
%   info_timestamp                     1x17                        34  char                
%   info_units                         3x23                       138  char                
%   x1_absolute_channel                1x5000                   40000  int64               
%   x1_distance_from_shore_m           1x5000                   40000  double              
%   x1_position_m                      1x5000                   40000  double              
%   x1_recwdepthz_m                    1x5000                   40000  double              
%   x1_relative_channel                1x5000                   40000  int64               
%   x2_time_s                          1x103217                825736  double              

%%
clc
clear all
close all

%% load data from dataset
addpath('Dataset', 'filters', 'plots');

filename = "20200627_052441_ch10001_to_ch15000_whale_raw_L160s.mat";
data_struct = load(filename);

time_and_date = "2020-06-27, 05:24:41";

strain = data_struct.data;

time = data_struct.x2_time_s;
sampling_interval_s = data_struct.info_sample_interval_s;

distance_m = data_struct.x1_distance_from_shore_m;
distance_km = distance_m .* 1e-3;

nb_of_channels = data_struct.info_ntraces;
nb_of_samples = data_struct.info_nsamples;

sampling_frequency_Hz = data_struct.info_sampling_frequency_Hz;
gauge_length = data_struct.info_GL_m;
channel_distance = distance_m(2) - distance_m(1);

%% butterworth bandpass filter [5-75] Hz

% filter parameters
lower_bp_freq = 5;
higher_bp_freq = 75;
filter_order = 5;
%

strain_bp_filtered = butterworth_bp_filter(strain, lower_bp_freq, higher_bp_freq, filter_order, sampling_frequency_Hz);

%% fk filtering [1450-3400] m/s propagation speed
fk_filter = fk_filter_design([nb_of_channels nb_of_samples], channel_distance, sampling_interval_s);
strain_fk_filtered = fk_filter_filt(strain_bp_filtered, fk_filter);

%% dB scale
strain_dB = 20*log10(abs(strain_fk_filtered) ./ max(abs(strain_fk_filtered), [], "all"));

%% time-space plot

% time-space plot
tx_plot = time_space_plot(strain_dB, time, distance_km, 'strain_min', -30, 'strain_max', -5);
subtitle(time_and_date, "FontSize", 12);
%

% propagation speed line
c = 1.47; % propagation speed [km/s]
hold on;
x_p = 46.2;
y_p = 43.2;
prop_speed = ( c .* (time - x_p) ) + y_p;
plot(time, prop_speed, 'w--', 'LineWidth', 1);
prop_speed_txt = ['c = ', num2str(c * 1e3), '[m/s]  '];
text(46.4, 47.3, prop_speed_txt, 'Color', 'white', 'FontSize', 12, 'HorizontalAlignment','right');
hold off;


% position of interest
yline(42.8, '--', 'CPA','LineWidth', 1, 'Color', '#FFA500');
yline(42, '--', 'far from CPA', 'LineWidth', 1, 'Color', '#B2EC5D');

% export plot as png
filename_export = fullfile('Bou22_article_plots/', 'time_space_plot_bou22_article_whale.png');
exportgraphics(tx_plot, filename_export);
%

%% strain waveform of a single channel

% waveform of channel of interest
channel_position_km = 42; % channel of interest

% get signal of channel at km = channel_position_km
[~, channel_focus_idx] = min(abs(distance_km - channel_position_km));
channel_focus = strain_fk_filtered(channel_focus_idx, :) .* 1e-9;
%

% plot strain waveform channel of interest
waveform = strain_waveform(channel_focus, time, 'amplitude_min', -1.3*1e-9, 'amplitude_max', 1.3*1e-9);
subtitle({sprintf("Channel at km %.2f", channel_position_km), time_and_date}, "FontSize", 12);
%

% detail of whale vocalization
figure;
plot(time, channel_focus);
time_detail_start = 48; time_detail_end = 49;
xlim([time_detail_start time_detail_end]);
ylim([-1.3*1e-9 1.3*1e-9]);
title('Detail: whale vocalization', 'FontSize', 14, 'FontWeight', 'bold');
subtitle(sprintf('from %.1f s to %.1f s', time_detail_start, time_detail_end), 'FontSize', 12);
%

% export plot as png
filename_export = fullfile('Bou22_article_plots/', 'strain_waveform_bou22_article_whale.png');
exportgraphics(waveform, filename_export);
%

% export audio file
filename_export = fullfile('Bou22_article_plots/', 'strain_audio_bou22_article_whale.wav');
audiowrite(filename_export, (channel_focus .* 1e9), round(sampling_frequency_Hz*3));
%

%% waveform of closest point of approach (CPA)
CPA_position_km = 42.8; % closest point of apporach

% get signal of channel at km = CPA_position_km
[~, CPA_idx] = min(abs(distance_km - CPA_position_km));
channel_CPA = strain_fk_filtered(CPA_idx, :) .* 1e-9;
%

% plot strain waveform closest point of approach
waveform_CPA = strain_waveform(channel_CPA, time, 'amplitude_min', -1.3*1e-9, 'amplitude_max', 1.3*1e-9);
subtitle({sprintf("Channel at km %.2f (closest point of approach)", CPA_position_km), time_and_date}, "FontSize", 12);
%

% export plot as png
filename_export = fullfile('Bou22_article_plots/', 'strain_waveform_CPA_bou22_article_whale.png');
exportgraphics(waveform_CPA, filename_export);
%

%% spectrogram of a single channel
channel_position_km = 42; % channel of interest

% get signal of channel at km = channel_position_km
[~, channel_focus_idx] = min(abs(distance_km - channel_position_km));
channel_focus = strain_fk_filtered(channel_focus_idx, :);
%

% STFT parameters
nfft = 4096; % number of FFT samples
N = 512; % window length
overlap_pct = 0.98; % overlap pencentage
han_window = hann(N, 'periodic'); % spectral window
%

% plot spectrogram
spectrogram = plot_spectrogram(channel_focus, nfft, N, han_window, overlap_pct, sampling_frequency_Hz, ...
    'frequency_min', 10, 'frequency_max', 80, 'strain_min', -25, 'strain_max', 0);
subtitle({sprintf("Channel at km %.2f", channel_position_km), time_and_date}, "FontSize", 12);
%

% export plot as png
filename_export = fullfile('Bou22_article_plots/', 'spectrogram_bou22_article_whale.png');
exportgraphics(spectrogram, filename_export);
%

%% space-frequency plot

% FFT parameters
nfft = 4096;
%

% space-frequency plot parameters
time_start_fx = 44; time_end_fx = 67; 
time_window_fx = 1.5;
%

% plot spatio-spectral representation
fx_plot = space_frequency_plot(strain_fk_filtered, distance_km, sampling_frequency_Hz, nfft, time_window_fx, ...
    time_start_fx, time_end_fx, 'frequency_min', 5, 'frequency_max', 75, 'strain_min', -20, 'strain_max', -5);
sgtitle({"Spatio-Spectral Representation", sprintf("From %.2f s to %.2f s", time_start_fx, time_end_fx), time_and_date});
%

% export plot as png
filename_export = fullfile('Bou22_article_plots/', 'spatio_spectral_plot_bou22_article_whale.png');
exportgraphics(fx_plot, filename_export);
%

%% corss correlation statistics

% correlation parameters
channel_position_km = 42; % reference channel distance
offset_xcorr = 300; % maximum offset (m)
max_lag = 0.2; % maximum time lag (s)
%

%% correlation of signals during whale call

% time interval
time_corr_start = 47; time_corr_end = 50;
%

% plot correlogram
correlogram_plot = correlogram(strain_fk_filtered, sampling_frequency_Hz, distance_m, ...
    channel_position_km, offset_xcorr, max_lag, time_corr_start, time_corr_end);
subtitle({sprintf('Signals duration: from %.2f s to %.2f s', time_corr_start, time_corr_end), time_and_date}, 'FontSize', 12);
%

% export plot as png
filename_export = fullfile('Bou22_article_plots/', 'correlogram_bou22_article_whale.png');
exportgraphics(correlogram_plot, filename_export);
%

% txt file name (for correlation statistics)
filename_corr_stats = fullfile('Bou22_article_plots/', 'correlation_statistics_bou22_article_whale.txt');
%

% plot correlation statistics and export data to txt file
xcorr_plot = correlation_statistics(strain_fk_filtered, sampling_frequency_Hz, distance_m, channel_distance, ...
    channel_position_km, offset_xcorr, max_lag, time_corr_start, time_corr_end, filename_corr_stats);
sgtitle({sprintf('Cross-correlation (Ref: %.3f km, max offset: %d m)', channel_position_km, offset_xcorr), ...
        sprintf('Signals duration: from %.2f s to %.2f s', time_corr_start, time_corr_end), time_and_date});
%

% export plot as png
filename_export = fullfile('Bou22_article_plots/', 'correlation_statistics_bou22_article_whale.png');
exportgraphics(xcorr_plot, filename_export);
%

%% correlation of noise signals

% strain signal in selected time interval
time_corr_start = 20; time_corr_end = 23;
%

% plot correlogram
correlogram_plot_noise = correlogram(strain_fk_filtered, sampling_frequency_Hz, distance_m, ...
    channel_position_km, offset_xcorr, max_lag, time_corr_start, time_corr_end);
subtitle({sprintf('Signals duration: from %.2f s to %.2f s', time_corr_start, time_corr_end), time_and_date}, 'FontSize', 12);
%

% export plot as png
filename_export = fullfile('Bou22_article_plots/', 'correlogram_noise_bou22_article_whale.png');
exportgraphics(correlogram_plot_noise, filename_export);
%

% txt file name (for correlation statistics)
filename_corr_stats = fullfile('Bou22_article_plots/', 'correlation_statistics_noise_bou22_article_whale.txt');
%

% plot correlation statistics and export data to txt file
xcorr_plot_noise = correlation_statistics(strain_fk_filtered, sampling_frequency_Hz, distance_m, channel_distance, ...
    channel_position_km, offset_xcorr, max_lag, time_corr_start, time_corr_end, filename_corr_stats);
sgtitle({'Correlation', sprintf('Signals duration: from %.2f s to %.2f s', time_corr_start, time_corr_end), time_and_date});
%

% export plot as png
filename_export = fullfile('Bou22_article_plots/', 'correlation_statistics_noise_bou22_article_whale.png');
exportgraphics(xcorr_plot_noise, filename_export);
%