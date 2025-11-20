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

filename = "20220906_175106_to_175436_ch2450_to_ch9191_sample_Freq_125_Hz_outer.mat";
data_struct = load(filename);

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

%% butterworth bandpass filter [5 38] Hz

%filter parameters
lower_bp_freq = 5;
higher_bp_freq = 45;
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
tx_plot = time_space_plot(strain_dB, time, distance_km, 'strain_min', -25, 'strain_max', -10);
subtitle(time_and_date, "FontSize", 12);
%

% export plot as png
filename_export = fullfile('Ror23_airgun/', 'time_space_plot_ror23_airgun_outer.png');
exportgraphics(tx_plot, filename_export);
%

%% strain waveform of a single channel
channel_position_km = 30; % channel of interest

% get signal of channel at km = channel_position_km
[~, channel_focus_idx] = min(abs(distance_km - channel_position_km));
channel_focus = strain_fk_filtered(channel_focus_idx, :);
%

% plot strain waveform channel of interest
waveform = strain_waveform(channel_focus, time, 'amplitude_min', -1.9*1e-10, 'amplitude_max', 1.9*1e-10);
subtitle({sprintf("Channel at km %.2f (closest point of approach)", channel_position_km), time_and_date}, "FontSize", 12);
%

% export plot as png
filename_export = fullfile('Ror23_airgun/', 'strain_waveform_ror23_airgun_outer.png');
exportgraphics(waveform, filename_export);
%

%% spectrogram of a single channel
channel_position_km = 30; % channel of interest

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

% plot spectrogram
spectrogram = plot_spectrogram(channel_focus, nfft, N, han_window, overlap_pct, sampling_frequency_Hz, ...
    'frequency_min', 5, 'frequency_max', 40, 'strain_min', -25, 'strain_max', -2);
subtitle({sprintf("Channel at km %.2f", channel_position_km), time_and_date}, "FontSize", 12);
%

% export plot as png
filename_export = fullfile('Ror23_airgun/', 'spectrogram_ror23_airgun_outer.png');
exportgraphics(spectrogram, filename_export);
%s

%% space-frequency plot

% FFT parameters
nfft = 4096;
%

% space-frequency plot parameters
time_start_fx = 50; time_end_fx = 68; 
time_window_fx = 1.7;
%

% plot spatio-spectral representation
fx_plot = space_frequency_plot(strain_fk_filtered, distance_km, sampling_frequency_Hz, nfft, time_window_fx, ...
    time_start_fx, time_end_fx, 'frequency_min', 10, 'frequency_max', 38, 'strain_min', -25, 'strain_max', -2);
sgtitle({"Spatio-Spectral Representation", sprintf("From %.2f s to %.2f s", time_start_fx, time_end_fx), time_and_date});
%

% export plot as png
filename_export = fullfile('Ror23_airgun/', 'spatio_spectral_plot_ror23_airgun_outer.png');
exportgraphics(fx_plot, filename_export);
%

%% corss correlation statistics

% correlation parameters
channel_position_km = 30; % reference channel distance
offset_xcorr = 80; % maximum offset (m)
max_lag = 0.05;  % maximum time lag (s)
%

% time interval
time_corr_start = 56; time_corr_end = 59;
%

% plot correlogram
correlogram_plot = correlogram(strain_fk_filtered, sampling_frequency_Hz, distance_m, ...
    channel_position_km, offset_xcorr, max_lag, time_corr_start, time_corr_end);
subtitle({sprintf('Signals duration: from %.2f s to %.2f s', time_corr_start, time_corr_end), time_and_date}, 'FontSize', 12);
%

% export plot as png
filename_export = fullfile('Ror23_airgun/', 'correlogram_ror23_airgun_outer.png');
exportgraphics(correlogram_plot, filename_export);
%

% txt file name (for correlation statistics)
filename_corr_stats = fullfile('Ror23_airgun/', 'correlation_statistics_ror23_airgun_outer.txt');
%

% plot correlation statistics and export data to txt file
xcorr_plot = correlation_statistics(strain_fk_filtered, sampling_frequency_Hz, distance_m, channel_distance, ...
    channel_position_km, offset_xcorr, max_lag, time_corr_start, time_corr_end, filename_corr_stats);
sgtitle({sprintf('Cross-correlation (Ref: %.3f km, max offset: %d m)', channel_position_km, offset_xcorr), ...
        sprintf('Signals duration: from %.2f s to %.2f s', time_corr_start, time_corr_end), time_and_date});
%

% export plot as png
filename_export = fullfile('Ror23_airgun/', 'correlation_statistics_ror23_airgun_outer.png');
exportgraphics(xcorr_plot, filename_export);
%