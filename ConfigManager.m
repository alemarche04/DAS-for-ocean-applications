classdef ConfigManager
    % CONFIGMANAGER Centralized configuration manager for DAS analysis
    %
    %   cfg = CONFIGMANAGER(dataset_name) creates a configuration manager
    %   for the specified DAS dataset, loading data and initializing all
    %   analysis parameters.
    %
    %   Properties:
    %       dataset_name - String identifier for the dataset
    %       data         - Structure containing loaded DAS data
    %       params       - Structure containing all analysis parameters
    %
    %   Methods:
    %       ConfigManager(dataset_name) - Constructor
    %           Inputs:
    %               dataset_name -	one of the following: 
	%								'DAS4Whale_Bou22'
	%								'DAS4Tracking_Ror23'
	%								'DAS4Tracking_airgun_inner'
	%								'DAS4Tracking_airgun_outer'
	%								'OOI_Wilcock_2023'
	%								'Norway'
	%
	%       initialize_parameters() - Initialize parameters for 
	%												data processing
    %           Output: params structure with all analysis parameters
    %
    %       load_data_DAS4Whale() - Load DAS4Whale dataset
    %           Output: data structure with DAS measurements
    %
    %       load_data_DAS4Tracking() - Load DAS4Tracking dataset
    %           Output: data structure with DAS measurements
	%
	%		load_data_OOI() - Load OOI dataset
    %           Output: data structure with DAS measurements
	%
	%		load_data_Norway() - Load Norway dataset
    %           Output: data structure with DAS measurements
    %
    %       reload() - Reload both data and configuration from source
    %           Usage: cfg = cfg.reload()
    %           Output: Updated ConfigManager object
    %
    %       reload_params() - Reload only parameters (keeps data in memory)
    %           Usage: cfg = cfg.reload_params()
    %           Output: Updated ConfigManager object
    %
    %   Example:
    %       % Load BOU22 dataset
    %       cfg = ConfigManager('DAS4Whale_Bou22');
    %
    %   See also STRUCT, CLASSDEF
    
    properties
        dataset_name  % Dataset identifier string
        data          % Structure containing DAS data
        params        % Structure containing analysis parameters
    end
    
    methods
        function obj = ConfigManager(dataset_name)
            % Initialize configuration for specified dataset
            % dataset_name: one of the following
			%				'DAS4Whale_Bou22'
			%				'DAS4Tracking_Ror23'
			%				'DAS4Tracking_airgun_inner'
			%				'DAS4Tracking_airgun_outer'
            %				'OOI_Wilcock_2023'
			%				'Norway'

            obj.dataset_name = dataset_name;
            
            % Load data and parameters based on dataset
			switch dataset_name
                case 'DAS4Whale_Bou22'
					filename = "20200627_052441_ch10001_to_ch15000_whale_raw_L160s.mat";
                    obj.data = obj.load_data_DAS4Whale(filename);
					obj.data.time_and_date = "2020-06-27, 05:24:41";
                case 'DAS4Tracking_Ror23'
					filename = "20220822_122707_to_123037_ch9803_to_ch24509_sample_Freq_78_Hz.mat";
                    obj.data = obj.load_data_DAS4Tracking(filename);
					obj.data.time_and_date = "2022-08-22, 12:27:07";
				case 'DAS4Tracking_airgun_inner'
					filename = "20220906_175107_to_175437_ch2450_to_ch9191_sample_Freq_125_Hz_inner.mat";
					obj.data = obj.load_data_DAS4Tracking(filename);
					obj.data.time_and_date = "2022-09-06, 17:51:07";
				case 'DAS4Tracking_airgun_outer'
					filename = "20220906_175106_to_175436_ch2450_to_ch9191_sample_Freq_125_Hz_outer.mat";
					obj.data = obj.load_data_DAS4Tracking(filename);
					obj.data.time_and_date = "2022-09-06, 17:51:06";
				case 'OOI_Wilcock_2023'
					filename = "North-C2-HF-P1kHz-GL30m-Sp2m-FS500Hz_2021-11-03T015731Z.h5";
					obj.data = obj.load_data_OOI(filename);
					obj.data.time_and_date = "2021-11-03, 01:57:31";
				case 'Norway'
					filename = "095659.hdf5";
					obj.data = obj.load_data_Norway(filename);
					obj.data.time_and_date = "09:56:59";
                otherwise
                    error('Unknown dataset: %s', dataset_name);
			end

			obj.params = obj.initialize_parameters(dataset_name);
		end

		%% Parameters initialization
		function params = initialize_parameters(~, dataset_name)

