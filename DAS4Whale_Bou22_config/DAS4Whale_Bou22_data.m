function data = DAS4Whale_Bou22_data()
	filename = "20200627_052441_ch10001_to_ch15000_whale_raw_L160s.mat";
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

	data.time_and_date = "2020-06-27, 05:24:41";

end