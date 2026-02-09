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
%       data - Struct containing strain signals, time vectors, 
%              spatial coordinates, and sensor metadata.

    filename = "20200627_052441_ch10001_to_ch15000_whale_raw_L160s.mat";
    dataset = load(filename);
    
    % Data extraction and conversion
    data.strain =                   dataset.data .* 1e-9;
    data.time =                     dataset.x2_time_s; % [s]
    data.sampling_interval_s =      dataset.info_sample_interval_s; % [s]
    data.distance_m =               dataset.x1_distance_from_shore_m; % [m]
    data.distance_km =              data.distance_m .* 1e-3; % [km]
    data.nb_of_channels =           dataset.info_ntraces;
    data.nb_of_samples =            dataset.info_nsamples;
    data.dimensions =               [data.nb_of_channels data.nb_of_samples];
    data.sampling_frequency_Hz =    dataset.info_sampling_frequency_Hz; % [Hz]
    data.gauge_length_m =           dataset.info_GL_m; % [m]
    data.channel_distance_m =       data.distance_m(2) - data.distance_m(1); % [m]
    data.time_and_date = "2020-06-27, 05:24:41";
end

% -----------------------------------------------------------------------%
%% BANDPASS FILTER
function bp = bandpass()
% BANDPASS Configuration for the 1D frequency bandpass filter.
%
%   Output:
%       bp - Struct containing cutoff frequencies and filter order.

    bp.bp_cutoff_freq   = [5 75]; % [Hz]
    bp.bp_order         = 5;
end

% -----------------------------------------------------------------------%
%% 2D MEDIAN FILTER
function medFilt = medFilt()
% MEDFILT Configuration for the 2D median filter.
%
%   Output:
%       medFilt - Struct containing kernel dimensions for denoising.

    medFilt.med_filt2D_dim = [3 3];
end

% -----------------------------------------------------------------------%
%% FK FILTER
function fkFilt = fkFilt()
% FKFILT Configuration for Frequency-Wavenumber (f-k) domain filtering.
%
%   Output:
%       fkFilt - Struct containing velocity range limits for f-k filtering.

    fkFilt.fk_velocity_range = [];
end

% -----------------------------------------------------------------------%
%% TIME-SPACE PLOT (T-X)
function tx = tx()
% TX Configuration for time-distance visualization.
%
%   Output:
%       tx - Parameters for axis limits and propagation speed references.

    tx.tx_time_lim                  = [];
    tx.tx_distance_lim              = [];
    tx.tx_strain_lim                = [-30 -5]; % [dB re strain]
    tx.tx_prop_speed_km_s           = 1.47;     % Sound speed in water [km/s]
    tx.tx_speed_line_points         = [47.75 45.48];
    tx.tx_channel_position_km       = 42;
    tx.tx_cpa_km                    = 42.8;
end

% -----------------------------------------------------------------------%
%% STRAIN WAVEFORM
function wf = waveform()
% WAVEFORM Configuration for strain waveform visualization.
%
%   Output:
%       wf - Parameters for time-series plotting and audio export.

    wf.wf_channel_position_km   = 42;
    wf.wf_cpa_km                = 42.8;
    wf.wf_time_lim              = [];
    wf.wf_strain_lim            = [-1.3e-9 1.3e-9];
    wf.filename_audio           = fullfile('DAS4Whale_Bou22/', 'strain_waveform_DAS4Whale_Bou22.wav');
end

% -----------------------------------------------------------------------%
%% SPECTROGRAM
function sg = spectrogram()
% SPECTROGRAM Configuration for time-frequency analysis.
%
%   Output:
%       sg - STFT parameters (Window type, NFFT, Overlap).

    sg.sg_channel_position_km   = 42;
    sg.sg_nfft                  = 4096;
    sg.sg_window_len            = 512;
    sg.sg_window                = hann(sg.sg_window_len, 'periodic');
    sg.sg_overlap_pct           = 0.89;
    sg.sg_time_lim              = [];
    sg.sg_frequency_lim         = [10 80]; % [Hz]
    sg.sg_strain_lim            = [-25 0];
end

% -----------------------------------------------------------------------%
%% SPACE-FREQUENCY PLOT (F-X)
function fx = fx()
% FX Configuration for distance-frequency visualization.
%
%   Output:
%       fx - Parameters for spectral animation and spatial frequency analysis.

    fx.fx_nfft              = 4096;
    fx.fx_time_interval     = [44 67];
    fx.fx_time_window       = 1.5;
    fx.fx_frequency_lim     = [5 75];
    fx.fx_strain_lim        = [-25 -5];
    fx.filename_animation   = fullfile('DAS4Whale_Bou22/', 'fx_animation_DAS4Whale_Bou22.avi');
end

% -----------------------------------------------------------------------%
%% CROSS-CORRELATION STATISTICS
function xcorr = correlation()
% CORRELATION Parameters for inter-channel cross-correlation processing.
%
%   Output:
%       xcorr - Channel offsets, time lags, and statistics export settings.

    xcorr.corr_channel_position_km  = 42;
    xcorr.corr_offset_m             = 300;
    xcorr.corr_time_lag             = 0.2;
    xcorr.corr_time_interval        = [47 50];
    xcorr.corr_cpa_km               = 42.8;
    xcorr.filename_xcorr_table      = fullfile('DAS4Whale_Bou22/', 'cross_corr_stats_DAS4Whale_Bou22.csv');
end