% ──────────────────────────────────────────────────────────────────────
%					Bandpass filter parameters
% ──────────────────────────────────────────────────────────────────────
			% cutoff frequency
			bp_cutoff_freq.DAS4Whale_Bou22					= [5 75];
			bp_cutoff_freq.DAS4Tracking_Ror23				= [5 30];
			bp_cutoff_freq.DAS4Tracking_airgun_inner		= [5 45];
			bp_cutoff_freq.DAS4Tracking_airgun_outer		= [5 45];
			bp_cutoff_freq.Norway							= [5 75];
			params.bpFilter.cutoff_freq = bp_cutoff_freq.(dataset_name);
			
			% filter order
			bp_order.DAS4Whale_Bou22						= 5;
			bp_order.DAS4Tracking_Ror23						= 5;
			bp_order.DAS4Tracking_airgun_inner				= 5;
			bp_order.DAS4Tracking_airgun_outer				= 5;
			bp_order.Norway									= 5;
			params.bpFilter.order = bp_order.(dataset_name);

% ──────────────────────────────────────────────────────────────────────
%					2D median filter filter parameters
% ──────────────────────────────────────────────────────────────────────
			% dimensions
			med_filt2D_dim.DAS4Whale_Bou22					= [3 3];
			med_filt2D_dim.DAS4Tracking_Ror23				= [3 3];
			med_filt2D_dim.DAS4Tracking_airgun_inner		= [3 3];
			med_filt2D_dim.DAS4Tracking_airgun_outer		= [3 3];
			med_filt2D_dim.Norway							= [3 3];
			params.medianFilter2D.dimensions = med_filt2D_dim.(dataset_name);
            
% ──────────────────────────────────────────────────────────────────────
%					FK filter parameters
% ──────────────────────────────────────────────────────────────────────	
			% velocity range
			fk_c_range.DAS4Whale_Bou22						= [];
			fk_c_range.DAS4Tracking_Ror23					= [];
			fk_c_range.DAS4Tracking_airgun_inner			= [];
			fk_c_range.DAS4Tracking_airgun_outer			= [];
			fk_c_range.Norway								= [];
			params.fkFilter.c_range = fk_c_range.(dataset_name);
            
