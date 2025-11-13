% The DAS-recorded spatio-temporal strain data supporting this analysis is available at:
% https://doi.org/10.18710/Q8OSON

% Replication data for DAS4Tracking - strain data for localization study
% author : Rørstadbotnen, Robin Andre and Landrø, Martin
% publisher : DataverseNO
% year : 2023


%   Name                                Size                    Bytes  Class   
%
%   data                            14707x17188            2022271328  double              
%   info_gauge_length                   1x1                         8  double              
%   info_meta                           1x1                       899  struct              
%   info_nsamples                       1x1                         8  double              
%   info_ntraces                        1x1                         8  double              
%   info_sampling_frequency_Hz          1x1                         8  double              
%   info_sampling_spatial               1x1                         8  double              
%   info_sapmling_interval_s            1x1                         8  double              
%   info_timestamp                     22x11                      484  char                
%   x1_absolute_channel                 1x14707                117656  double              
%   x1_relative_channel                 1x14707                117656  double              
%   x1_time                             1x17188                137504  double

%%
clc
clear all
close all

%% load data from dataset
addpath('Dataset', 'filters', 'plots');

filename = "20220822_122707_to_123037_ch9803_to_ch24509_sample_Freq_78_Hz.mat";
data_struct = load(filename);

%timestamp = data_struct.info_timestamp;
filename_char = char(filename);
datestamp = filename_char(1:4) + "-" + filename_char(5:6) + "-" + filename_char(7:8);
timestamp = filename_char(10:11) + ":" + filename_char(12:13) + ":" + filename_char(14:15);
time_and_date = datestamp + ", " + timestamp;

strain = data_struct.data;

time = data_struct.x1_time;
sampling_interval_s = data_struct.info_sapmling_interval_s;

distance_m = data_struct.x1_absolute_channel;
distance_km = distance_m .* 1e-3;

nb_of_channels = data_struct.info_ntraces;
nb_of_samples = data_struct.info_nsamples;

sampling_frequency_Hz = data_struct.info_sampling_frequency_Hz;
gauge_length = data_struct.info_gauge_length;
channel_distance = distance_m(2) - distance_m(1);

%% butterworth bandpass filter [15 30] Hz

% filter parameters
lower_bp_freq = 15;
higher_bp_freq = 30;
filter_order = 5;
%

strain_bp_filtered = butterworth_bp_filter(strain, lower_bp_freq, higher_bp_freq, filter_order, sampling_frequency_Hz);

%% fk filtering [1450-3400] m/s propagation speed
fk_filter = fk_filter_design([nb_of_channels nb_of_samples], channel_distance, sampling_interval_s);
strain_fk_filtered = fk_filter_filt(strain_bp_filtered, fk_filter);

%% dB scale
strain_dB = 20*log10(abs(strain_fk_filtered) ./ max(abs(strain_fk_filtered), [], "all"));

%% time-space plot

% time-space plot parameters
time_start = 85; time_end = 170; 
distance_min = 50; distance_max = 100;
strain_min_dB = -50; strain_max_dB = -18;
%

% time-space plot
time_space_plot(strain_dB, time, distance_km, ...
    time_start, time_end, distance_min, distance_max, strain_min_dB, strain_max_dB)
subtitle(time_and_date, "FontSize", 12);
%

% export plot as png
filename_export = fullfile('Ror23_article_plots/', 'time_space_plot_ror23_article_whale.png');
exportgraphics(gcf, filename_export);
%

%% strain waveform of a single channel
channel_position_km = 59.52; % channel of interest

% get signal of channel at km = channel_position_km
[~, channel_focus_idx] = min(abs(distance_km - channel_position_km));
channel_focus = strain_fk_filtered(channel_focus_idx, :);
%

% parameters of strain waveform plot
time_start = time(1); time_end = time(end); 
amplitude_min = -1.7 * 1e-9; amplitude_max = 1.7 * 1e-9;
%

% plot strain waveform channel of interest
strain_waveform(channel_focus, time, ...
    time_start, time_end, amplitude_min, amplitude_max)
subtitle({time_and_date, sprintf("Channel at km %.2f", channel_position_km)}, "FontSize", 12);
%

