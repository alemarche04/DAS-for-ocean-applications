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
    %               dataset_name - 'DAS4Whale_bou22' or 'DAS4Tracking_ror23'
    %
    %       load_data_bou22() - Load BOU22 whale dataset
    %           Output: data structure with DAS measurements
    %
    %       init_params_bou22() - Initialize BOU22 parameter groups
    %           Output: params structure with all analysis parameters
    %
    %       load_data_ror23() - Load ROR23 tracking dataset (template)
    %           Output: data structure with DAS measurements
    %
    %       init_params_ror23() - Initialize ROR23 parameters (template)
    %           Output: params structure with all analysis parameters
    %
    %       init_default_params() - Initialize default parameter structures
    %           Output: params with default values for all groups
    %
    %       reload() - Reload both data and configuration from source
    %           Usage: cfg = cfg.reload()
    %           Output: Updated ConfigManager object
    %
    %       reload_params() - Reload only parameters (keeps data in memory)
    %           Usage: cfg = cfg.reload_params()
    %           Output: Updated ConfigManager object
    %
    %       save_config(filename) - Save current configuration to MAT file
    %           Input: filename - Path to output MAT file
    %           Usage: cfg.save_config('my_config.mat')
    %
    %       load_config(filename) - Load configuration from MAT file
    %           Input: filename - Path to input MAT file
    %           Usage: cfg = cfg.load_config('my_config.mat')
    %           Output: Updated ConfigManager object
    %
    %   Example:
    %       % Load BOU22 dataset and access parameters
    %       cfg = ConfigManager('DAS4Whale_bou22');
    %       filtered_data = butterworth_bp_filter(cfg.data.strain, ...
    %                                             cfg.params.bpFilter.cutoff_freq, ...
    %                                             cfg.params.bpFilter.order, ...
    %                                             cfg.data.sampling_frequency);
    %
    %       % Save and reload configuration
    %       cfg.save_config('analysis_config.mat');
    %       cfg = cfg.reload_params();
    %
    %   See also STRUCT, SAVE, LOAD
    
    properties
        dataset_name  % Dataset identifier string
        data          % Structure containing DAS data
        params        % Structure containing analysis parameters
    end
    
    methods
        function obj = ConfigManager(dataset_name)
            % Initialize configuration for specified dataset
            % dataset_name: 'DAS4Whale_bou22', 'DAS4Tracking_ror23'
            
            obj.dataset_name = dataset_name;
            
            % Load data and parameters based on dataset
            switch dataset_name
                case 'DAS4Whale_bou22'
                    obj.data = obj.load_data_bou22();
                    obj.params = obj.init_params_bou22();
                case 'DAS4Tracking_ror23'
                    obj.data = obj.load_data_ror23();
                    obj.params = obj.init_params_ror23();
                % Add more datasets here
                otherwise
                    error('Unknown dataset: %s', dataset_name);
            end
        end

        %% DAS4Whale_bou22
        function data = load_data_bou22(~)
            % Load BOU22 whale dataset
            filename = "20200627_052441_ch10001_to_ch15000_whale_raw_L160s.mat";
            dataset = load(filename);
            
            % Extract data
            data.time_and_date =			"2020-06-27, 05:24:41";
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

        function params = init_params_bou22(obj)
            % Initialize all parameter groups
            params = obj.init_default_params();
            
            % Bandpass filter parameters
            params.bpFilter.cutoff_freq =				[5 75]; % Hz
            params.bpFilter.order =						5;

			% 2D median filter filter parameters
            params.medianFilter2D.dimensions =			[3 3];
            
            % FK filter parameters
            params.fkFilter.c_range =					[];
            
            % Time-space plot parameters
            params.txPlot.time_lim =					[];
            params.txPlot.distance_lim =				[];
            params.txPlot.strain_lim =					[-30 -5];
            params.txPlot.prop_speed_km_s =				1.47; % km/s
            params.txPlot.speed_line_points =			[47.75 45.48];
            params.txPlot.channel_position_km =			42; % km
            params.txPlot.cpa_km =						42.8; % km
            params.txPlot.filename =					fullfile('Bou22_article_plots/', 'time_space_plot_bou22_article_whale.png');
            
            % Waveform parameters
            params.waveform.channel_position_km =		42; % km
            params.waveform.cpa_km =					42.8; % km
            params.waveform.time_lim =					[]; % s
            params.waveform.strain_lim =				[-1.3e-9 1.3e-9];
            params.waveform.filename_plot =				fullfile('Bou22_article_plots/', 'strain_waveform_bou22_article_whale.png');
            params.waveform.filename_audio =			fullfile('Bou22_article_plots/', 'strain_audio_bou22_article_whale.wav');
            
            % Spectrogram parameters
            params.spectrogram.channel_position_km =	42; % km
            params.spectrogram.nfft =					4096;
            params.spectrogram.window_len =				512;
            params.spectrogram.overlap_pct =			0.89;
            params.spectrogram.window =					hann(params.spectrogram.window_len, 'periodic');
            params.spectrogram.time_lim =				[]; % s
            params.spectrogram.frequency_lim =			[10 80]; % Hz
            params.spectrogram.strain_lim =				[-25 0];
            params.spectrogram.filename =				fullfile('Bou22_article_plots/', 'spectrogram_bou22_article_whale.png');
            
            % Space-frequency plot parameters
            params.fxPlot.nfft =						4096;
            params.fxPlot.time_interval =				[44 67]; % s
            params.fxPlot.time_window =					1.5;
            params.fxPlot.frequency_lim =				[5 75]; % Hz
            params.fxPlot.strain_lim =					[-20 -5];
			params.fxPlot.filename_animation =			fullfile('Bou22_article_plots/', 'spatio_spectral_animation_plot_bou22_article_whale.avi');
            params.fxPlot.filename =					fullfile('Bou22_article_plots/', 'spatio_spectral_plot_bou22_article_whale.png');
            
            % Correlation parameters
            params.correlation.channel_position_km =	42; % km
            params.correlation.offset_m =				300; % m
            params.correlation.time_lag =				0.2; % s
            params.correlation.time_interval =			[47 50]; % s
            params.correlation.filename_corrlogram =	fullfile('Bou22_article_plots/', 'correlogram_bou22_article_whale.png');
            params.correlation.filename_xcorr =			fullfile('Bou22_article_plots/', 'correlation_statistics_bou22_article_whale.png');
            params.correlation.filename =				fullfile('Bou22_article_plots/', 'correlation_statistics_bou22_article_whale.txt');

			% Event detection parameters
			params.eventDetection.filename_csv =		fullfile('Bou22_article_plots/', 'events_bou22_article_whale.csv');
			params.eventDetection.filename_plot =		fullfile('Bou22_article_plots/', 'events_detected_bou22_article_whale.png');
        end
        
        %% DAS4Tracking_ror23
        function data = load_data_ror23(~)
            % Template for another dataset
            filename = "20220822_122707_to_123037_ch9803_to_ch24509_sample_Freq_78_Hz.mat";
            dataset = load(filename);
            
            % Extract data (similar structure)
            data.time_and_date =			"2022-08-22, 12:27:07";
            data.strain =					dataset.data;
            data.time =						dataset.x1_time;
            data.sampling_interval_s =		dataset.info_sapmling_interval_s;            
            data.distance_m =				dataset.x1_absolute_channel;
            data.distance_km =				data.distance_m .* 1e-3;            
            data.nb_of_channels =			dataset.info_ntraces;
            data.nb_of_samples =			dataset.info_nsamples;            
            data.sampling_frequency_Hz =	dataset.info_sampling_frequency_Hz;
            data.gauge_length =				dataset.info_gauge_length;
            data.channel_distance_m =		data.distance_m(2) - data.distance_m(1);
        end

        function params = init_params_ror23(obj)
            % Initialize parameters
            params = obj.init_default_params();
            
            % Override with dataset-specific values
            % Bandpass filter parameters
            params.bpFilter.cutoff_freq =				[5 30]; % Hz
            params.bpFilter.order =						5;
            
            % FK filter parameters
            params.fkFilter.speed =						[];
            
            % Time-space plot parameters
            params.txPlot.time_lim =					[85 170];
            params.txPlot.distance_lim =				[50 100];
            params.txPlot.strain_lim =					[-50 -18];
            params.txPlot.prop_speed_km_s =				1.47; % km/s
            params.txPlot.speed_line_point =			[118.9 65.5];
            params.txPlot.channel_position_km =			60; % km
            params.txPlot.cpa_km =						58.9; % km
            params.txPlot.filename =					fullfile('Ror23_article_plots/', 'time_space_plot_ror23_article_whale.png');
            
            % Waveform parameters
            params.waveform.channel_position_km =		60; % km
            params.waveform.cpa_km =					58.9; % km
            params.waveform.time_lim =					[]; % s
            params.waveform.strain_lim =				[-1.7e-9 1.7e-9];
            params.waveform.filename_plot =				fullfile('Ror23_article_plots/', 'strain_waveform_ror23_article_whale.png');
            params.waveform.filename_plot_cpa =			fullfile('Ror23_article_plots/', 'strain_waveform_CPA_ror23_article_whale.png');
            params.waveform.filename_audio =			fullfile('Ror23_article_plots/', 'strain_audio_ror23_article_whale.wav');
            
            % Spectrogram parameters
            params.spectrogram.channel_position_km =	60; % km
            params.spectrogram.nfft =					4096;
            params.spectrogram.window_len =				512;
            params.spectrogram.overlap_pct =			0.89;
            params.spectrogram.window =					hann(params.spectrogram.window_len, 'periodic');
            params.spectrogram.time_lim =				[]; % s
            params.spectrogram.frequency_lim =			[5 35]; % Hz
            params.spectrogram.strain_lim =				[-35 -5];
            params.spectrogram.filename =				fullfile('Ror23_article_plots/', 'spectrogram_ror23_article_whale.png');
            
            % Space-frequency plot parameters
            params.fxPlot.nfft =						4096;
            params.fxPlot.time_interval =				[100 123]; % s
            params.fxPlot.time_window =					1.5;
            params.fxPlot.frequency_lim =				[5 35]; % Hz
            params.fxPlot.strain_lim =					[-35 -5];
			params.fxPlot.filename_animation =			fullfile('Ror23_article_plots/', 'spatio_spectral_animation_plot_ror23_article_whale.avi');
            params.fxPlot.filename =					fullfile('Ror23_article_plots/', 'spatio_spectral_plot_ror23_article_whale.png');
            
            % Correlation parameters
            params.correlation.channel_position_km =	60; % km
            params.correlation.offset_m =				300; % m
            params.correlation.time_lag =				0.2; % s
            params.correlation.time_interval =			[103 106]; % s
            params.correlation.filename_corrlogram =	fullfile('Ror23_article_plots/', 'correlogram_ror23_article_whale.png');
            params.correlation.filename_xcorr =			fullfile('Ror23_article_plots/', 'correlation_statistics_ror23_article_whale.png');
            params.correlation.filename =				fullfile('Ror23_article_plots/', 'correlation_statistics_ror23_article_whale.txt');

			% Event detection parameters
			params.eventDetection.filename_csv =		fullfile('Ror23_article_plots/', 'events_ror23_article_whale.csv');
        end
        
        %% initialization
        function params = init_default_params(~)
            % Initialize all parameter structures with defaults
            
            % Bandpass filter
            params.bpFilter.cutoff_freq = [1 100];
            params.bpFilter.order = 4;
            
            % FK filter
            params.fkFilter.speed = [];
            
            % TX plot
            params.txPlot.time_lim = [];
            params.txPlot.distance_lim = [];
            params.txPlot.strain_lim = [];
            params.txPlot.prop_speed_km_s = 1.5;
            params.txPlot.speed_line_point = [];
            params.txPlot.channel_position_km = [];
            params.txPlot.cpa_km = [];
            params.txPlot.filename = '';
            
            % Waveform
            params.waveform.channel_position_km = [];
            params.waveform.cpa_km = [];
            params.waveform.time_lim = [];
            params.waveform.strain_lim = [];
            params.waveform.filename_plot = '';
            params.waveform.filename_plot_cpa = '';
            params.waveform.filename_audio = '';
            
            % Spectrogram
            params.spectrogram.channel_position_km = [];
            params.spectrogram.nfft = 2048;
            params.spectrogram.window_len = 256;
            params.spectrogram.overlap_pct = 0.75;
            params.spectrogram.window = [];
            params.spectrogram.time_lim = [];
            params.spectrogram.frequency_lim = [];
            params.spectrogram.strain_lim = [];
            params.spectrogram.filename = '';
            
            % FX plot
            params.fxPlot.nfft = 2048;
            params.fxPlot.time_interval = [];
            params.fxPlot.time_window = [];
            params.fxPlot.frequency_lim = [];
            params.fxPlot.strain_lim = [];
            params.fxPlot.filename = '';
            
            % Correlation
            params.correlation.channel_position_km = [];
            params.correlation.offset_m = [];
            params.correlation.time_lag = [];
            params.correlation.time_interval = [];
            params.correlation.filename_corrlogram = '';
            params.correlation.filename_xcorr = '';
            params.correlation.filename = '';
		end

		%% utilities
        function obj = reload(obj)
            % Reload both data and configuration from source
            % Usage: cfg = cfg.reload()
            
            fprintf('Reloading data and configuration for dataset: %s\n', obj.dataset_name);
            
            % Re-initialize based on dataset
            switch obj.dataset_name
                case 'DAS4Whale_bou22'
                    obj.data = obj.load_data_bou22();
                    obj.params = obj.init_params_bou22();
                case 'DAS4Tracking_ror23'
                    obj.data = obj.load_data_ror23();
                    obj.params = obj.init_params_ror23();
                otherwise
                    error('Unknown dataset: %s', obj.dataset_name);
            end
            
            fprintf('Data and configuration reloaded successfully.\n');
        end

        function obj = reload_params(obj)
            % Reload only parameters (keeps existing data in memory)
            % Usage: cfg = cfg.reload_params()
            
			clc;
            fprintf('Reloading parameters for dataset: %s\n', obj.dataset_name);
            
            % Re-initialize only parameters based on dataset
            switch obj.dataset_name
                case 'DAS4Whale_bou22'
                    obj.params = obj.init_params_bou22();
                case 'DAS4Tracking_ror23'
                    obj.params = obj.init_params_ror23();
                otherwise
                    error('Unknown dataset: %s', obj.dataset_name);
            end
            
            fprintf('Parameters reloaded successfully.\n');
        end

        function save_config(obj, filename)
            % Save current configuration to MAT file
            % Usage: cfg.save_config('my_config.mat')
            
            config.dataset_name = obj.dataset_name;
            config.params = obj.params;
            config.timestamp = datetime('now');
            
            save(filename, 'config');
            fprintf('Configuration saved to: %s\n', filename);
        end
        
        function obj = load_config(obj, filename)
            % Load configuration from MAT file
            % Usage: cfg.load_config('my_config.mat')
            
            if ~isfile(filename)
                error('Configuration file not found: %s', filename);
            end
            
            config = load(filename);
            obj.params = config.config.params;
            
            fprintf('Configuration loaded from: %s\n', filename);
            if isfield(config.config, 'timestamp')
                fprintf('Saved on: %s\n', config.config.timestamp);
            end
        end
    end
end