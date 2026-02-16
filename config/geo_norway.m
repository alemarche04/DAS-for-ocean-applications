function geo = geo_norway()
% GEO_NORWAY Function file for position file from Trondheim dataset.
%
%   Geographical mapping of the cable and vessel (source) positions.
%
%   Output:
%       geo - Struct containing sub-configuration and plotting functions.
%
%   See also: READSTRUCT, VERTCAT, GEODETIC2ENU, DIFF, CUMCUM, PLOT, PLOT3

	geo.geoCable						= @geoCable;
	geo.sourcePos						= @sourcePos;
	geo.sourcePos_interval				= @sourcePos_interval;
	geo.plot_cable_geometry_2D			= @plot_cable_geometry_2D;
	geo.plot_cable_geometry_3D			= @plot_cable_geometry_3D;
	geo.plot_source_pos_2D				= @plot_source_pos_2D;
	geo.plot_source_pos_all_2D			= @plot_source_pos_all_2D;
	geo.plot_cable_source_3D			= @plot_cable_source_3D;
	geo.get_channel_on_cable			= @get_channel_on_cable;
	geo.plot_channel_on_cable			= @plot_channel_on_cable;
	geo.get_source_on_cable				= @get_source_on_cable;
	geo.plot_source_on_cable			= @plot_source_on_cable;
	geo.plot_source_channel_on_cable	= @plot_source_channel_on_cable;
end

%% GEOGRAPHICAL DATA & PLOTTING
function geoCable = geoCable()
% GEOCABLE Loads cable geometry from JSON and interpolates altitude.
    S = readstruct("cable-layout.json");
    C = S.features.geometry.coordinates{1};
    coord = vertcat(C{:});
    cable_lon = coord(:,1);
    cable_lat = coord(:,2);
    cable_up = coord(:,3);
    
    % linear interpolation for missing altitude data
    for i = 1:length(cable_up)
        if cable_up(i) == 0
            if i == 1, break; end
            k = i + 1;
            while k <= length(cable_up) && cable_up(k) == 0, k = k + 1; end
            if k > length(cable_up)
                cable_up(i) = cable_up(i-1);
            else
                cable_up(i) = (cable_up(i-1) + cable_up(k)) / 2;
            end
        end
    end
    geoCable.origin.lat = cable_lat(1);
    geoCable.origin.lon = cable_lon(1);
    geoCable.origin.up = 0;

	[geoCable.xE, geoCable.yN, geoCable.zU] = geodetic2enu(cable_lat, cable_lon, cable_up, ...
        geoCable.origin.lat, geoCable.origin.lon, geoCable.origin.up, wgs84Ellipsoid);

	% compute incremental and cumulative distance of the FO cable
	dx = diff(geoCable.xE);
	dy = diff(geoCable.yN);
	dz = diff(geoCable.zU);

	geoCable.dist_inc = sqrt(dx.^2 + dy.^2 + dz.^2);
	geoCable.dist_cum = [0; cumsum(geoCable.dist_inc)]; % start from 0m
	geoCable.total_distance = geoCable.dist_cum(end);
	%
end

%========================================================================%

function plot_cable_geometry_2D()
% PLOT_CABLE_GEOMETRY_2D Plots cable layout (2D) in Local ENU coordinates.
    cable = geoCable();
    
    figure(Name="Cable Geometry (2D)", NumberTitle="off");
    plot(cable.xE, cable.yN); 
	title("Cable geometry (2D)");
	axis equal; grid on;
	ylim([-50 2300]);
    xlabel('East (m)'); ylabel('North (m)');
end

%========================================================================%

function plot_cable_geometry_3D()
% PLOT_CABLE_GEOMETRY_3D Plots cable layout (3D) in Local ENU coordinates.
    cable = geoCable();
    
    figure(Name="Cable Geometry (3D)", NumberTitle="off");
    plot3(cable.xE, cable.yN, cable.zU, 'b.-', 'LineWidth', 1.5); 
	title("Cable geometry (3D)");
	grid on; axis equal; view(3);
    xlabel('East (m)'); ylabel('North (m)'); zlabel('Altitude (m)');
	xlim([-50 450]); ylim([-200 100]); zlim([-150 0]);
end

%========================================================================%

