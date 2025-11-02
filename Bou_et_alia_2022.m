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

%timestamp = data_struct.info_timestamp;
filename_char = char(filename);
datestamp = filename_char(1:4) + "-" + filename_char(5:6) + "-" + filename_char(7:8);
timestamp = filename_char(10:11) + ":" + filename_char(12:13) + ":" + filename_char(14:15);
time_and_date = datestamp + " " + timestamp;

strain = data_struct.data;

time = data_struct.x2_time_s;
sampling_interval_s = data_struct.info_sample_interval_s;

distance_m = data_struct.x1_position_m;
distance_km = distance_m .* 1e-3;

nb_of_channels = data_struct.info_ntraces;
nb_of_samples = data_struct.info_nsamples;

sampling_frequency_Hz = data_struct.info_sampling_frequency_Hz;
gauge_length = data_struct.info_GL_m;
channel_distance = distance_m(2) - distance_m(1);

%% butterworth bandpass filter [20 45] Hz
lower_bp_freq = 20;
higher_bp_freq = 45;
filter_order = 5;

strain_bp_filtered = butterworth_bp_filter(strain, lower_bp_freq, higher_bp_freq, filter_order, sampling_frequency_Hz);

%% fk filtering [1450-3400] m/s propagation speed
fk_filter = fk_filter_design([nb_of_channels nb_of_samples], channel_distance, sampling_interval_s);
strain_fk_filtered = fk_filter_filt(strain_bp_filtered, fk_filter);

%% dB scale
strain_dB = 20*log10(abs(strain_fk_filtered) ./ max(abs(strain_fk_filtered), [], "all"));

%% time-space plot
time_start = time(1); time_end = time(end); 
distance_min = distance_km(1); distance_max = distance_km(end);
strain_min_dB = -30; strain_max_dB = -5;

time_space_plot(strain_dB, time, distance_km, ...
    time_start, time_end, distance_min, distance_max, strain_min_dB, strain_max_dB)
subtitle(time_and_date, "FontSize", 12);

filename_export = fullfile('Bou22_article_plots/', 'time_space_plot_bou22_article_whale.png');
%exportgraphics(gca, filenae_export);

%% strain waveform of a single channel
channel_position_km = 44.2; % channel of interest

[~, channel_focus_idx] = min(abs(distance_km - channel_position_km));
channel_focus = strain_fk_filtered(channel_focus_idx, :) .* 1e-9;

time_start = time(1); time_end = time(end); 
amplitude_min = -0.7 * 1e-9; amplitude_max = 0.7 * 1e-9;

strain_waveform(channel_focus, time, ...
    time_start, time_end, amplitude_min, amplitude_max)

filename_export = fullfile('Bou22_article_plots/', 'strain_waveform_bou22_article_whale.png');
%exportgraphics(gca, filenae_export);

%% spectrogram of a single channel
channel_position_km = 44.2; % channel of interest

[~, channel_focus_idx] = min(abs(distance_km - channel_position_km));
channel_focus = strain_fk_filtered(channel_focus_idx, :);

nfft = 4096;
N = 512;
overlap_pct = 0.98;
han_window = hann(N, 'periodic');

time_start = time(1); time_end = time(end); 
frequency_min = 0; frequency_max = 100;
strain_min_dB = -20; strain_max_dB = 0;

plot_spectrogram(channel_focus, nfft, N, han_window, overlap_pct, sampling_frequency_Hz, ...
    time_start, time_end, frequency_min, frequency_max, strain_min_dB, strain_max_dB)

subtitle(sprintf("Channel at km %0.1f", channel_position_km));

filename_export = fullfile('Bou22_article_plots/', 'spectrogram_bou22_article_whale.png');
%exportgraphics(gca, filenae_export);

%% space-frequency plot
nfft = 4096;

time_start_fx = 44; time_end_fx = 67; 
frequency_min = 10; frequency_max = 50;
strain_min_dB = -20; strain_max_dB = -5;

time_window_fx = 1.5;

get_animation = true;

space_frequency_plot(strain_fk_filtered, distance_km, sampling_frequency_Hz, nfft, time_window_fx, ...
    time_start_fx, time_end_fx, frequency_min, frequency_max, strain_min_dB, strain_max_dB, get_animation);

filename_export = fullfile('Bou22_article_plots/', 'spatio_spectral_plot_bou22_article_whale.png');
%exportgraphics(gca, filenae_export);

%% corss correlation statistics
channel_position_km = 44.2; % reference channel distance
offset_xcorr = 300; % maximum offset (m)
max_lag = 1;  % maximum time lag (s)

time_corr_start = 1; time_corr_end = 1;

strain_corr = strain_fk_filtered(:, time_corr_start:time_corr_end);

correlation(strain_fk_filtered, sampling_frequency_Hz, distance_m, channel_distance, channel_position_km, offset_xcorr, max_lag)