% export plot as png
filename_export = fullfile('Ror23_article_plots/', 'strain_waveform_ror23_article_whale.png');
exportgraphics(gcf, filename_export);
%

%% spectrogram of a single channel
channel_position_km = 59.52; % channel of interest

% get signal of channel at km = channel_position_km
[~, channel_focus_idx] = min(abs(distance_km - channel_position_km));
channel_focus = strain_fk_filtered(channel_focus_idx, :);
%

% STFT parameters
nfft = 4096;
N = 512;
overlap_pct = 0.98;
han_window = hann(N, 'periodic');
%

% spectrogram parameters
time_start = time(1); time_end = time(end); 
frequency_min = 10; frequency_max = 35;
strain_min_dB = -35; strain_max_dB = -5;
%

% plot spectrogram
plot_spectrogram(channel_focus, nfft, N, han_window, overlap_pct, sampling_frequency_Hz, ...
    time_start, time_end, frequency_min, frequency_max, strain_min_dB, strain_max_dB)
subtitle({time_and_date, sprintf("Channel at km %.2f", channel_position_km)}, "FontSize", 12);
%

% export plot as png
filename_export = fullfile('Ror23_article_plots/', 'spectrogram_ror23_article_whale.png');
exportgraphics(gcf, filename_export);
%

%% space-frequency plot

% FFT parameters
nfft = 4096;
%

% space-frequency plot parameters
time_start_fx = 105; time_end_fx = 125; 
time_window_fx = 1.8;

frequency_min = 10; frequency_max = 35;
strain_min_dB = -35; strain_max_dB = -5;
%

% if true, produces animation
get_animation = false;
%

% plot spatio-spectral representation
space_frequency_plot(strain_fk_filtered, distance_km, sampling_frequency_Hz, nfft, time_window_fx, ...
    time_start_fx, time_end_fx, frequency_min, frequency_max, strain_min_dB, strain_max_dB, get_animation);
sgtitle({"Spatio-Spectral Representation", sprintf("From %.2f s to %.2f s", time_start_fx, time_end_fx), time_and_date});
%

% export plot as png
filename_export = fullfile('Ror23_article_plots/', 'spatio_spectral_plot_ror23_article_whale.png');
exportgraphics(gcf, filename_export);
%

%% corss correlation statistics

% correlation parameters
channel_position_km = 59.52; % reference channel distance
offset_xcorr = 300; % maximum offset (m)
max_lag = 0.2;  % maximum time lag (s)
%

% strain signal in selected time interval
time_corr_start = 100; time_corr_end = 103;
t_start_idx = round(time_corr_start / sampling_interval_s);
t_end_idx = round(time_corr_end / sampling_interval_s);
strain_corr = strain_fk_filtered(:, t_start_idx:t_end_idx);
%

% plot correlogram
correlogram(strain_corr, sampling_frequency_Hz, distance_m, ...
    channel_position_km, offset_xcorr, max_lag)
subtitle({sprintf('Signals duration: from %.2f s to %.2f s', time_corr_start, time_corr_end), time_and_date}, 'FontSize', 12);
%

% export plot as png
filename_export = fullfile('Ror23_article_plots/', 'correlogram_ror23_article_whale.png');
exportgraphics(gcf, filename_export);
%

% txt file name (for correlation statistics)
filename_corr_stats = fullfile('Ror23_article_plots/', 'correlation_statistics_ror23_article_whale.txt');
%

% plot correlation statistics and export data to txt file
correlation_statistics(strain_corr, sampling_frequency_Hz, distance_m, ...
    channel_distance, channel_position_km, offset_xcorr, max_lag, filename_corr_stats)
sgtitle({sprintf('Cross-correlation (Ref: %.3f km, max offset: %d m)', channel_position_km, offset_xcorr), ...
        sprintf('Signals duration: from %.2f s to %.2f s', time_corr_start, time_corr_end), time_and_date});
%

% export plot as png
filename_export = fullfile('Ror23_article_plots/', 'correlation_statistics_ror23_article_whale.png');
exportgraphics(gcf, filename_export);
%