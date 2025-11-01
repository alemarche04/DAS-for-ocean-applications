% The DAS-recorded spatio-temporal strain data supporting this analysis is available at:
% https://doi.org/10.58046/5J60-FJ89

% author : Wilcock & OOI
% year : 2023


% Group '/' 
%     Attributes:
%         'uuid':  '4936778f-6535-441a-9db2-f4f1d3de92d4'
%     Group '/Acquisition' 
%         Attributes:
%             'schemaVersion':  '2.0'
%             'uuid':  '89c88658-cb76-4a1a-bd85-b8e1572e49f5'
%             'AcquisitionId':  '89c88658-cb76-4a1a-bd85-b8e1572e49f5'
%             'NumberOfLoci':  32600
%             'StartLocusIndex':  0
%             'SpatialSamplingInterval':  2.041905
%             'TriggeredMeasurement':  'false'
%             'SpatialSamplingIntervalUnit':  'm'
%             'GaugeLength':  30.628572
%             'GaugeLengthUnit':  'm'
%             'MinimumFrequency':  0.000000
%             'MaximumFrequency':  250.000000
%             'PulseRate':  1000.000000
%             'PulseWidth':  150.000000
%             'PulseWidthUnit':  'ns'
%             'VendorCode':  'OptaSense IU Setup 1.7.3 c5bde49175ee6dc70c95d4b39db648d3fda54a46'
%         Group '/Acquisition/Custom' 
%             Attributes:
%                 'CustomSchemaVersion':  3
%                 'Laser Wavelength (nm)':  1550
%                 'Fibre Refractive Index':  1.468200
%                 'GPS Sync Guaranteed':  1
%                 'CSU Resolution (ns)':  1
%                 'Data Compromised':  0
%                 'Header Schema':  '3.0'
%                 'FPGA Drawing Number':  7804701
%                 'FPGA Version':  '2.0'
%                 'Unit Serial Number':  10010
%                 'User Data Type':  1087
%                 'Pulse Width (CSU)':  150
%                 'Gauge Length (CSU)':  0
%                 'Ping Period (CSU)':  1000000
%                 'Acquisition Start (CSU)':  0
%                 'Input Channel Pitch (CSU)':  1
%                 'FPGA Data Type':  9
%                 'FPGA Data Sub Type':  0
%                 'Output Channel Start (CSU)':  0
%                 'Output Channel Pitch (CSU)':  20.000000
%                 'Data Width (Bits)':  32
%                 'Num Output Channels':  32600
%                 'Decimation Factor':  2
%                 'GPS Enabled':  1
%                 'Variant':  25
%                 'Product Drawing Number':  7800001
%                 'FPGA Image in Set':  0
%                 'Firmware Version':  '2.0.0'
%                 'Input Mux. Position':  0
%                 'ADC Clock (MHz)':  1000
%                 'Pulse Layout':  14
%                 'Synthetic Gauge Length (CSU)':  300
%                 'Num Carriers':  2
%                 'Carrier Separation (CSU)':  448
%                 'Num Elements Per Channel':  1
%                 'Phase Fractional Width (Bits)':  16
%         Group '/Acquisition/Raw[0]' 
%             Attributes:
%                 'uuid':  'c0784377-c239-4f79-aaa0-5dd39ac8e257'
%                 'NumberOfLoci':  32600
%                 'StartLocusIndex':  0
%                 'OutputDataRate':  500.000000
%                 'RawDataUnit':  'rad * 2PI/2^16'
%                 'RawDescription':  'Diversity Processed Phase Dual Pulse Balanced. Ocp 20'
%             Dataset 'RawData' 
%                 Size:  15000x32600
%                 MaxSize:  15000x32600
%                 Datatype:   H5T_STD_I32LE (int32)
%                 ChunkSize:  128x510
%                 Filters:  shuffle, deflate(4)
%                 FillValue:  0
%                 Attributes:
%                     'Dimensions':  'locus ', 'time  '
%                     'Count':  489000000
%                     'StartIndex':  7365000
%                     'PartStartTime':  '2021-11-03T01:57:31.560000Z'
%                     'PartEndTime':  '2021-11-03T01:58:01.558000Z'
%             Dataset 'RawDataTime' 
%                 Size:  15000
%                 MaxSize:  15000
%                 Datatype:   H5T_STD_I64LE (int64)
%                 ChunkSize:  15000
%                 Filters:  shuffle, deflate(1)
%                 FillValue:  0
%                 Attributes:
%                     'Count':  15000
%                     'StartIndex':  7365000
%                     'StartTime':  '2021-11-02T21:52:01.560000Z'
%                     'PartStartTime':  '2021-11-03T01:57:31.560000Z'
%                     'PartEndTime':  '2021-11-03T01:58:01.558000Z'
%             Group '/Acquisition/Raw[0]/Custom' 
%                 Dataset 'GpBits' 
%                     Size:  15000
%                     MaxSize:  15000
%                     Datatype:   H5T_STD_U8LE (uint8)
%                     ChunkSize:  15000
%                     Filters:  deflate(1)
%                     FillValue:  0
%                     Attributes:
%                         'Description':   '0x01 = Data modified post-acquisition
%                                           0x02 = Data compromised'
%                 Dataset 'GpsStatus' 
%                     Size:  15000
%                     MaxSize:  15000
%                     Datatype:   H5T_STD_U8LE (uint8)
%                     ChunkSize:  15000
%                     Filters:  deflate(1)
%                     FillValue:  0
%                     Attributes:
%                         'Description':   '0x01 = GPS Mode
%                                           0x02 = GPS Sync Guaranteed
%                                           0x04 = Time modified post-acquisition'
%                 Dataset 'PpsOffset' 
%                     Size:  15000
%                     MaxSize:  15000
%                     Datatype:   H5T_STD_U32LE (uint32)
%                     ChunkSize:  15000
%                     Filters:  shuffle, deflate(1)
%                     FillValue:  0
%                     Attributes:
%                         'Units':  'CSU'
%                 Dataset 'SampleCount' 
%                     Size:  15000
%                     MaxSize:  15000
%                     Datatype:   H5T_STD_I64LE (int64)
%                     ChunkSize:  15000
%                     Filters:  shuffle, deflate(1)
%                     FillValue:  0

