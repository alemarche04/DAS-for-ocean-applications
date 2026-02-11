function cfg = Norway_cfg()
% NORWAY_CFG Configuration file for the Trondheimsfjord dataset.
%
%   CFG = NORWAY_CFG() returns a structure containing function handles
%   and parameters for processing DAS data from the Norway experiment.
%   This configuration includes geographical mapping of the cable and
%   vessel (source) positions.
%
%   Output:
%       cfg - Struct containing processing parameters and handles to 
%             sub-configuration and plotting functions.
%
%   See also: GEODETIC2ENU, H5READ, READSTRUCT

	cfg.load_data						= @load_data;
	cfg.bandpass						= @bandpass;
	cfg.medFilt							= @medFilt;
	cfg.fkFilt							= @fkFilt;
	cfg.tx_plot							= @tx_plot;
	cfg.waveform						= @waveform;
	cfg.spectrogram						= @spectrogram;
	cfg.fx_plot							= @fx_plot;
	cfg.correlation						= @correlation;
	cfg.geoCable						= @geoCable;
	cfg.sourcePos						= @sourcePos;
	cfg.plot_cable_geometry_2D			= @plot_cable_geometry_2D;
	cfg.plot_source_pos_2D				= @plot_source_pos_2D;
	cfg.plot_source_pos_all_2D			= @plot_source_pos_all_2D;
	cfg.plot_cable_source_3D			= @plot_cable_source_3D;
	cfg.plot_channel_on_cable			= @plot_channel_on_cable;
	cfg.plot_source_on_cable			= @plot_source_on_cable;
	cfg.plot_source_channel_on_cable	= @plot_source_channel_on_cable;
	
end
% -----------------------------------------------------------------------%

%% DATA LOADING
function data = load_data()
% LOAD_DATA Loads DAS strain data and metadata from HDF5 files.
%
%   Output:
%       data - Struct containing transposed strain matrix, time vectors,
%              distances, and sensor metadata (fs, dx, GL).

	filename = '122403_norway.hdf5';
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

    fkFilt.velocity_range = [1400 1435 1575 1600];
end
% -----------------------------------------------------------------------%

%% TIME-SPACE PLOT (T-X)
function tx = tx_plot()
% TX Configuration for time-distance visualization.
%
%   Output:
%       tx - Parameters for axis limits and propagation speed references.

    tx.time_lim					= [];
    tx.distance_lim				= [];
    tx.strain_lim				= [-60 -25];	% [dB]
    tx.prop_speed_km_s			= 1.47;     % Sound speed in water [km/s]
    tx.speed_line_points		= [1 1];
    tx.channel_position_km		= 0;
    tx.cpa_km					= 0;
end
% -----------------------------------------------------------------------%

%% STRAIN WAVEFORM
function wf = waveform()
% WAVEFORM Configuration for strain waveform visualization.
%
%   Output:
%       wf - Parameters for time-series plotting and audio export.

    wf.channel_position_km	= 0;
    wf.cpa_km				= 0;
    wf.time_lim				= [];
    wf.strain_lim			= [];
    wf.filename_audio		= fullfile('Norway/', 'strain_waveform_Norway.wav');
end
% -----------------------------------------------------------------------%

%% SPECTROGRAM
function sg = spectrogram()
% SPECTROGRAM Configuration for time-frequency analysis.
%
%   Output:
%       sg - STFT parameters (Window type, NFFT, Overlap) and plot parameters.

    sg.channel_position_km	= 0.18156; 
    sg.nfft					= 4096;
    sg.window_len			= 512;
    sg.window				= hann(sg.window_len, 'periodic');
    sg.overlap_pct			= 0.89;
    sg.time_lim				= [];
    sg.frequency_lim		= [800 4000]; % [Hz]
    sg.strain_lim			= [-30 0];
end
% -----------------------------------------------------------------------%

%% SPACE-FREQUENCY PLOT (F-X)
function fx = fx_plot()
% FX Configuration for space-frequency visualization.
%
%   Output:
%       fx - Parameters for spatial-frequency analysis.

    fx.nfft					= 4096;
    fx.time_interval		= [0 23];
    fx.time_window			= 1.5;
    fx.frequency_lim		= [];
    fx.strain_lim			= [];
    fx.filename_animation	= fullfile('Norway/', 'fx_animation_Norway.avi');
end
% -----------------------------------------------------------------------%

%% CROSS-CORRELATION STATISTICS
function xcorr = correlation()
% CORRELATION Parameters for inter-channel cross-correlation processing.
%
%   Output:
%       xcorr - Channel offsets, time lags, and statistics export settings.

    xcorr.channel_position_km	= 0;
    xcorr.offset_m				= 300;
    xcorr.time_lag				= 0.2;
    xcorr.time_interval			= [0 3];
    xcorr.cpa_km				= 0;
    xcorr.filename_table		= fullfile('Norway/', 'cross_corr_stats_Norway.csv');