% ──────────────────────────────────────────────────────────────────────
%					Time-space plot parameters
% ──────────────────────────────────────────────────────────────────────
			% time limits
			time_lim.DAS4Whale_Bou22						= [];
			time_lim.DAS4Tracking_Ror23						= [];
			time_lim.DAS4Tracking_airgun_inner				= [];
			time_lim.DAS4Tracking_airgun_outer				= [];
			time_lim.Norway									= [];
			params.txPlot.time_lim = time_lim.(dataset_name);

			% distance limits
			distance_lim.DAS4Whale_Bou22					= [];
			distance_lim.DAS4Tracking_Ror23					= [];
			distance_lim.DAS4Tracking_airgun_inner			= [];
			distance_lim.DAS4Tracking_airgun_outer			= [];
			distance_lim.Norway								= [];
			params.txPlot.distance_lim = distance_lim.(dataset_name);

			% strain limits
			strain_lim.DAS4Whale_Bou22						= [-30 -5];
			strain_lim.DAS4Tracking_Ror23					= [-50 -18];
			strain_lim.DAS4Tracking_airgun_inner			= [-25 -10];
			strain_lim.DAS4Tracking_airgun_outer			= [-25 -10];
			strain_lim.Norway								= [-30 -5];
			params.txPlot.strain_lim = strain_lim.(dataset_name);

			% propagation speed
			prop_speed_km_s.DAS4Whale_Bou22					= 1.47;
			prop_speed_km_s.DAS4Tracking_Ror23				= 1.47;
			prop_speed_km_s.DAS4Tracking_airgun_inner		= 1.47;
			prop_speed_km_s.DAS4Tracking_airgun_outer		= 1.47;
			prop_speed_km_s.Norway							= 1.47;
			params.txPlot.prop_speed_km_s = prop_speed_km_s.(dataset_name);

			% point touched by speed line
			speed_line_points.DAS4Whale_Bou22				= [47.75 45.48];
			speed_line_points.DAS4Tracking_Ror23			= [118.9 65.5];
			speed_line_points.DAS4Tracking_airgun_inner		= [54.4 33];
			speed_line_points.DAS4Tracking_airgun_outer		= [55.4 33];
			speed_line_points.Norway						= [1 1];
			params.txPlot.speed_line_points = speed_line_points.(dataset_name);

			% channel position
			channel_position_km.DAS4Whale_Bou22				= 42;
			channel_position_km.DAS4Tracking_Ror23			= 60;
			channel_position_km.DAS4Tracking_airgun_inner	= 32.5;
			channel_position_km.DAS4Tracking_airgun_outer	= 33;
			channel_position_km.Norway						= 1;
			params.txPlot.channel_position_km = channel_position_km.(dataset_name);

			% CPA position
			cpa_km.DAS4Whale_Bou22							= 42.8;
			cpa_km.DAS4Tracking_Ror23						= 58.9;
			cpa_km.DAS4Tracking_airgun_inner				= 31;
			cpa_km.DAS4Tracking_airgun_outer				= 30.8;
			cpa_km.Norway									= 10;
			params.txPlot.cpa_km = cpa_km.(dataset_name);

			% name of time-space plot png file
			params.txPlot.filename = fullfile(dataset_name, ['time_space_plot_' dataset_name  '.png']);
            
% ──────────────────────────────────────────────────────────────────────
%					Waveform parameters
% ──────────────────────────────────────────────────────────────────────
			% channel position
			channel_position_km.DAS4Whale_Bou22				= 42;
			channel_position_km.DAS4Tracking_Ror23			= 60;
			channel_position_km.DAS4Tracking_airgun_inner	= 32.5;
			channel_position_km.DAS4Tracking_airgun_outer	= 33;
			channel_position_km.Norway						= 1;
			params.waveform.channel_position_km = channel_position_km.(dataset_name);

			% CPA position
			cpa_km.DAS4Whale_Bou22							= 42.8;
			cpa_km.DAS4Tracking_Ror23						= 58.9;
			cpa_km.DAS4Tracking_airgun_inner				= 31;
			cpa_km.DAS4Tracking_airgun_outer				= 30.8;
			cpa_km.Norway									= 10;
			params.waveform.cpa_km = cpa_km.(dataset_name);

			% time limits
			time_lim.DAS4Whale_Bou22						= [];
			time_lim.DAS4Tracking_Ror23						= [];
			time_lim.DAS4Tracking_airgun_inner				= [];
			time_lim.DAS4Tracking_airgun_outer				= [];
			time_lim.Norway									= [];
			params.waveform.time_lim = time_lim.(dataset_name);

			% strain limits
			strain_lim.DAS4Whale_Bou22						= [-1.3e-9 1.3e-9];
			strain_lim.DAS4Tracking_Ror23					= [-1.7*1e-9 1.7*1e-9];
			strain_lim.DAS4Tracking_airgun_inner			= [-1*1e-9 1*1e-9];
			strain_lim.DAS4Tracking_airgun_outer			= [-0.6*1e-9 1*0.6e-9];
			strain_lim.Norway								= [-1.3e-9 1.3e-9];
			params.waveform.strain_lim = strain_lim.(dataset_name);

			% name of waveform plot png file
			params.waveform.filename_plot =	fullfile(dataset_name, ['strain_waveform_' dataset_name  '.png']);

			% name of waveform audio file
            params.waveform.filename_audio = fullfile(dataset_name, ['strain_waveform_' dataset_name  '.wav']);
            
