function cfg = DAS4Whale_Bou22_cfg()
% DAS4WHALE_BOU22_CFG Configuration file for the DAS4Whale dataset.
%
%   CFG = DAS4WHALE_BOU22_CFG() returns a structure containing function
%   handles and predefined parameters for loading, processing, and 
%   visualizing Distributed Acoustic Sensing (DAS) data.
%
%   Output:
%       cfg - Struct containing processing parameters and handles to 
%             sub-configuration functions.
%
%   Reference: Bou22 Dataset
%   See also: LOAD, SPECTROGRAM, DESIGNFILT

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
function data = load_data()
% LOAD_DATA Loads raw DAS data from the specified .mat file.
%
%   Output:
%       data - Struct containing transposed strain matrix, time vectors,
%              distances, and sensor metadata (fs, dx, GL).

    filename = "20200627_052441_ch10001_to_ch15000_whale_raw_L160s.mat";
    dataset = load(filename);
    
    % Data extraction and conversion
    data.strain						= dataset.data .* 1e-9;
    data.time						= dataset.x2_time_s; % [s]
    data.sampling_interval_s		= dataset.info_sample_interval_s; % [s]
    data.distance_m					= dataset.x1_distance_from_shore_m; % [m]
    data.distance_km				= data.distance_m .* 1e-3; % [km]
    data.nb_of_channels				= dataset.info_ntraces;
    data.nb_of_samples				= dataset.info_nsamples;
    data.dimensions					= [data.nb_of_channels data.nb_of_samples];
    data.sampling_frequency_Hz		= dataset.info_sampling_frequency_Hz; % [Hz]
    data.gauge_length_m				= dataset.info_GL_m; % [m]
    data.channel_distance_m			= data.distance_m(2) - data.distance_m(1); % [m]
    data.time_and_date				= "2020-06-27, 05:24:41";
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

    fkFilt.velocity_range = [];
end

% -----------------------------------------------------------------------%

%% TIME-SPACE PLOT (T-X)
function tx = tx()
% TX Configuration for time-distance visualization.
%
%   Output:
%       tx - Parameters for axis limits and propagation speed references.

    tx.time_lim                 = [];
    tx.distance_lim             = [];
    tx.strain_lim               = [-30 -5]; % [dB]
	tx.p1						= [49.65 45925.8]; % [time space]
	tx.p2						= [48.15 43752.5]; % [time space]
    tx.channel_position_m       = 42000;
    tx.cpa_m                    = 42800;
end

% -----------------------------------------------------------------------%

%% STRAIN WAVEFORM
function wf = waveform()
% WAVEFORM Configuration for strain waveform visualization.
%
%   Output:
%       wf - Parameters for time-series plotting and audio export.

    wf.channel_position_m    = 42000;
    wf.cpa_m                 = 42800;
    wf.time_lim              = [];
    wf.strain_lim            = [-1.3e-9 1.3e-9];
    wf.filename_audio        = fullfile('DAS4Whale_Bou22/', 'strain_waveform_DAS4Whale_Bou22.wav');
end
% -----------------------------------------------------------------------%

%% SPECTROGRAM
function sg = spectrogram()
% SPECTROGRAM Configuration for time-frequency analysis.
%
%   Output:
%       sg - STFT parameters (Window type, NFFT, Overlap) and plot parameters.

    sg.channel_position_m    = 42000;
    sg.nfft                  = 4096;
    sg.window_len            = 512;
    sg.window                = hann(sg.window_len, 'periodic');
    sg.overlap_pct           = 0.89;
    sg.time_lim              = [];
    sg.frequency_lim         = [10 80]; % [Hz]
    sg.strain_lim            = [-25 0];
end
% -----------------------------------------------------------------------%

%% SPACE-FREQUENCY PLOT (F-X)
function fx = fx()
% FX Configuration for space-frequency visualization.
%
%   Output:
%       fx - Parameters for spatial-frequency analysis.

    fx.nfft					= 4096;
    fx.time_interval		= [44 67];
    fx.time_window			= 1.5;
    fx.frequency_lim		= [5 75];
    fx.strain_lim			= [-25 -5];
    fx.filename_animation   = fullfile('DAS4Whale_Bou22/', 'fx_animation_DAS4Whale_Bou22.avi');
end
% -----------------------------------------------------------------------%

%% CROSS-CORRELATION STATISTICS
function xcorr = correlation()
% CORRELATION Parameters for inter-channel cross-correlation processing.
%
%   Output:
%       xcorr - Channel offsets, time lags, and statistics export settings.

    xcorr.channel_position_m	= 42000;
    xcorr.offset_m				= 300;
    xcorr.time_lag				= 0.2;
    xcorr.time_interval			= [47 50];
    xcorr.cpa_m					= 42800;
    xcorr.filename_table		= fullfile('DAS4Whale_Bou22/', 'cross_corr_stats_DAS4Whale_Bou22.csv');
end