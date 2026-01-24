function cfg = DAS4Whale_Bou22_cfg()

	cfg.data		= @data;
	cfg.bandpass	= @bandpass;
	cfg.medFilt		= @medFilt;
	cfg.fkFilt		= @fkFilt;
	cfg.tx			= @tx;
	cfg.waveform	= @waveform;
	cfg.spectrogram = @spectrogram;
	cfg.fx			= @fx;
	cfg.correlation = @correlation;
	
end

function data = data()
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

function bp = bandpass()
	bp.bp_cutoff_freq	= [5 75];
	bp.bp_order			= 5;
end

function medFilt = medFilt()
	medFilt.med_filt2D_dim = [3 3];
end

function fkFilt = fkFilt()
	fkFilt.fk_velocity_range = [];
end

function tx = tx()
	tx.tx_time_lim					= [];
	tx.tx_distance_lim				= [];
	tx.tx_strain_lim				= [-30 -5];
	tx.tx_prop_speed_km_s			= 1.47;
	tx.tx_speed_line_points			= [47.75 45.48];
	tx.tx_channel_position_km		= 42;
	tx.tx_cpa_km					= 42.8;
end

function wf = waveform()
	wf.wf_channel_position_km	= 42;
	wf.wf_cpa_km				= 42.8;
	wf.wf_time_lim				= [];
	wf.wf_strain_lim			= [-1.3e-9 1.3e-9];
	wf.filename_audio			= fullfile(dataset_name, ['strain_waveform_' dataset_name  '.wav']);
end

function sg = spectrogram()
	sg.sg_channel_position_km	= 42;
	sg.sg_nfft					= 4096;
	sg.sg_window_len			= 512;
	sg.sg_window				= hann(sg.sg_window_len, 'periodic');
	sg.sg_overlap_pct			= 0.89;
	sg.sg_time_lim				= [];
	sg.sg_frequency_lim			= [10 80];
	sg.sg_strain_lim			= [-25 0];
end

function fx = fx()
	fx.fx_nfft				= 4096;
	fx.fx_time_interval		= [44 67];
	fx.fx_time_window		= 1.5;
	fx.fx_frequency_lim		= [5 75];
	fx.fx_strain_lim		= [-25 -5];
	fx.filename_animation	= fullfile(dataset_name, ['fx_animation_' dataset_name  '.avi']);
end

function xcorr = correlation()
	xcorr.corr_channel_position_km	= 42;
	xcorr.corr_offset_m				= 300;
	xcorr.corr_time_lag				= 0.2;
	xcorr.corr_time_interval		= [47 50];
	xcorr.corr_cpa_km				= 42.8;
	xcorr.filename_xcorr_table		= fullfile(dataset_name, ['cross_corr_stats_' dataset_name  '.csv']);
end