% ──────────────────────────────────────────────────────────────────────
%					Spectrogram parameters
% ──────────────────────────────────────────────────────────────────────
			% channel position
			channel_position_km.DAS4Whale_Bou22				= 42;
			channel_position_km.DAS4Tracking_Ror23			= 60;
			channel_position_km.DAS4Tracking_airgun_inner	= 32.5;
			channel_position_km.DAS4Tracking_airgun_outer	= 33;
			channel_position_km.Norway						= 1;
			params.spectrogram.channel_position_km = channel_position_km.(dataset_name);

			% number of fft samples
			nfft.DAS4Whale_Bou22							= 4096;
			nfft.DAS4Tracking_Ror23							= 4096;
			nfft.DAS4Tracking_airgun_inner					= 4096;
			nfft.DAS4Tracking_airgun_outer					= 4096;
			nfft.Norway										= 4096;
			params.spectrogram.nfft = nfft.(dataset_name);

			% window length
			window_len.DAS4Whale_Bou22						= 512;
			window_len.DAS4Tracking_Ror23					= 512;
			window_len.DAS4Tracking_airgun_inner			= 512;
			window_len.DAS4Tracking_airgun_outer			= 512;
			window_len.Norway								= 512;
			params.spectrogram.window_len = window_len.(dataset_name);

			% window overlap percentage
			overlap_pct.DAS4Whale_Bou22						= 0.89;
			overlap_pct.DAS4Tracking_Ror23					= 0.89;
			overlap_pct.DAS4Tracking_airgun_inner			= 0.89;
			overlap_pct.DAS4Tracking_airgun_outer			= 0.89;
			overlap_pct.Norway								= 0.89;
			params.spectrogram.overlap_pct = overlap_pct.(dataset_name);

			% window function
			window.DAS4Whale_Bou22							= hann(params.spectrogram.window_len, 'periodic');
			window.DAS4Tracking_Ror23						= hann(params.spectrogram.window_len, 'periodic');
			window.DAS4Tracking_airgun_inner				= hann(params.spectrogram.window_len, 'periodic');
			window.DAS4Tracking_airgun_outer				= hann(params.spectrogram.window_len, 'periodic');
			window.Norway									= hann(params.spectrogram.window_len, 'periodic');
			params.spectrogram.window = window.(dataset_name);

			% time limits
			time_lim.DAS4Whale_Bou22						= [];
			time_lim.DAS4Tracking_Ror23						= [];
			time_lim.DAS4Tracking_airgun_inner				= [];
			time_lim.DAS4Tracking_airgun_outer				= [];
			time_lim.Norway									= [];
			params.spectrogram.time_lim = time_lim.(dataset_name);

			% frequency limits
			frequency_lim.DAS4Whale_Bou22					= [10 80];
			frequency_lim.DAS4Tracking_Ror23				= [5 35];
			frequency_lim.DAS4Tracking_airgun_inner			= [5 45];
			frequency_lim.DAS4Tracking_airgun_outer			= [5 45];
			frequency_lim.Norway							= [10 80];
			params.spectrogram.frequency_lim = frequency_lim.(dataset_name);

			% strain limits
			strain_lim.DAS4Whale_Bou22						= [-25 0];
			strain_lim.DAS4Tracking_Ror23					= [-35 -5];
			strain_lim.DAS4Tracking_airgun_inner			= [-25 -2];
			strain_lim.DAS4Tracking_airgun_outer			= [-25 -2];
			strain_lim.Norway								= [-25 0];
			params.spectrogram.strain_lim = strain_lim.(dataset_name);

			% name of spectrognam png file
            params.spectrogram.filename = fullfile(dataset_name, ['spectrogram_' dataset_name  '.png']);
            