function source = sourcePos()
% SOURCEPOS Loads vessel/source positions from CSV.
    opts = detectImportOptions('source-position.ods');
    opts = setvaropts(opts, 'datetime', 'Type', 'string'); 
    T = readtable('source-position.ods', opts); 
	T.datetime = datetime(T.datetime, 'InputFormat', 'dd/MM/yyyy HH:mm:ss');
    source.time_index = timeofday(T.datetime);

    source_lat = table2array(T(:, 3));
    source_lon = table2array(T(:, 4));

	cable = geoCable();

	[source.xE, source.yN, source.zU] = geodetic2enu(source_lat, source_lon, 0, ...
        cable.origin.lat, cable.origin.lon, cable.origin.up, wgs84Ellipsoid);
end

%========================================================================%

function source = sourcePos_interval(t_start, t_end)
% SOURCEPOS Loads vessel/source positions from CSV for a specific time range.
    opts = detectImportOptions('source-position.ods');
    opts = setvaropts(opts, 'datetime', 'Type', 'string'); 
    T = readtable('source-position.ods', opts);
    T.datetime = datetime(T.datetime, 'InputFormat', 'dd/MM/yyyy HH:mm:ss');
    source.time_index = timeofday(T.datetime);
    
    target_interval = T(source.time_index >= t_start & source.time_index <= t_end, :);
    source_lat = table2array(target_interval(:, 3));
    source_lon = table2array(target_interval(:, 4));

	cable = geoCable();

	[source.xE, source.yN, source.zU] = geodetic2enu(source_lat, source_lon, 0, ...
        cable.origin.lat, cable.origin.lon, cable.origin.up, wgs84Ellipsoid);
end

%========================================================================%

function plot_source_pos_2D(sourcePos)
% PLOT_SOURCE_POS_2D Overlays a single source track on the cable geometry.
    plot_cable_geometry_2D();
    set(gcf, 'Name', 'Cable and Source Track');
    hold on;
    scatter(sourcePos.xE, sourcePos.yN, 10, 'red', 'filled');
	title("Cable geometry and Source track(2D)");
    hold off;
end

%========================================================================%

function plot_source_pos_all_2D(sourcePos1, sourcePos2, sourcePos3)
% PLOT_SOURCE_POS_ALL_2D Plots three different source tracks (runs) on one map.
    plot_cable_geometry_2D();
	set(gcf, 'Name', 'Cable and Source Tracks (2D)');

    colors = {'red', 'green', 'blue'};
    sources = {sourcePos1, sourcePos2, sourcePos3};

    hold on;
	for i = 1:3
        scatter(sources{i}.xE, sources{i}.yN, 10, colors{i}, 'filled');
	end
	title("Cable geometry and Source tracks (2D)");
    legend('Cable', 'Run 1', 'Run 2', 'Run 3');
	xlim([-50 450]); ylim([-200 100]);
    hold off;
end

%========================================================================%

function plot_cable_source_3D(sourcePos1, sourcePos2, sourcePos3)
% PLOT_CABLE_SOURCE_3D Creates a 3D visualization of cable depth and source tracks.
    plot_cable_geometry_3D();
	set(gcf, 'Name', 'Cable and Source Tracks (3D)');
    
    sources = {sourcePos1, sourcePos2, sourcePos3};
    colors = {'r', 'g', 'b'};

	hold on;
	for i = 1:3
        plot3(sources{i}.xE, sources{i}.yN, sources{i}.zU, '-o', 'Color', colors{i}, 'MarkerSize', 3);
	end
	title("Cable geometry and Source tracks (3D)");
    grid on; axis equal; view(3);
    xlabel('East (m)'); ylabel('North (m)'); zlabel('Altitude (m)');
	legend('Cable', 'Run 1', 'Run 2', 'Run 3');
	xlim([-50 450]); ylim([-200 100]); zlim([-150 0]);
	hold off;
end

%========================================================================%

function channel = get_channel_on_cable(target_channel_m)
% GET_CAHNNEL_ON_CABLE Compute the position of a channel on the FO cable.

	% get cable geometry
    cable = geoCable();

	% check FO cable length bounds
	if target_channel_m < 0 || target_channel_m > cable.total_distance
		warning("Target channel out of range.")
		return
	end
	%

	% compute channel position on the FO cable
	channel.x = interp1(cable.dist_cum, cable.xE, target_channel_m);
	channel.y = interp1(cable.dist_cum, cable.yN, target_channel_m);
	channel.z = interp1(cable.dist_cum, cable.zU, target_channel_m);
	%
end

%========================================================================%

