function cfg = Norway_cfg()

	cfg.data					= @data;
	cfg.bandpass				= @bandpass;
	cfg.medFilt					= @medFilt;
	cfg.fkFilt					= @fkFilt;
	cfg.tx						= @tx;
	cfg.waveform				= @waveform;
	cfg.spectrogram				= @spectrogram;
	cfg.fx						= @fx;
	cfg.correlation				= @correlation;
	cfg.geoCable				= @geoCable;
	cfg.sourcePos				= @sourcePos;
	cfg.plot_cable_geometry_2D	= @plot_cable_geometry_2D;
	cfg.plot_source_pos_2D		= @plot_source_pos_2D;
	cfg.plot_source_pos_all_2D	= @plot_source_pos_all_2D;
	cfg.plot_calbe_source_3D	= @plot_calbe_source_3D;
	
end

%% LOAD DATA
function data = data()
	% filename = "095659.hdf5";
    
    % Extract data
    % data.strain =										double(h5read(filename,"/data")) * 1e-9;
    % data.sampling_interval_s =						double(h5read(filename,'/header/dt'));         
    % data.channel_distance_m =							double(h5read(filename,'/header/dx'));
	% [data.nb_of_channels, data.nb_of_samples] =		size(data.strain);
	% data.time =										double(0:1:(data.nb_of_samples - 1)) .* data.sampling_interval_s;
	% data.channel_number =								double(h5read(filename,'/header/channels'));
	% data.distance_m =									double(h5read(filename,'/cableSpec/sensorDistances'));
    % data.distance_km =								double(data.distance_m .* 1e-3);
	% data.dimensions =									[data.nb_of_channels data.nb_of_samples];
    % data.sampling_frequency_Hz =						1/data.sampling_interval_s;
    % data.gauge_length =								double(h5read(filename,'/header/gaugeLength'));
	% 
	% data.time_and_date = "09:56:59";
	
	filename = 'norway_095659.hdf5';

	data.strain						= h5read(filename, '/trace');
	data.time						= h5read(filename, '/tx');
	data.distance_m					= h5read(filename, '/dist');
	data.distance_km				= double(data.distance_m .* 1e-3);
	
	temp_time						= h5read(filename, '/file_begin_time_utc');
	data.time_and_date				= temp_time{1}; 
	
	data.sampling_frequency_Hz		= h5read(filename, '/metadata/fs');
	data.channel_distance_m			= h5read(filename, '/metadata/dx');
	data.gauge_length				= h5read(filename, '/metadata/GL');
	data.nb_of_channels				= h5read(filename, '/metadata/nx');
	data.nb_of_samples				= h5read(filename, '/metadata/ns');

	data.sampling_interval_s		= 1/data.sampling_frequency_Hz;
	data.dimensions					= [data.nb_of_channels data.nb_of_samples];
	
	% Python is "Row-Major", MATLAB is "Column-Major", 
	data.strain	= data.strain'; 
	
	% test
	% disp(['Strain shape: ', num2str(size(data.strain))]);

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
	tx.tx_strain_lim				= [-50 0];
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
	geoCable.up = coord(:,3);
	for i = 1:length(geoCable.up)
		if geoCable.up(i) == 0
			if i == 1
				break
			end
			k = i + 1;
			while geoCable.up(k) == 0
				k = k + 1;
			end
			if (k > length(geoCable.up))
				geoCable.up(i) = geoCable.up(i-1);
			else
				geoCable.up(i) = (geoCable.up(i-1)+geoCable.up(k))/2;
			end
		end
	end
	geoCable.origin.lat = geoCable.lat(1);
	geoCable.origin.lon = geoCable.lon(1);
	geoCable.origin.up = 0;
end

%% PLOT CABLE GEOMETRY
function geo_origin = plot_cable_geometry_2D()
	cable_geometry = geoCable();
	geo_origin = cable_geometry.origin;
	[xEast_cable, yNorth_cable, ~] = geodetic2enu(cable_geometry.lat, cable_geometry.lon, cable_geometry.up, ...
		geo_origin.lat, geo_origin.lon, geo_origin.up, wgs84Ellipsoid);

	figure(Name="Cable Geometry", NumberTitle="off");
	plot(xEast_cable, yNorth_cable)
	axis('equal');
	grid on;
	xlabel('East (m)');
	ylabel('North (m)');
	ylim([-100 2300]);
end

%% SOURCE POSITION
function sourcePos = sourcePos(t_start, t_end)
	opts = detectImportOptions('source-position.csv');
	opts = setvaropts(opts, 'datetime', 'Type', 'string'); 
	T = readtable('source-position.csv', opts);
	T.datetime = datetime(T.datetime, 'InputFormat', 'dd/MM/yyyy HH:mm:ss');
	time_index = timeofday(T.datetime);
	
	sourcePos = T(time_index >= t_start & time_index <= t_end, :);
	sourcePos.lat = table2array(sourcePos(:, 3));
	sourcePos.lon = table2array(sourcePos(:, 4));