end
% -----------------------------------------------------------------------%

%% GEOGRAPHICAL DATA & PLOTTING
function geoCable = geoCable()
% GEOCABLE Loads cable geometry from JSON and interpolates altitude.
    S = readstruct("cable-layout.json");
    C = S.features.geometry.coordinates{1};
    coord = vertcat(C{:});
    geoCable.lon = coord(:,1);
    geoCable.lat = coord(:,2);
    geoCable.up = coord(:,3);
    
    % linear interpolation for missing altitude data
    for i = 1:length(geoCable.up)
        if geoCable.up(i) == 0
            if i == 1, break; end
            k = i + 1;
            while k <= length(geoCable.up) && geoCable.up(k) == 0, k = k + 1; end
            if k > length(geoCable.up)
                geoCable.up(i) = geoCable.up(i-1);
            else
                geoCable.up(i) = (geoCable.up(i-1) + geoCable.up(k)) / 2;
            end
        end
    end
    geoCable.origin.lat = geoCable.lat(1);
    geoCable.origin.lon = geoCable.lon(1);
    geoCable.origin.up = 0;
end

function geo_origin = plot_cable_geometry_2D()
% PLOT_CABLE_GEOMETRY_2D Plots cable layout in Local ENU coordinates.
    cable_geometry = geoCable();
    geo_origin = cable_geometry.origin;
    [xEast, yNorth, ~] = geodetic2enu(cable_geometry.lat, cable_geometry.lon, cable_geometry.up, ...
        geo_origin.lat, geo_origin.lon, geo_origin.up, wgs84Ellipsoid);
    
    figure(Name="Cable Geometry (2D)", NumberTitle="off");
    plot(xEast, yNorth); axis equal; grid on;
	ylim([-50 2300]);
    xlabel('East (m)'); ylabel('North (m)');
end

function sourcePos = sourcePos(t_start, t_end)
% SOURCEPOS Loads vessel/source positions from CSV for a specific time range.
    opts = detectImportOptions('source-position.ods');
    opts = setvaropts(opts, 'datetime', 'Type', 'string'); 
    T = readtable('source-position.ods', opts);
    T.datetime = datetime(T.datetime, 'InputFormat', 'dd/MM/yyyy HH:mm:ss');
    time_index = timeofday(T.datetime);
    
    sourcePos = T(time_index >= t_start & time_index <= t_end, :);
    sourcePos.lat = table2array(sourcePos(:, 3));
    sourcePos.lon = table2array(sourcePos(:, 4));
end

function plot_source_pos_2D(sourcePos, geo_origin)
% PLOT_SOURCE_POS_2D Overlays a single source track on the cable geometry.
    plot_cable_geometry_2D();
    set(gcf, 'Name', 'Cable and Source Track');
    [xEast, yNorth, ~] = geodetic2enu(sourcePos.lat, sourcePos.lon, 0, ...
        geo_origin.lat, geo_origin.lon, geo_origin.up, wgs84Ellipsoid);
    hold on;
    scatter(xEast, yNorth, 10, 'red', 'filled');
    hold off;
end

function plot_source_pos_all_2D(sourcePos1, sourcePos2, sourcePos3, geo_origin)
% PLOT_SOURCE_POS_ALL_2D Plots three different source tracks (runs) on one map.
    plot_cable_geometry_2D();
    colors = {'red', 'green', 'blue'};
    sources = {sourcePos1, sourcePos2, sourcePos3};
    hold on;
    for i = 1:3
        [xE, yN, ~] = geodetic2enu(sources{i}.lat, sources{i}.lon, 0, ...
            geo_origin.lat, geo_origin.lon, geo_origin.up, wgs84Ellipsoid);
        scatter(xE, yN, 10, colors{i}, 'filled');
    end
    legend('Cable', 'Run 1', 'Run 2', 'Run 3');
	xlim([-50 450]); ylim([-200 100]);
    hold off;
end

