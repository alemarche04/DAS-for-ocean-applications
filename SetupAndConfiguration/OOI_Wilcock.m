function cfg = OOI_Wilcock()
% DOOI_WILCOCK Configuration file for the OOI Wilcock dataset.
%
%   CFG = DOOI_WILCOCK() returns a structure containing function
%   handles and predefined parameters for loading, processing, and 
%   visualizing Distributed Acoustic Sensing (DAS) data.
%
%   Output:
%       cfg - Struct containing processing parameters and handles to 
%             sub-configuration functions.
%
%   Reference: https://oceanobservatories.org/pi-instrument/rapid-a-community-test-of-distributed-acoustic-sensing-on-the-ocean-observatories-initiative-regional-cabled-array/
%   See also: H5READ, FULLFILE

	% Check if the dataset exists
	if ~isfile(fullfile(fileparts(which(dataset_name)), dataset_name))
        error('Dataset file does not exist: %s', dataset_name);
	end


    % Function handles for configuration sub-modules
    cfg.load_data   = @load_data;
    cfg.bandpass    = @bandpass;
    cfg.medFilt     = @medFilt;
    cfg.fkFilt      = @fkFilt;
    cfg.tx_plot     = @tx;
    cfg.waveform    = @waveform;
    cfg.spectrogram = @spectrogram;
    cfg.fx_plot     = @fx;
    cfg.correlation = @correlation;
    
end
% -----------------------------------------------------------------------%

%% DATA LOADING
function data = load_data(dataset_name)
% LOAD_DATA Loads raw DAS data from the specified .mat file.
%
%   Output:
%       data - Struct containing transposed strain matrix, time vectors,
%              distances, and sensor metadata (fs, dx, GL).

    % Check if the dataset exists
	if ~isfile(fullfile(fileparts(which(dataset_name)), dataset_name))
        error('Dataset file does not exist: %s', dataset_name);
	end

	% Check if directory exists
	if isfolder("OOI_Wilcock") == false
    	% Create directory
    	mkdir("OOI_Wilcock")
	end

	% Extract data
    data.strain						= double(h5read(dataset_name,"/Acquisition/Raw[0]/RawData"))'; %[strain unit]
    data.time						= double(h5read(dataset_name,"/Acquisition/Raw[0]/RawDataTime"))'; %[us]
	data.time						= (data.time - data.time(1)) .* 1e-6; %[s]
    data.sampling_interval_s		= data.time(2) - data.time(1); %[s]
    data.channel_distance_m			= double(h5readatt(dataset_name,'/Acquisition','SpatialSamplingInterval')); %[m]
	data.nb_of_channels				= h5readatt(dataset_name,'/Acquisition','NumberOfLoci');
    data.nb_of_samples				= length(data.time);
	data.distance_m					= double(0:1:(data.nb_of_channels - 1)) .* data.channel_distance_m; %[m]
    data.distance_km				= data.distance_m .* 1e-3; %[km]
	data.dimensions					= [data.nb_of_channels data.nb_of_samples];
    data.sampling_frequency_Hz		= h5readatt(dataset_name,'/Acquisition/Raw[0]','OutputDataRate'); %[Hz]
    data.gauge_length				= h5readatt(dataset_name,'/Acquisition','GaugeLength'); %[m]
	data.propagation_speed			= 1500; % [m/s]
end
% -----------------------------------------------------------------------%

%% BANDPASS FILTER
function bp = bandpass()
% BANDPASS Configuration for the frequency bandpass filter.
%
%   Output:
%       bp - Struct containing cutoff frequencies and filter order.

    bp.cutoff_freq   = [5 75]; % [Hz]
    bp.order         = 5;
end
% -----------------------------------------------------------------------%

%% 2D MEDIAN FILTER
function medFilt = medFilt()
% MEDFILT Configuration for the 2D median filter.
%
%   Output:
%       medFilt - Struct containing kernel dimensions for denoising.

    medFilt.dim = [3 3];
end
% -----------------------------------------------------------------------%

%% FK FILTER
function fkFilt = fkFilt()
% FKFILT Configuration for Frequency-Wavenumber (f-k) domain filtering.
%
%   Output:
%       fkFilt - Struct containing velocity range limits for f-k filtering.

    fkFilt.velocity_range = []; %[m/s]
end

% -----------------------------------------------------------------------%

%% TIME-SPACE PLOT (T-X)
function tx = tx()
% TX Configuration for time-distance visualization.
%
%   Output:
%       tx - Parameters for axis limits and propagation speed references.

    tx.time_lim                 = []; % [s]
    tx.distance_lim             = []; % [m]
    tx.strain_lim               = [-30 -5]; % [dB]
	tx.p1						= [1 1]; % [time space]
	tx.p2						= [1 1]; % [time space]
    tx.channel_position_m       = 1; % [m]
    tx.cpa_m                    = 1; % [m]
end

% -----------------------------------------------------------------------%

%% STRAIN WAVEFORM
function wf = waveform()
% WAVEFORM Configuration for strain waveform visualization.
%
%   Output:
%       wf - Parameters for time-series plotting and audio export.

    wf.channel_position_m    = 1; % [m]
    wf.cpa_m                 = 1; % [m]
    wf.time_lim              = []; % [s]
    wf.strain_lim            = [-1.3e-9 1.3e-9]; %[strain unit]
    wf.filename_audio        = fullfile('DAS4Tracking/', 'strain_waveform_DAS4Tracking.wav');
end
% -----------------------------------------------------------------------%

%% SPECTROGRAM
function sg = spectrogram()
% SPECTROGRAM Configuration for time-frequency analysis.
%
%   Output:
%       sg - STFT parameters (Window type, NFFT, Overlap) and plot parameters.

    sg.channel_position_m    = 1; % [m]
    sg.nfft                  = 4096;
    sg.window_len            = 512;
    sg.window                = hann(sg.window_len, 'periodic');
    sg.overlap_pct           = 0.89;
    sg.time_lim              = []; % [s]
    sg.frequency_lim         = [10 80]; % [Hz]
    sg.strain_lim            = [-25 0]; % [dB]
end
% -----------------------------------------------------------------------%

%% SPACE-FREQUENCY PLOT (F-X)
function fx = fx()
% FX Configuration for space-frequency visualization.
%
%   Output:
%       fx - Parameters for spatial-frequency analysis.

    fx.nfft					= 4096;
    fx.time_interval		= [1 23]; % [s]
    fx.time_window			= 1.5; % [s]
    fx.frequency_lim		= [5 75]; % [Hz]
    fx.strain_lim			= [-25 -5]; % [dB]
    fx.filename_animation   = fullfile('DAS4Tracking/', 'fx_animation_DAS4Tracking.avi');
end
% -----------------------------------------------------------------------%

%% CROSS-CORRELATION STATISTICS
function xcorr = correlation()
% CORRELATION Parameters for inter-channel cross-correlation processing.
%
%   Output:
%       xcorr - Channel offsets, time lags, and statistics export settings.

    xcorr.channel_position_m	= 1; % [m]
    xcorr.offset_m				= 10; % [m]
    xcorr.time_lag				= 0.01; % [s]
    xcorr.time_interval			= [1 3]; % [s]
    xcorr.cpa_m					= 1; % [m]
    xcorr.filename_table		= fullfile('DAS4Tracking/', 'cross_corr_stats_DAS4Tracking.csv');
end