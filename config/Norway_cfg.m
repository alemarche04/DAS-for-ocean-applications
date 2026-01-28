function cfg = Norway_cfg()

	cfg.data		= @data;
	cfg.bandpass	= @bandpass;
	cfg.medFilt		= @medFilt;
	cfg.fkFilt		= @fkFilt;
	cfg.tx			= @tx;
	cfg.waveform	= @waveform;
	cfg.spectrogram = @spectrogram;
	cfg.fx			= @fx;
	cfg.correlation = @correlation;
	cfg.geoCable	= @geoCable;
	
end

%% LOAD DATA
function data = data()
	filename = "095659.hdf5";
    
    % Extract data
    data.strain =									double(h5read(filename,"/data")) * 1e-9;
    data.sampling_interval_s =						double(h5read(filename,'/header/dt'));         
    data.channel_distance_m =						double(h5read(filename,'/header/dx'));
	[data.nb_of_channels, data.nb_of_samples] =		size(data.strain);
	data.time =										double(0:1:(data.nb_of_samples - 1)) .* data.sampling_interval_s;
	data.distance_m =								double(0:1:(data.nb_of_channels - 1)) .* data.channel_distance_m;
    data.distance_km =								double(data.distance_m .* 1e-3);
	data.dimensions =								[data.nb_of_channels data.nb_of_samples];
    data.sampling_frequency_Hz =					1/data.sampling_interval_s;
    data.gauge_length =								double(h5read(filename,'/header/gaugeLength'));

	data.time_and_date = "09:56:59";

end

%% BANDPASS FILTER
function bp = bandpass()
	bp.bp_cutoff_freq	= [5 75];
	bp.bp_order			= 3;
end

%% 2D MEDIAN FILTER
function medFilt = medFilt()
	medFilt.med_filt2D_dim = [3 3];
end

%% FK FILTER
function fkFilt = fkFilt()
	fkFilt.fk_velocity_range = [];
end

%% TIME-SPACE PLOT
function tx = tx()
	tx.tx_time_lim					= [];
	tx.tx_distance_lim				= [];
	tx.tx_strain_lim				= [];
	tx.tx_prop_speed_km_s			= 1.47;
	tx.tx_speed_line_points			= [1 1];
	tx.tx_channel_position_km		= 0;
	tx.tx_cpa_km					= 0;
end

%% STRAIN WAVEFORM
function wf = waveform()
	wf.wf_channel_position_km	= 0;
	wf.wf_cpa_km				= 0;
	wf.wf_time_lim				= [];
	wf.wf_strain_lim			= [];
	wf.filename_audio			= fullfile('Norway/', 'strain_waveform_Norway.wav');
end

%% SPECTROGRAM
function sg = spectrogram()
	sg.sg_channel_position_km	= 0;
	sg.sg_nfft					= 4096;
	sg.sg_window_len			= 512;
	sg.sg_window				= hann(sg.sg_window_len, 'periodic');
	sg.sg_overlap_pct			= 0.89;
	sg.sg_time_lim				= [];
	sg.sg_frequency_lim			= [];
	sg.sg_strain_lim			= [];
end

%% SPACE-FREQUENCY PLOT
function fx = fx()
	fx.fx_nfft				= 4096;
	fx.fx_time_interval		= [0 23];
	fx.fx_time_window		= 1.5;
	fx.fx_frequency_lim		= [];
	fx.fx_strain_lim		= [];
	fx.filename_animation	= fullfile('Norway/', 'fx_animation_Norway.avi');
end

%% CORSS CORRELATION STATISTICS
function xcorr = correlation()
	xcorr.corr_channel_position_km	= 0;
	xcorr.corr_offset_m				= 300;
	xcorr.corr_time_lag				= 0.2;
	xcorr.corr_time_interval		= [0 3];
	xcorr.corr_cpa_km				= 0;
	xcorr.filename_xcorr_table		= fullfile('Norway/', 'cross_corr_stats_Norway.csv');
end

%% CABLE GEOMETRY
function geoCable = geoCable()
	S = readstruct("cable-layout.json");
	C = S.features.geometry.coordinates{1};
	coord = vertcat(C{:});
	geoCable.lon = coord(:,1);
	geoCable.lat = coord(:,2);
	geoCable.alt = coord(:,3);
	for i = 1:length(geoCable.alt)
		if geoCable.alt(i) == 0
			if i == 1
				break
			end
			k = i + 1;
			while geoCable.alt(k) == 0
				k = k + 1;
			end
			if (k > length(geoCable.alt))
				geoCable.alt(i) = geoCable.alt(i-1);
			else
				geoCable.alt(i) = (geoCable.alt(i-1)+geoCable.alt(k))/2;
			end
		end
	end
end