function plot_cable_source_3D(sourcePos1, sourcePos2, sourcePos3)
% PLOT_CABLE_SOURCE_3D Creates a 3D visualization of cable depth and source tracks.
    cable = geoCable();
    geo_origin = cable.origin;
    [xE_c, yN_c, zU_c] = geodetic2enu(cable.lat, cable.lon, cable.up, ...
        geo_origin.lat, geo_origin.lon, geo_origin.up, wgs84Ellipsoid);
    
    figure(Name="Cable and Source 3D", NumberTitle="off");
    plot3(xE_c, yN_c, zU_c, 'b.-', 'LineWidth', 1.5); 
	hold on;
    
    sources = {sourcePos1, sourcePos2, sourcePos3};
    colors = {'r', 'g', 'b'};
    for i = 1:3
        [xE, yN, zU] = geodetic2enu(sources{i}.lat, sources{i}.lon, 0, ...
            geo_origin.lat, geo_origin.lon, geo_origin.up, wgs84Ellipsoid);
        plot3(xE, yN, zU, '-o', 'Color', colors{i}, 'MarkerSize', 3);
    end
    grid on; axis equal; view(3);
    xlabel('East (m)'); ylabel('North (m)'); zlabel('Altitude (m)');
	legend('Cable', 'Run 1', 'Run 2', 'Run 3');
	xlim([-50 450]); ylim([-200 100]); zlim([-150 0]);
	hold off;
end