end

%% PLOT SINGLE RUN SOURCE POSITION 2D
function plot_source_pos_2D(sourcePos, geo_origin)
	plot_cable_geometry_2D()
	set(gcf, 'Name', 'Cable Geometry and Source Position');

	[xEast_source, yNorth_source, ~] = geodetic2enu(sourcePos.lat, sourcePos.lon, 0, ...
		geo_origin.lat, geo_origin.lon, geo_origin.up, wgs84Ellipsoid);

	hold on
	scatter(xEast_source, yNorth_source, 10, 'red', 'filled');
	ylim([-400 2300])
	hold off

end

%% PLOT SOURCE POSITION ALL RUNS 2D
function plot_source_pos_all_2D(sourcePos1, sourcePos2, sourcePos3, geo_origin)
	plot_cable_geometry_2D();
	set(gcf, 'Name', 'Cable Geometry and Source Position');

	[xEast_source_run1, yNorth_source_run1, ~] = geodetic2enu(sourcePos1.lat, sourcePos1.lon, 0, ...
		geo_origin.lat, geo_origin.lon, geo_origin.up, wgs84Ellipsoid);
	[xEast_source_run2, yNorth_source_run2, ~] = geodetic2enu(sourcePos2.lat, sourcePos2.lon, 0, ...
		geo_origin.lat, geo_origin.lon, geo_origin.up, wgs84Ellipsoid);
	[xEast_source_run3, yNorth_source_run3, ~] = geodetic2enu(sourcePos3.lat, sourcePos3.lon, 0, ...
		geo_origin.lat, geo_origin.lon, geo_origin.up, wgs84Ellipsoid);

	hold on
	scatter(xEast_source_run1, yNorth_source_run1, 10, 'red', 'filled');
	scatter(xEast_source_run2, yNorth_source_run2, 10, 'green', 'filled');
	scatter(xEast_source_run3, yNorth_source_run3, 10, 'blue', 'filled');
	xlim([-100 600])
	ylim([-250 200])
	legend('Cable', 'Source position 1st run', 'Source position 2nd run', 'Source position 3rd run');
	hold off
end

%% PLOT CABLE AND SOURCE 3D
function plot_calbe_source_3D(sourcePos1, sourcePos2, sourcePos3)
	cable_geometry = geoCable();
	geo_origin = cable_geometry.origin;
	[xEast_cable, yNorth_cable, zUp_cable] = geodetic2enu(cable_geometry.lat, cable_geometry.lon, cable_geometry.up, ...
		geo_origin.lat, geo_origin.lon, geo_origin.up, wgs84Ellipsoid);
	[xEast_source_run1, yNorth_source_run1, zUp_source_run1] = geodetic2enu(sourcePos1.lat, sourcePos1.lon, 0, ...
		geo_origin.lat, geo_origin.lon, geo_origin.up, wgs84Ellipsoid);
	[xEast_source_run2, yNorth_source_run2, zUp_source_run2] = geodetic2enu(sourcePos2.lat, sourcePos2.lon, 0, ...
		geo_origin.lat, geo_origin.lon, geo_origin.up, wgs84Ellipsoid);
	[xEast_source_run3, yNorth_source_run3, zUp_source_run3] = geodetic2enu(sourcePos3.lat, sourcePos3.lon, 0, ...
		geo_origin.lat, geo_origin.lon, geo_origin.up, wgs84Ellipsoid);

	figure(Name="Cable Geometry and Source Positio 3D", NumberTitle="off");
	plot3(xEast_cable, yNorth_cable, zUp_cable, 'b.-', 'LineWidth', 1.5, 'MarkerSize', 10);
	grid on;
	xlabel('East (m)');
	ylabel('North (m)');
	zlabel('Altitude (m)');
	axis equal;
	hold on
	plot3(xEast_source_run1, yNorth_source_run1, zUp_source_run1, '-o','Color','red', 'MarkerSize', 3);
	plot3(xEast_source_run2, yNorth_source_run2, zUp_source_run2, '-o','Color','green', 'MarkerSize', 3);
	plot3(xEast_source_run3, yNorth_source_run3, zUp_source_run3, '-o','Color','blue', 'MarkerSize', 3);
	legend('Cable', 'Source position 1st run', 'Source position 2nd run', 'Source position 3rd run');
	xlim([-100 600])
	ylim([-250 200])
	zlim([-150, 0])
	view(3);
	hold off
end