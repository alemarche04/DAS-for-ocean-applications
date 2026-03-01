function cfg = Norway_cfg()
% NORWAY_CFG Configuration file for the Trondheimsfjord dataset.
%
%   CFG = NORWAY_CFG() returns a structure containing function handles
%   and parameters for processing DAS data from the Norway experiment.
%
%   Output:
%       cfg - Struct containing processing parameters and handles to 
%             sub-configuration and plotting functions.
%
%   See also: H5READ, FULLFILE

	cfg.load_data						= @load_data;
	cfg.bandpass						= @bandpass;
	cfg.medFilt							= @medFilt;
	cfg.fkFilt							= @fkFilt;
	cfg.tx_plot							= @tx_plot;
	cfg.waveform						= @waveform;
	cfg.spectrogram						= @spectrogram;
	cfg.fx_plot							= @fx_plot;
	cfg.correlation						= @correlation;	
end
% -----------------------------------------------------------------------%

%% DATA LOADING
function data = load_data(dataset_name)
% LOAD_DATA Loads DAS strain data and metadata from HDF5 files.
%
%   Output:
%       data - Struct containing transposed strain matrix, time vectors,
%              distances, and sensor metadata (fs, dx, GL).


	% Check if the dataset exists
	if ~isfile(fullfile(fileparts(which(dataset_name)), dataset_name))
        error('Dataset file does not exist: %s', dataset_name);
	end

	% Check if directory exists
	if isfolder("Norway") == false
    	% Create directory
    	mkdir("Norway")
	end

	% Check if directory exists
	if isfolder("Dataset") == false
    	% Create directory
    	mkdir("Dataset")
	end

	% Create filename for the loaded dataset
	loaded_filename = fullfile("Dataset", strcat('Trondheim_processed_', dataset_name));
	input_filename = fullfile(fileparts(which('122403.hdf5')), '122403.hdf5');

	% Check if processed dataset already exists
	if ~isfile(loaded_filename)
        % Run python script to load data of interest from hdf5 file
		pyrunfile("hdf5_handler.py", input_file=input_filename, output_file=loaded_filename);
	end

    % Extract data
    data.strain						= h5read(loaded_filename, '/trace'); %[strain unit]
	data.time						= h5read(loaded_filename, '/tx'); %[s]
	data.distance_m					= h5read(loaded_filename, '/dist'); %[m]
	data.distance_km				= double(data.distance_m .* 1e-3); %[km]
	
	temp_time						= h5read(loaded_filename, '/file_begin_time_utc');
	data.time_and_date				= temp_time{1}; 
	
	data.sampling_frequency_Hz		= h5read(loaded_filename, '/metadata/fs'); %[Hz]
	data.channel_distance_m			= h5read(loaded_filename, '/metadata/dx'); %[m]
	data.gauge_length				= h5read(loaded_filename, '/metadata/GL'); %[m]
	data.nb_of_channels				= h5read(loaded_filename, '/metadata/nx');
	data.nb_of_samples				= h5read(loaded_filename, '/metadata/ns');
	data.sampling_interval_s		= 1/data.sampling_frequency_Hz;
	data.dimensions					= [data.nb_of_channels data.nb_of_samples];
	
	% Transpose from Row-Major (Python) to Column-Major (MATLAB)
	data.strain	= data.strain'; 
end
% -----------------------------------------------------------------------%

%% BANDPASS FILTER
function bp = bandpass()
% BANDPASS Configuration for the frequency bandpass filter.
%
%   Output:
%       bp - Struct containing cutoff frequencies and filter order.
    bp.cutoff_freq		= [800 4000]; % [Hz]
    bp.order			= 6;
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

    fkFilt.velocity_range = [1400 1435 1575 1600]; %[m/s]
end
% -----------------------------------------------------------------------%

%% TIME-SPACE PLOT (T-X)
function tx = tx_plot()
% TX Configuration for time-distance visualization.
%
%   Output:
%       tx - Parameters for axis limits and propagation speed references.

    tx.time_lim					= []; %[s]
    tx.distance_lim				= []; %[m]
    tx.strain_lim				= [-40 -10]; % [dB]
    tx.p1						= [1 1]; %[time space]
	tx.p2						= [2 2]; %[time space]
    tx.channel_position_m		= 0; %[m]
    tx.cpa_m					= 0; %[m]
end
% -----------------------------------------------------------------------%

%% STRAIN WAVEFORM
function wf = waveform()
% WAVEFORM Configuration for strain waveform visualization.
%
%   Output:
%       wf - Parameters for time-series plotting and audio export.

    wf.channel_position_m	= (286 -1) * 1.02; %[m]
    wf.cpa_m				= 0; %[m]
    wf.time_lim				= []; %[s]
    wf.strain_lim			= []; %[strain unit]
    wf.filename_audio		= fullfile('Norway/', 'strain_waveform_Norway.wav');
end
% -----------------------------------------------------------------------%

%% SPECTROGRAM
function sg = spectrogram()
% SPECTROGRAM Configuration for time-frequency analysis.
%
%   Output:
%       sg - STFT parameters (Window type, NFFT, Overlap) and plot parameters.

    sg.channel_position_m	= (286 -1) * 1.02; %[m]
    sg.nfft					= 4096;
    sg.window_len			= 512;
    sg.window				= hann(sg.window_len, 'periodic');
    sg.overlap_pct			= 0.89;
    sg.time_lim				= []; %[s]
    sg.frequency_lim		= [800 4000]; %[Hz]
    sg.strain_lim			= [-155 -125]; %[dB]
end
% -----------------------------------------------------------------------%

%% SPACE-FREQUENCY PLOT (F-X)
function fx = fx_plot()
% FX Configuration for space-frequency visualization.
%
%   Output:
%       fx - Parameters for spatial-frequency analysis.

    fx.nfft					= 4096;
    fx.time_interval		= [0 23]; %[s]
    fx.time_window			= 1.5; %[s]
    fx.frequency_lim		= []; %[Hz]
    fx.strain_lim			= []; %[dB]
    fx.filename_animation	= fullfile('Norway/', 'fx_animation_Norway.avi');
end
% -----------------------------------------------------------------------%

%% CROSS-CORRELATION STATISTICS
function xcorr = correlation()
% CORRELATION Parameters for inter-channel cross-correlation processing.
%
%   Output:
%       xcorr - Channel offsets, time lags, and statistics export settings.

    xcorr.channel_position_m	= (178 -1) * 1.02; %[m]
    xcorr.offset_m				= 9; %[m]
    xcorr.time_lag				= 0.007; %[s]
    xcorr.time_interval			= [3.8 4]; %[s]
    xcorr.cpa_m					= 207; %[m]
    xcorr.filename_table		= fullfile('Norway/', 'cross_corr_stats_Norway.csv');
end
% -----------------------------------------------------------------------%