function plot_channel_on_cable(target_channel_m)
% PLOT_CAHNNEL_ON_CABLE Creates a 2D and 3D visualization of a channel on
% the fiber optic cable.

	% get channel position on FO cable
    channel = get_channel_on_cable(target_channel_m);

	% plot 2D
	plot_cable_geometry_2D();
	set(gcf, 'Name', 'Channel on FO cable (2D)');
	
	hold on
	plot(channel.x, channel.y, 'ro', 'MarkerSize', 6, 'MarkerFaceColor', 'r');

	ylim([-50 2300]);
	title('Cable Geometry and Channel position (2D)')
	subtitle(['Channel at meter: ', num2str(target_channel_m)]);
	legend('Cable', 'Channel');
	hold off
	%

	% plot 3D
	plot_cable_geometry_3D();
	set(gcf, 'Name', 'Channel on FO cable (3D)');
	
	hold on
	plot3(channel.x, channel.y, channel.z, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
	
	title('Cable Geometry and Channel position (3D)')
	subtitle(['Channel at meter: ', num2str(target_channel_m)]);
	legend('Cable', 'Channel');
	hold off
	%
end

%========================================================================%

function source = get_source_on_cable(time_and_date)
% GET_SOURCE_ON_CABLE Compute the position of the source at a given time.

	% import source position and time indexes from file
	sPos = sourcePos();
	
	% get time and date of the recording (current file)
	datetime_source = datetime(time_and_date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
	time_source = timeofday(datetime_source);

	[~, source_pos_idx] = min(abs(sPos.time_index - time_source));
	%
	
	% find source position at the time of recording
	source.xE = sPos.xE(source_pos_idx);
	source.yN = sPos.yN(source_pos_idx);
	source.zU = 0;
	%
end

%========================================================================%

function plot_source_on_cable(time_and_date)
% PLOT_SOURCE_ON_CABLE Creates a 2D and 3D visualization of the source on 
% the FO cable at the time of recording

	% get source position at time of recording
	source = get_source_on_cable(time_and_date);

	% plot 2D
	plot_cable_geometry_2D();
	set(gcf, 'Name', 'Source and FO cable (2D)');
	
	hold on
	plot(source.xE, source.yN, 'go', 'MarkerSize', 6, 'MarkerFaceColor', 'g');
	ylim([-50 2300]);
	title('Cable Geometry and Source position (2D)')
	subtitle(time_and_date);
	legend('Cable', 'Source');
	hold off
	%

	% plot 3D
	plot_cable_geometry_3D();
	set(gcf, 'Name', 'Source and FO cable (3D)');

	hold on
	plot3(source.xE, source.yN, source.zU, 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 6);
	title('Cable Geometry and Source position (3D)')
	subtitle(time_and_date);
	legend('Cable', 'Source');
	hold off
	%

end

%========================================================================%

function plot_source_channel_on_cable(time_and_date, target_channel_m)
% PLOT_SOURCE_CHANNEL_ON_CABLE Creates a 2D and 3D visualization of a channel  
% and the source on the FO cable at the time of recording
	
	% get source position at time of recording
	source = get_source_on_cable(time_and_date);

	% get channel position on FO cable
    channel = get_channel_on_cable(target_channel_m);

	% plot 2D
	plot_cable_geometry_2D();
	set(gcf, 'Name', 'Source, Channel and FO cable (2D)');
	
	hold on
	plot(channel.x, channel.y, 'ro', 'MarkerSize', 6, 'MarkerFaceColor', 'r');
	plot(source.xE, source.yN, 'go', 'MarkerSize', 6, 'MarkerFaceColor', 'g');
	ylim([-50 2300]);
	title('Cable Geometry, Source and Channel position (2D)')
	subtitle([time_and_date, ' | Channel at meter: ', num2str(target_channel_m)]);
	legend('Cable', 'Channel', 'Source');
	hold off
	%

	% plot 3D
	plot_cable_geometry_3D();
	set(gcf, 'Name', 'Source, Channel and FO cable (3D)');

	hold on
	plot3(channel.x, channel.y, channel.z, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
	plot3(source.xE, source.yN, source.zU, 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 6);
	title('Cable Geometry, Source and Channel position (3D)')
	subtitle([time_and_date, ' | Channel at meter: ', num2str(target_channel_m)]);
	legend('Cable', 'Channel', 'Source'); 
	xlim([-50 450]); ylim([-200 100]); zlim([-150 0]);
	hold off
	%

end

%========================================================================%