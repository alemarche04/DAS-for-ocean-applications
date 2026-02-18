function loader = DatasetLoader()
	loader.DAS4Whale		= @DAS4Whale;
	loader.DAS4Tracking		= @DAS4Tracking;
	loader.OOI_Wilcock		= @OOI_Wilcock;
	loader.Trondheim		= @Trondheim;
end

%% DAS4Whale
% https://zenodo.org/records/5823343
function data = DAS4Whale(dataset_name)

	% Check if the dataset exists
	if ~isfile(fullfile(fileparts(which(dataset_name)), dataset_name))
        error('Dataset file does not exist: %s', dataset_name);
	end

	dataset = load(dataset_name);
    
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

%% DAS4Tracking
% https://dataverse.no/dataset.xhtml?persistentId=doi:10.18710/Q8OSON
function data = DAS4Tracking(dataset_name)

	% Check if the dataset exists
	if ~isfile(fullfile(fileparts(which(dataset_name)), dataset_name))
        error('Dataset file does not exist: %s', dataset_name);
	end

	dataset = load(dataset_name);
    
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

%% OOI_Wilcock
% https://oceanobservatories.org/pi-instrument/rapid-a-community-test-of-distributed-acoustic-sensing-on-the-ocean-observatories-initiative-regional-cabled-array/
function data = OOI_Wilcock(dataset_name)

	% Check if the dataset exists
	if ~isfile(fullfile(fileparts(which(dataset_name)), dataset_name))
        error('Dataset file does not exist: %s', dataset_name);
	end

	% Extract data
    data.strain =					double(h5read(dataset_name,"/Acquisition/Raw[0]/RawData"))';
    data.time =						double(h5read(dataset_name,"/Acquisition/Raw[0]/RawDataTime"))';
	data.time =						(data.time - data.time(1)) .* 1e-6;
    data.sampling_interval_s =		data.time(2) - data.time(1);            
    data.channel_distance_m =		double(h5readatt(dataset_name,'/Acquisition','SpatialSamplingInterval'));
	data.nb_of_channels =			h5readatt(dataset_name,'/Acquisition','NumberOfLoci');
    data.nb_of_samples =			length(data.time);
	data.distance_m =				double(0:1:(data.nb_of_channels - 1)) .* data.channel_distance_m;
    data.distance_km =				data.distance_m .* 1e-3; 
	data.dimensions =				[data.nb_of_channels data.nb_of_samples];
    data.sampling_frequency_Hz =	h5readatt(dataset_name,'/Acquisition/Raw[0]','OutputDataRate');
    data.gauge_length =				h5readatt(dataset_name,'/Acquisition','GaugeLength');
end

%% Trondheim
function data = Trondheim(dataset_name)

	% Check if the dataset exists
	if ~isfile(fullfile(fileparts(which(dataset_name)), dataset_name))
        error('Dataset file does not exist: %s', dataset_name);
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
    data.strain						= h5read(loaded_filename, '/trace');
	data.time						= h5read(loaded_filename, '/tx');
	data.distance_m					= h5read(loaded_filename, '/dist');
	data.distance_km				= double(data.distance_m .* 1e-3);
	
	temp_time						= h5read(loaded_filename, '/file_begin_time_utc');
	data.time_and_date				= temp_time{1}; 
	
	data.sampling_frequency_Hz		= h5read(loaded_filename, '/metadata/fs');
	data.channel_distance_m			= h5read(loaded_filename, '/metadata/dx');
	data.gauge_length				= h5read(loaded_filename, '/metadata/GL');
	data.nb_of_channels				= h5read(loaded_filename, '/metadata/nx');
	data.nb_of_samples				= h5read(loaded_filename, '/metadata/ns');
	data.sampling_interval_s		= 1/data.sampling_frequency_Hz;
	data.dimensions					= [data.nb_of_channels data.nb_of_samples];
	
	% Transpose from Row-Major (Python) to Column-Major (MATLAB)
	data.strain	= data.strain'; 
end