%%
clc
clear all
close all

%% load data from dataset
addpath('Dataset', 'filters', 'plots');

filename = "North-C2-HF-P1kHz-GL30m-Sp2m-FS500Hz_2021-11-03T015731Z.h5";

timestamp = h5readatt(filename,'/Acquisition/Raw[0]/RawDataTime','PartStartTime');

strain = h5read(filename,"/Acquisition/Raw[0]/RawData"); % strain data [channel x time]
strain = double(strain);
strain = strain';

time = h5read(filename,"/Acquisition/Raw[0]/RawDataTime"); % time axis [microseconds]
time = double(time);
time = time';
time = time .* 1e-6; % time axis in seconds
time = time - time(1); % time starts from 0

sampling_interval_s = time(2) - time(1); % sampling interval [s]

channel_distance = double(h5readatt(filename,'/Acquisition','SpatialSamplingInterval'));

nb_of_channels = h5readatt(filename,'/Acquisition','NumberOfLoci');
nb_of_samples = length(time);

distance_m = 0:1:(nb_of_channels - 1);
distance_m = double(distance_m);
distance_m = distance_m .* channel_distance; % distance axis [m]
distance_km = distance_m .* 1e-3;

sampling_frequency_Hz = h5readatt(filename,'/Acquisition/Raw[0]','OutputDataRate');
gauge_length = h5readatt(filename,'/Acquisition','GaugeLength');

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
time_start = 85; time_end = 170; 
distance_min = 50; distance_max = 100;
strain_min_dB = -50; strain_max_dB = -18;

time_space_plot(strain_dB, time, distance_km, ...
    time_start, time_end, distance_min, distance_max, strain_min_dB, strain_max_dB)
subtitle(timestamp, "FontSize", 12);

filename_export = fullfile('Wilcock_OOI_plots/', 'time_space_plot_wilcock_OOI.png');
%exportgraphics(gca, filenae_export);

%% strain waveform of a single channel
channel_position_km = 59.52; % channel of interest

[~, channel_focus_idx] = min(abs(distance_km - channel_position_km));
channel_focus = strain_fk_filtered(channel_focus_idx, :);

time_start = time(1); time_end = time(end); 
amplitude_min = min(channel_focus, [], "all"); amplitude_max = max(channel_focus, [], "all");

strain_waveform(channel_focus, time, ...
    time_start, time_end, amplitude_min, amplitude_max)

filename_export = fullfile('Wilcock_OOI_plots/', 'strain_waveform_wilcock_OOI.png');
%exportgraphics(gca, filenae_export);

%% spectrogram of a single channel
channel_position_km = 59.52; % channel of interest

[~, channel_focus_idx] = min(abs(distance_km - channel_position_km));
channel_focus = strain_fk_filtered(channel_focus_idx, :);

nfft = 4096;
N = 512;
overlap_pct = 0.98;
han_window = hann(N, 'periodic');

time_start = time(1); time_end = time(end); 
frequency_min = 0; frequency_max = 50;
strain_min_dB = -35; strain_max_dB = -5;

plot_spectrogram(channel_focus, nfft, N, han_window, overlap_pct, sampling_frequency_Hz, ...
    time_start, time_end, frequency_min, frequency_max, strain_min_dB, strain_max_dB)

subtitle(sprintf("Channel at km %0.1f", channel_position_km));

filename_export = fullfile('Wilcock_OOI_plots/', 'spectrogram_wilcock_OOI.png');
%exportgraphics(gca, filenae_export);

%% space-frequency plot
nfft = 4096;

time_start_fx = 105; time_end_fx = 125; 
frequency_min = 10; frequency_max = 50;
strain_min_dB = -35; strain_max_dB = -5;

time_window_fx = 2;

get_animation = false;

space_frequency_plot(strain_fk_filtered, distance_km, sampling_frequency_Hz, nfft, time_window_fx, ...
    time_start_fx, time_end_fx, frequency_min, frequency_max, strain_min_dB, strain_max_dB, get_animation);

filename_export = fullfile('Wilcock_OOI_plots/', 'spatio_spectral_plot_wilcock_OOI.png');
%exportgraphics(gca, filenae_export);

%% corss correlation statistics
channel_position_km = 59.52; % reference channel distance
offset_xcorr = 300; % maximum offset (m)
max_lag = 1;  % maximum time lag (s)

correlation(strain_fk_filtered, sampling_frequency_Hz, distance_m, channel_distance, channel_position_km, offset_xcorr, max_lag)