% ──────────────────────────────────────────────────────────────────────
%					Space-frequency plot parameters
% ──────────────────────────────────────────────────────────────────────
            % number of fft samples
			nfft.DAS4Whale_Bou22							= 4096;
			nfft.DAS4Tracking_Ror23							= 4096;
			nfft.DAS4Tracking_airgun_inner					= 4096;
			nfft.DAS4Tracking_airgun_outer					= 4096;
			nfft.Norway										= 4096;
			params.fxPlot.nfft = nfft.(dataset_name);

			% time interval
			time_interval.DAS4Whale_Bou22					= [44 67];
			time_interval.DAS4Tracking_Ror23				= [100 123];
			time_interval.DAS4Tracking_airgun_inner			= [52.5 62.9];
			time_interval.DAS4Tracking_airgun_outer			= [53.5 63.9];
			time_interval.Norway							= [1 2];
			params.fxPlot.time_interval = time_interval.(dataset_name);

			% time window
			time_window.DAS4Whale_Bou22						= 1.5;
			time_window.DAS4Tracking_Ror23					= 1.5;
			time_window.DAS4Tracking_airgun_inner			= 1.5;
			time_window.DAS4Tracking_airgun_outer			= 1.5;
			time_window.Norway								= 1.5;
			params.fxPlot.time_window = time_window.(dataset_name);

			% frequency limits
			frequency_lim.DAS4Whale_Bou22					= [5 75];
			frequency_lim.DAS4Tracking_Ror23				= [5 35];
			frequency_lim.DAS4Tracking_airgun_inner			= [5 45];
			frequency_lim.DAS4Tracking_airgun_outer			= [5 45];
			frequency_lim.Norway							= [5 75];
			params.fxPlot.frequency_lim = frequency_lim.(dataset_name);

			% strain limits
			strain_lim.DAS4Whale_Bou22						= [-25 -5];
			strain_lim.DAS4Tracking_Ror23					= [-35 -5];
			strain_lim.DAS4Tracking_airgun_inner			= [-25 -2];
			strain_lim.DAS4Tracking_airgun_outer			= [-25 -2];
			strain_lim.Norway								= [-25 -5];
			params.fxPlot.strain_lim = strain_lim.(dataset_name);

			% name of space-frequency plot png file
			params.fxPlot.filename = fullfile(dataset_name, ['fx_plot_' dataset_name  '.png']);

			% name of space-frequency animation file
			params.fxPlot.filename_animation = fullfile(dataset_name, ['fx_animation_' dataset_name  '.avi']);
            

% ──────────────────────────────────────────────────────────────────────
%					Correlation parameters
% ──────────────────────────────────────────────────────────────────────
			% channel position
			channel_position_km.DAS4Whale_Bou22				= 42;
			channel_position_km.DAS4Tracking_Ror23			= 60;
			channel_position_km.DAS4Tracking_airgun_inner	= 32.5;
			channel_position_km.DAS4Tracking_airgun_outer	= 33;
			channel_position_km.Norway						= 1;
			params.correlation.channel_position_km = channel_position_km.(dataset_name);

			% cross correlation spatial offset
			offset_m.DAS4Whale_Bou22						= 300;
			offset_m.DAS4Tracking_Ror23						= 300;
			offset_m.DAS4Tracking_airgun_inner				= 35;
			offset_m.DAS4Tracking_airgun_outer				= 35;
			offset_m.Norway									= 300;
			params.correlation.offset_m = offset_m.(dataset_name);

			% cross correlation maximum time lag
			time_lag.DAS4Whale_Bou22						= 0.2;
			time_lag.DAS4Tracking_Ror23						= 0.2;
			time_lag.DAS4Tracking_airgun_inner				= 0.02;
			time_lag.DAS4Tracking_airgun_outer				= 0.02;
			time_lag.Norway									= 0.2;
			params.correlation.time_lag = time_lag.(dataset_name);

			% time interval of cross correlated signals
			time_interval.DAS4Whale_Bou22					= [47 50];
			time_interval.DAS4Tracking_Ror23				= [102 105];
			time_interval.DAS4Tracking_airgun_inner			= [55 58];
			time_interval.DAS4Tracking_airgun_outer			= [56 59];
			time_interval.Norway					= [1 2];
			params.correlation.time_interval = time_interval.(dataset_name);

			% name of correlogram png file
            params.correlation.filename_correlogram = fullfile(dataset_name, ['correlogram_' dataset_name  '.png']);

			% name of cross-correlation plots png file
            params.correlation.filename_xcorr = fullfile(dataset_name, ['cross_corr_stats_' dataset_name  '.png']);

			% name of cross-correlation statistics csv file
            params.correlation.filename_table =	fullfile(dataset_name, ['cross_corr_stats_' dataset_name  '.csv']);