function plot_channel_on_cable(target_channel_m)
% PLOT_CAHNNEL_ON_CABLE Creates a 2D and 3D visualization of a channel on
% the fiber optic cable

	% get cable geometry
    cable_geometry = geoCable();
    geo_origin = cable_geometry.origin;
    [xE_cable, yN_cable, zU_cable] = geodetic2enu(cable_geometry.lat, cable_geometry.lon, cable_geometry.up, ...
        geo_origin.lat, geo_origin.lon, geo_origin.up, wgs84Ellipsoid);
	%

	% compute incremental and cumulative distance of the FO cable
	dx = diff(xE_cable);
	dy = diff(yN_cable);
	dz = diff(zU_cable);

	dist_inc = sqrt(dx.^2 + dy.^2 + dz.^2);
	dist_cum = [0; cumsum(dist_inc)]; % start from 0m
	total_distance = dist_cum(end);
	%

	% check FO cable length bounds
	if target_channel_m < 0 || target_channel_m > total_distance
		warning("Target channel out of range.")
		return
	end
	%

	% compute channel position on the FO cable
	x_target = interp1(dist_cum, xE_cable, target_channel_m);
	y_target = interp1(dist_cum, yN_cable, target_channel_m);
	z_target = interp1(dist_cum, zU_cable, target_channel_m);
	%

	% plot 2D
	figure(Name="Cable Geometry and Channel position (2D)", NumberTitle="off");
    plot(xE_cable, yN_cable); axis equal; grid on;
	ylim([-50 2300]);
    xlabel('East (m)'); ylabel('North (m)');
	title(['Channel at meter: ', num2str(target_channel_m)]);
	hold on
	plot(x_target, y_target, 'ro', 'MarkerSize', 6, 'MarkerFaceColor', 'r');
	legend('Cable', 'Channel');
	hold off

	% plot 3D
	figure(Name="Cable Geometry and Channel position (3D)", NumberTitle="off");
    plot3(xE_cable, yN_cable, zU_cable, 'b.-', 'LineWidth', 1.5); hold on;
	plot3(x_target, y_target, z_target, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
	grid on; axis equal; view(3);
    xlabel('East (m)'); ylabel('North (m)'); zlabel('Altitude (m)');
	title(['Channel at meter: ', num2str(target_channel_m)]);
	legend('Cable', 'Channel');
	hold off
end

function plot_source_on_cable(time_and_date)
% PLOT_SOURCE_ON_CABLE Creates a 2D and 3D visualization of the source on 
% the FO cable at the time of recording

	% get cable geometry
    cable_geometry = geoCable();
    geo_origin = cable_geometry.origin;
    [xE_cable, yN_cable, zU_cable] = geodetic2enu(cable_geometry.lat, cable_geometry.lon, cable_geometry.up, ...
        geo_origin.lat, geo_origin.lon, geo_origin.up, wgs84Ellipsoid);
	%

	% import source position and time indexes from file
	opts = detectImportOptions('source-position.ods');
    opts = setvaropts(opts, 'datetime', 'Type', 'string'); 
    T = readtable('source-position.ods', opts);
    T.datetime = datetime(T.datetime, 'InputFormat', 'dd/MM/yyyy HH:mm:ss');
    time_index = timeofday(T.datetime);

    sourcePos.lat = table2array(T(:, 3));
    sourcePos.lon = table2array(T(:, 4));

	[xE_source, yN_source, ~] = geodetic2enu(sourcePos.lat, sourcePos.lon, 0, ...
        geo_origin.lat, geo_origin.lon, geo_origin.up, wgs84Ellipsoid);
	%
	
	% get time and date of the recording (current file)
	datetime_source = datetime(time_and_date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
	time_source = timeofday(datetime_source);

	[~, source_pos_idx] = min(abs(time_index - time_source));
	%
	
	% find source position at the time of recording
	xE_position = xE_source(source_pos_idx);
	yN_position = yN_source(source_pos_idx);
	zU_position = 0;
	%

	% plot 2D
	figure(Name="Cable Geometry and Source position (2D)", NumberTitle="off");
    plot(xE_cable, yN_cable); axis equal; grid on;
	ylim([-50 2300]);
    xlabel('East (m)'); ylabel('North (m)');
	hold on
	plot(xE_position, yN_position, 'go', 'MarkerSize', 6, 'MarkerFaceColor', 'g');
	legend('Cable', 'Source');
	hold off

	% plot 3D
	figure(Name="Cable Geometry and Source position (3D)", NumberTitle="off");
    plot3(xE_cable, yN_cable, zU_cable, 'b.-', 'LineWidth', 1.5); hold on;
	plot3(xE_position, yN_position, zU_position, 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 6);
	grid on; axis equal; view(3);
    xlabel('East (m)'); ylabel('North (m)'); zlabel('Altitude (m)');
	legend('Cable', 'Source');
	hold off

end

function plot_source_channel_on_cable(time_and_date, target_channel_m)
% PLOT_SOURCE_CHANNEL_ON_CABLE Creates a 2D and 3D visualization of a channel  
% and the source on the FO cable at the time of recording
	
	% get cable geometry
    cable_geometry = geoCable();
    geo_origin = cable_geometry.origin;
    [xE_cable, yN_cable, zU_cable] = geodetic2enu(cable_geometry.lat, cable_geometry.lon, cable_geometry.up, ...
        geo_origin.lat, geo_origin.lon, geo_origin.up, wgs84Ellipsoid);
	%

	% import source position and time indexes from file
	opts = detectImportOptions('source-position.ods');
    opts = setvaropts(opts, 'datetime', 'Type', 'string'); 
    T = readtable('source-position.ods', opts);
    T.datetime = datetime(T.datetime, 'InputFormat', 'dd/MM/yyyy HH:mm:ss');
    time_index = timeofday(T.datetime);

    sourcePos.lat = table2array(T(:, 3));
    sourcePos.lon = table2array(T(:, 4));

	[xE_source, yN_source, ~] = geodetic2enu(sourcePos.lat, sourcePos.lon, 0, ...
        geo_origin.lat, geo_origin.lon, geo_origin.up, wgs84Ellipsoid);
	%
	
	% get time and date of the recording (current file)
	datetime_source = datetime(time_and_date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
	time_source = timeofday(datetime_source);

	[~, source_pos_idx] = min(abs(time_index - time_source));
	%
	
	% find source position at the time of recording
	xE_position = xE_source(source_pos_idx);
	yN_position = yN_source(source_pos_idx);
	zU_position = 0;
	%

	% compute incremental and cumulative distance of the FO cable
	dx = diff(xE_cable);
	dy = diff(yN_cable);
	dz = diff(zU_cable);

	dist_inc = sqrt(dx.^2 + dy.^2 + dz.^2);
	dist_cum = [0; cumsum(dist_inc)]; % start from 0m
	total_distance = dist_cum(end);
	%

	% check FO cable length bounds
	if target_channel_m < 0 || target_channel_m > total_distance
		warning("Target channel out of range.")
		return
	end
	%

	% compute channel position on the FO cable
	x_target = interp1(dist_cum, xE_cable, target_channel_m);
	y_target = interp1(dist_cum, yN_cable, target_channel_m);
	z_target = interp1(dist_cum, zU_cable, target_channel_m);
	%

	% plot 2D
	figure(Name="Cable Geometry< Channel and Source position (2D)", NumberTitle="off");
    plot(xE_cable, yN_cable); axis equal; grid on;
	ylim([-50 2300]);
    xlabel('East (m)'); ylabel('North (m)');
	title(['Channel at meter: ', num2str(target_channel_m)]);
	hold on
	plot(xE_position, yN_position, 'go', 'MarkerSize', 6, 'MarkerFaceColor', 'g');
	plot(x_target, y_target, 'ro', 'MarkerSize', 6, 'MarkerFaceColor', 'r');
	legend('Cable', 'Source', 'Channel');
	hold off

	% plot 3D
	figure(Name="Cable Geometry, Channel and Source position (3D)", NumberTitle="off");
    plot3(xE_cable, yN_cable, zU_cable, 'b.-', 'LineWidth', 1.5); 
	hold on;
	plot3(xE_position, yN_position, zU_position, 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 6);
	plot3(x_target, y_target, z_target, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
	grid on; axis equal; view(3);
	title(['Channel at meter: ', num2str(target_channel_m)]);
    xlabel('East (m)'); ylabel('North (m)'); zlabel('Altitude (m)');
	legend('Cable', 'Source', 'Channel');
	xlim([-50 450]); ylim([-200 100]); zlim([-150 0]);
	hold off

end