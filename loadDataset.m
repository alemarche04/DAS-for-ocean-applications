function data = loadDataset(dataset_name)

	% dataset_name: one of the following
	%				'DAS4Whale_Bou22'
	%				'DAS4Tracking_Ror23'
	%				'DAS4Tracking_airgun_inner'
	%				'DAS4Tracking_airgun_outer'
    %				'OOI_Wilcock_2023'
	%				'Norway'
    
    % Load data and parameters based on dataset
	dataset_name = char(dataset_name);
	switch dataset_name
        case 'DAS4Whale_Bou22'
			filename = "20200627_052441_ch10001_to_ch15000_whale_raw_L160s.mat";
            data = load_data_DAS4Whale(filename);
			data.time_and_date = "2020-06-27, 05:24:41";
        case 'DAS4Tracking_Ror23'
			filename = "20220822_122707_to_123037_ch9803_to_ch24509_sample_Freq_78_Hz.mat";
            data = load_data_DAS4Tracking(filename);
			data.time_and_date = "2022-08-22, 12:27:07";
		case 'DAS4Tracking_airgun_inner'
			filename = "20220906_175107_to_175437_ch2450_to_ch9191_sample_Freq_125_Hz_inner.mat";
			data = load_data_DAS4Tracking(filename);
			data.time_and_date = "2022-09-06, 17:51:07";
		case 'DAS4Tracking_airgun_outer'
			filename = "20220906_175106_to_175436_ch2450_to_ch9191_sample_Freq_125_Hz_outer.mat";
			data = load_data_DAS4Tracking(filename);
			data.time_and_date = "2022-09-06, 17:51:06";
		case 'OOI_Wilcock_2023'
			filename = "North-C2-HF-P1kHz-GL30m-Sp2m-FS500Hz_2021-11-03T015731Z.h5";
			data = load_data_OOI(filename);
			data.time_and_date = "2021-11-03, 01:57:31";
		case 'Norway'
			filename = "095659.hdf5";
			data = load_data_Norway(filename);
			data.time_and_date = "09:56:59";
        otherwise
            error('Unknown dataset: %s', dataset_name);
	end
end

%% load data from DAS4Whale dataset
function data = load_data_DAS4Whale(filename)
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
function data = load_data_DAS4Tracking(filename)
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
function data = load_data_OOI(filename)
                
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
function data = load_data_Norway(filename)
                
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