% ──────────────────────────────────────────────────────────────────────
%					Event detection parameters
% ──────────────────────────────────────────────────────────────────────
			% name of time-space plot of events detected png file
			params.eventDetection.filename_plot = fullfile(dataset_name, ['events_tx_plot_' dataset_name  '.png']);

			% name of events detected csv file
			params.eventDetection.filename_csv = fullfile(dataset_name, ['events_' dataset_name  '.csv']);
			
        end

        %% load data from DAS4Whale dataset
		function data = load_data_DAS4Whale(~, filename)
            dataset = load(filename);
            
            % Extract data
            data.strain =					dataset.data .* 1e-9;
            data.time =						dataset.x2_time_s; % s
            data.sampling_interval_s =		dataset.info_sample_interval_s; % s
            data.distance_m =				dataset.x1_distance_from_shore_m; % m
            data.distance_km =				data.distance_m .* 1e-3; % km
            data.nb_of_channels =			dataset.info_ntraces;
            data.nb_of_samples =			dataset.info_nsamples;
            data.dimensions =				[data.nb_of_channels data.nb_of_samples];
            data.sampling_frequency_Hz =	dataset.info_sampling_frequency_Hz; % Hz
            data.gauge_length_m =			dataset.info_GL_m; % m
            data.channel_distance_m =		data.distance_m(2) - data.distance_m(1); % m
		end

        %% load data from DAS4Tracking dataset
		function data = load_data_DAS4Tracking(~, filename)
            dataset = load(filename);
            
            % Extract data
            data.strain =					dataset.data;
            data.time =						dataset.x1_time;
            data.sampling_interval_s =		dataset.info_sapmling_interval_s;            
            data.distance_m =				dataset.x1_absolute_channel;
            data.distance_km =				data.distance_m .* 1e-3;            
            data.nb_of_channels =			dataset.info_ntraces;
            data.nb_of_samples =			dataset.info_nsamples; 
			data.dimensions =				[data.nb_of_channels data.nb_of_samples];
            data.sampling_frequency_Hz =	dataset.info_sampling_frequency_Hz;
            data.gauge_length =				dataset.info_gauge_length;
            data.channel_distance_m =		data.distance_m(2) - data.distance_m(1);
		end
		
		%% load data from OOI dataset 
		function data = load_data_OOI(~, filename)
                        
            % Extract data
            data.strain =					double(h5read(filename,"/Acquisition/Raw[0]/RawData"))';
            data.time =						double(h5read(filename,"/Acquisition/Raw[0]/RawDataTime"))';
			data.time =						(data.time - data.time(1)) .* 1e-6;
            data.sampling_interval_s =		data.time(2) - data.time(1);            
            data.channel_distance_m =		double(h5readatt(filename,'/Acquisition','SpatialSamplingInterval'));
			data.nb_of_channels =			h5readatt(filename,'/Acquisition','NumberOfLoci');
            data.nb_of_samples =			length(data.time);
			data.distance_m =				double(0:1:(data.nb_of_channels - 1)) .* data.channel_distance_m;
            data.distance_km =				data.distance_m .* 1e-3; 
			data.dimensions =				[data.nb_of_channels data.nb_of_samples];
            data.sampling_frequency_Hz =	h5readatt(filename,'/Acquisition/Raw[0]','OutputDataRate');
            data.gauge_length =				h5readatt(filename,'/Acquisition','GaugeLength');
		end

		%% load data from Norway dataset 
		function data = load_data_Norway(~, filename)
                        
            % Extract data
            data.strain =									double(h5read(filename,"/data"))';
            data.sampling_interval_s =						double(h5read(filename,'/header/dt'));         
            data.channel_distance_m =						double(h5read(filename,'/header/dx'));
			[data.nb_of_channels, data.nb_of_samples] =		size(data.strain);
			data.time =										double(0:1:(data.nb_of_samples - 1)) .* data.sampling_interval_s;
			data.distance_m =								double(0:1:(data.nb_of_channels - 1)) .* data.channel_distance_m;
            data.distance_km =								data.distance_m .* 1e-3;
			data.dimensions =								[data.nb_of_channels data.nb_of_samples];
            data.sampling_frequency_Hz =					1/data.sampling_interval_s;
            data.gauge_length =								double(h5read(filename,'/header/gaugeLength'));
		end

		%% utilities
        function obj = reload(obj)
            % Reload both data and configuration from source
            % Usage: cfg = cfg.reload()
            
            fprintf('Reloading data and configuration for dataset: %s\n', obj.dataset_name);
            
            % Re-initialize based on dataset

			switch obj.dataset_name
                case 'DAS4Whale_Bou22'
					filename = "20200627_052441_ch10001_to_ch15000_whale_raw_L160s.mat";
                    obj.data = obj.load_data_DAS4Whale(filename);
					obj.data.time_and_date = "2020-06-27, 05:24:41";
                case 'DAS4Tracking_Ror23'
					filename = "20220822_122707_to_123037_ch9803_to_ch24509_sample_Freq_78_Hz.mat";
                    obj.data = obj.load_data_DAS4Tracking(filename);
					obj.data.time_and_date = "2022-08-22, 12:27:07";
				case 'DAS4Tracking_airgun_inner'
					filename = "20220906_175107_to_175437_ch2450_to_ch9191_sample_Freq_125_Hz_inner.mat";
					obj.data = obj.load_data_DAS4Tracking(filename);
					obj.data.time_and_date = "2022-09-06, 17:51:07";
				case 'DAS4Tracking_airgun_outer'
					filename = "20220906_175106_to_175436_ch2450_to_ch9191_sample_Freq_125_Hz_outer.mat";
					obj.data = obj.load_data_DAS4Tracking(filename);
					obj.data.time_and_date = "2022-09-06, 17:51:06";
				case 'OOI_Wilcock_2023'
					filename = "North-C2-HF-P1kHz-GL30m-Sp2m-FS500Hz_2021-11-03T015731Z.h5";
					obj.data = obj.load_data_OOI(filename);
					obj.data.time_and_date = "2021-11-03, 01:57:31";
				case 'Norway'
					filename = "095659.hdf5";
					obj.data = obj.load_data_Norway(filename);
					obj.data.time_and_date = "09:56:59";
                otherwise
                    error('Unknown dataset: %s', obj.dataset_name);
			end
            obj.params = obj.initialize_parameters(obj.dataset_name);
            fprintf('Data and configuration reloaded successfully.\n');
        end

        function obj = reload_params(obj)
            % Reload only parameters (keeps existing data in memory)
            % Usage: cfg = cfg.reload_params()
            
			clc;
            fprintf('Reloading parameters for dataset: %s\n', obj.dataset_name);
            
            % Re-initialize only parameters based on dataset
			if ~ismember(obj.dataset_name, {'DAS4Whale_Bou22', ...
											'DAS4Tracking_Ror23', ...
											'DAS4Tracking_airgun_inner', ...
											'DAS4Tracking_airgun_outer', ...
											'OOI_Wilcock_2023' ...
											'Norway'})
				error('Unknown dataset: %s', obj.dataset_name);
			end
            obj.params = obj.initialize_parameters(obj.dataset_name);
            fprintf('Parameters reloaded successfully.\n');
		end
    end
end