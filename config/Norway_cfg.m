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

	cfg.load_data				= @load_data;
	cfg.bandpass				= @bandpass;
	cfg.medFilt					= @medFilt;
	cfg.fkFilt					= @fkFilt;
	cfg.tx_plot					= @tx_plot;
	cfg.waveform				= @waveform;
	cfg.spectrogram				= @spectrogram;
	cfg.fx_plot					= @fx_plot;
	cfg.correlation				= @correlation;
	cfg.geoCable				= @geoCable;
	cfg.sourcePos				= @sourcePos;
	cfg.plot_cable_geometry_2D	= @plot_cable_geometry_2D;
	cfg.plot_source_pos_2D		= @plot_source_pos_2D;
	cfg.plot_source_pos_all_2D	= @plot_source_pos_all_2D;
	cfg.plot_cable_source_3D	= @plot_cable_source_3D;
	
end

% -----------------------------------------------------------------------%
%% DATA LOADING
function data = load_data()
% LOAD_DATA Loads DAS strain data and metadata from HDF5 files.
%
%   Output:
%       data - Struct containing transposed strain matrix, time vectors,
%              distances, and sensor metadata (fs, dx, GL).

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
	
	% Transpose from Row-Major (Python) to Column-Major (MATLAB)
	data.strain	= data.strain'; 
end

% -----------------------------------------------------------------------%
%% FILTERS
function bp = bandpass()
% BANDPASS Configuration for frequency bandpass filtering.
    bp.bp_cutoff_freq	= [5 75]; % [Hz]
    bp.bp_order			= 3;
end

function medFilt = medFilt()
% MEDFILT Configuration for 2D median denoising.
    medFilt.med_filt2D_dim = [3 3];
end

function fkFilt = fkFilt()
% FKFILT Configuration for Frequency-Wavenumber filtering.
    fkFilt.fk_velocity_range = [];
end

% -----------------------------------------------------------------------%
%% VISUALIZATION PARAMETERS
function tx = tx_plot()
% TX_PLOT Configuration for Time-Space (LTT) plot visualization.
    tx.tx_time_lim					= [];
    tx.tx_distance_lim				= [];
    tx.tx_strain_lim				= [-50 0]; % [dB]
    tx.tx_prop_speed_km_s			= 1.47;
    tx.tx_speed_line_points			= [1 1];
    tx.tx_channel_position_km		= 0;
    tx.tx_cpa_km					= 0;
end

function wf = waveform()
% WAVEFORM Configuration for strain time-series visualization.
    wf.wf_channel_position_km	= 0;
    wf.wf_cpa_km				= 0;
    wf.wf_time_lim				= [];
    wf.wf_strain_lim			= [];
    wf.filename_audio			= fullfile('Norway/', 'strain_waveform_Norway.wav');
end

function sg = spectrogram()
% SPECTROGRAM Configuration for spectral analysis (STFT).
    sg.sg_channel_position_km	= 0;
    sg.sg_nfft					= 4096;
    sg.sg_window_len			= 512;
    sg.sg_window				= hann(sg.sg_window_len, 'periodic');
    sg.sg_overlap_pct			= 0.89;
    sg.sg_time_lim				= [];
    sg.sg_frequency_lim			= [];
    sg.sg_strain_lim			= [];
end

function fx = fx_plot()
% FX_PLOT Configuration for Space-Frequency spectral visualization.
    fx.fx_nfft				= 4096;
    fx.fx_time_interval		= [0 23];
    fx.fx_time_window		= 1.5;
    fx.fx_frequency_lim		= [];
    fx.fx_strain_lim		= [];
    fx.filename_animation	= fullfile('Norway/', 'fx_animation_Norway.avi');
end

% -----------------------------------------------------------------------%
%% CROSS-CORRELATION
function xcorr = correlation()
% CORRELATION Configuration for channel cross-correlation analysis.
    xcorr.corr_channel_position_km	= 0;
    xcorr.corr_offset_m				= 300;
    xcorr.corr_time_lag				= 0.2;
    xcorr.corr_time_interval		= [0 3];
    xcorr.corr_cpa_km				= 0;
    xcorr.filename_xcorr_table		= fullfile('Norway/', 'cross_corr_stats_Norway.csv');
end

% -----------------------------------------------------------------------%
%% GEOGRAPHICAL DATA & PLOTTING
function geoCable = geoCable()
% GEOCABLE Loads cable geometry from JSON and interpolates altitude.
%
%   Output:
%       geoCable - Struct with lat, lon, and depth (up) coordinates.
    S = readstruct("cable-layout.json");
    C = S.features.geometry.coordinates{1};
    coord = vertcat(C{:});
    geoCable.lon = coord(:,1);
    geoCable.lat = coord(:,2);
    geoCable.up = coord(:,3);
    
    % Linear interpolation for missing altitude data
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
    xlabel('East (m)'); ylabel('North (m)');
end

function sourcePos = sourcePos(t_start, t_end)
% SOURCEPOS Loads vessel/source positions from CSV for a specific time range.
%
%   Inputs:
%       t_start, t_end - duration objects/time values for filtering.
    opts = detectImportOptions('source-position.csv');
    opts = setvaropts(opts, 'datetime', 'Type', 'string'); 
    T = readtable('source-position.csv', opts);
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
    hold off;
end

function plot_cable_source_3D(sourcePos1, sourcePos2, sourcePos3)
% PLOT_CABLE_SOURCE_3D Creates a 3D visualization of cable depth and source tracks.
    cable = geoCable();
    geo_origin = cable.origin;
    [xE_c, yN_c, zU_c] = geodetic2enu(cable.lat, cable.lon, cable.up, ...
        geo_origin.lat, geo_origin.lon, geo_origin.up, wgs84Ellipsoid);
    
    figure(Name="Cable and Source 3D", NumberTitle="off");
    plot3(xE_c, yN_c, zU_c, 'b.-', 'LineWidth', 1.5); hold on;
    
    sources = {sourcePos1, sourcePos2, sourcePos3};
    colors = {'r', 'g', 'b'};
    for i = 1:3
        [xE, yN, zU] = geodetic2enu(sources{i}.lat, sources{i}.lon, 0, ...
            geo_origin.lat, geo_origin.lon, geo_origin.up, wgs84Ellipsoid);
        plot3(xE, yN, zU, '-o', 'Color', colors{i}, 'MarkerSize', 3);
    end
    grid on; axis equal; view(3);
    xlabel('East (m)'); ylabel('North (m)'); zlabel('Altitude (m)');
end