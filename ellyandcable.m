function EllyCable = ellyandcable()

	EllyCable.cable_geometry		= @cable_geometry;
	EllyCable.run1					= @run1;
	EllyCable.run2					= @run2;
	EllyCable.run3					= @run3;
	EllyCable.plot_run1				= @plot_run1;
	EllyCable.plot_run2				= @plot_run2;
	EllyCable.plot_run3				= @plot_run3;
	EllyCable.get_distance			= @get_distance;
	EllyCable.source_pos			= @source_pos;
end

%% CABLE GEOMETRY
function cable_geo = cable_geometry()
	% load data file first run (cable geometry is the same for all runs)
	load("ellyandcable_run1.mat", "cable");
	
	% ECEF coordinates system uses a shperical model
	Earth = referenceSphere('Earth'); 
	
	% get geodetic coordinates for the cable
	[cable_geo.lat, cable_geo.lon, cable_geo.alt] = ecef2geodetic(Earth, cable(3, :), cable(1, :), cable(2, :));
	% origin (reference point for cartesian coordinate system)
	cable_geo.lat0 = cable_geo.lat(1);
	cable_geo.lon0 = cable_geo.lon(1);
	cable_geo.alt0 = 0;
	% transforms geodetic coordinates (lat, lon, alt) of the cable to the local east-north-up (ENU) Cartesian coordinates
	[cable_geo.xE, cable_geo.yN, cable_geo.zU] = geodetic2enu(cable_geo.lat, cable_geo.lon, cable_geo.alt, ...
		cable_geo.lat0, cable_geo.lon0, cable_geo.alt0, wgs84Ellipsoid);
end
%========================================================================%

%% FIRST RUN
function elly1 = run1()
	% load data file first run (cable geometry is the same for all runs)
	run1 = load("ellyandcable_run1.mat", "elly");
	
	% get geodetic coordinates for Elly (source)
	[elly1.lat, elly1.lon, elly1.alt] = ecef2geodetic(Earth, run1.elly(3, :), run1.elly(1, :), run1.elly(2, :));
	% transforms geodetic coordinates (lat, lon, alt) of Elly to the local east-north-up (ENU) Cartesian coordinates
	[elly1.xE, elly1.yN, elly1.zU] = geodetic2enu(elly1.lat, elly1.lon, elly1.alt, cable.lat0, cable.lon0, cable.alt0, wgs84Ellipsoid);
end
%========================================================================%

function plot_run1()
	% load data file first run (cable geometry is the same for all runs)
	run1 = load("ellyandcable_run1.mat");

	% get cable geometry
	cable = cable_geometry();
	
	% plot 3D geometry of the FO cable
	figure(Name="Cable and Source (first run)", NumberTitle="off");
	plot3(cable.xE, cable.yN, cable.zU, 'b.-', 'LineWidth', 1.5); 
	grid on; axis equal; view(3);
	xlabel('East (m)'); ylabel('North (m)'); zlabel('Altitude (m)');
	title('Cable geometry and Elly position (first run)', 'FontSize', 12);
	hold on;
	
	% get geodetic coordinates for Elly (source)
	[elly1.lat, elly1.lon, elly1.alt] = ecef2geodetic(Earth, run1.elly(3, :), run1.elly(1, :), run1.elly(2, :));
	% transforms geodetic coordinates (lat, lon, alt) of Elly to the local east-north-up (ENU) Cartesian coordinates
	[elly1.xE, elly1.yN, elly1.zU] = geodetic2enu(elly1.lat, elly1.lon, elly1.alt, cable.lat0, cable.lon0, cable.alt0, wgs84Ellipsoid);
	% plot 3D geometry of the source
	plot3(elly1.xE, elly1.yN, elly1.zU, '-o', 'Color', 'r', 'MarkerSize', 3);
	view(3);
	
	% add colormap for time progression
	colormap("jet");
	scatter3(elly1.xE, elly1.yN, elly1.zU, 50, run1.t, 'filled');
	cb = colorbar;
	cb.Label.String = 'Time (s)';
	clim([min(run1.t) max(run1.t)]);
	xlim([-50 450]); ylim([-200 300]); zlim([-150 0]);
	hold off;
end
%========================================================================%

%% SECOND RUN
function elly2 = run2()
	% load data file second run
	run2 = load("ellyandcable_run2.mat", "elly");

	% get geodetic coordinates for Elly (source)
	[elly2.lat, elly2.lon, elly2.alt] = ecef2geodetic(Earth, run2.elly(3, :), run2.elly(1, :), run2.elly(2, :));
	% transforms geodetic coordinates (lat, lon, alt) of Elly to the local east-north-up (ENU) Cartesian coordinates
	[elly2.xE, elly2.yN, elly2.zU] = geodetic2enu(elly2.lat, elly2.lon, elly2.alt, cable.lat0, cable.lon0, cable.alt0, wgs84Ellipsoid);
end
%========================================================================%

function plot_run2()
	% load data file second run
	run2 = load("ellyandcable_run2.mat");
	
	% plot 3D geometry of the FO cable
	figure(Name="Cable and Source (second run)", NumberTitle="off");
	plot3(cable.xE, cable.yN, cable.zU, 'b.-', 'LineWidth', 1.5); 
	grid on; axis equal; view(3);
	xlabel('East (m)'); ylabel('North (m)'); zlabel('Altitude (m)');
	title('Cable geometry and Elly position (second run)', 'FontSize', 12);
	hold on;
	
	% get geodetic coordinates for Elly (source)
	[elly2.lat, elly2.lon, elly2.alt] = ecef2geodetic(Earth, run2.elly(3, :), run2.elly(1, :), run2.elly(2, :));
	% transforms geodetic coordinates (lat, lon, alt) of Elly to the local east-north-up (ENU) Cartesian coordinates
	[elly2.xE, elly2.yN, elly2.zU] = geodetic2enu(elly2.lat, elly2.lon, elly2.alt, cable.lat0, cable.lon0, cable.alt0, wgs84Ellipsoid);
	% plot 3D geometry of the source
	plot3(elly2.xE, elly2.yN, elly2.zU, '-o', 'Color', 'r', 'MarkerSize', 3);
	view(3);
	
	% add colormap for time progression
	colormap("jet");
	scatter3(elly2.xE, elly2.yN, elly2.zU, 50, run2.t, 'filled');
	cb = colorbar;
	cb.Label.String = 'Time (s)';
	clim([min(run2.t) max(run2.t)]);
	xlim([-50 450]); ylim([-200 300]); zlim([-150 0]);
	hold off;
end
%========================================================================%

%% THIRD RUN
function elly3 = run3()
	% load data file third run
	run3 = load("ellyandcable_run3.mat", "elly");
	
	% get geodetic coordinates for Elly (source)
	[elly3.lat, elly3.lon, elly3.alt] = ecef2geodetic(Earth, run3.elly(3, :), run3.elly(1, :), run3.elly(2, :));
	% transforms geodetic coordinates (lat, lon, alt) of Elly to the local east-north-up (ENU) Cartesian coordinates
	[elly3.xE, elly3.yN, elly3.zU] = geodetic2enu(elly3.lat, elly3.lon, elly3.alt, cable.lat0, cable.lon0, cable.alt0, wgs84Ellipsoid);
end
%========================================================================%

function plot_run3()
	% load data file third run
	run3 = load("ellyandcable_run3.mat");
	
	% plot 3D geometry of the FO cable
	figure(Name="Cable and Source (third run)", NumberTitle="off");
	plot3(cable.xE, cable.yN, cable.zU, 'b.-', 'LineWidth', 1.5); 
	grid on; axis equal; view(3);
	xlabel('East (m)'); ylabel('North (m)'); zlabel('Altitude (m)');
	title('Cable geometry and Elly position (third run)', 'FontSize', 12);
	hold on;
	
	% get geodetic coordinates for Elly (source)
	[elly3.lat, elly3.lon, elly3.alt] = ecef2geodetic(Earth, run3.elly(3, :), run3.elly(1, :), run3.elly(2, :));
	% transforms geodetic coordinates (lat, lon, alt) of Elly to the local east-north-up (ENU) Cartesian coordinates
	[elly3.xE, elly3.yN, elly3.zU] = geodetic2enu(elly3.lat, elly3.lon, elly3.alt, cable.lat0, cable.lon0, cable.alt0, wgs84Ellipsoid);
	% plot 3D geometry of the source
	plot3(elly3.xE, elly3.yN, elly3.zU, '-o', 'Color', 'r', 'MarkerSize', 3);
	view(3);
	
	% add colormap for time progression
	colormap("jet");
	scatter3(elly3.xE, elly3.yN, elly3.zU, 50, run3.t, 'filled');
	cb = colorbar;
	cb.Label.String = 'Time (s)';
	clim([min(run3.t) max(run3.t)]);
	xlim([-50 450]); ylim([-200 300]); zlim([-150 0]);
	hold off;
end
%========================================================================%

%% DISTANCE INFO (CHANNEL-ELLY)
function d = get_distance(channel_idx, time_and_date)

	% set up time axis and format
	load("ellyandcable_run1.mat", "t");
	time = seconds(t + 36); % time starts form -36?
	fmt = 'hh:mm:ss.SSS';

	% RUN1: 128 transmissions, each of 22.5 s
	t_start_run1 = duration('10:59:19.0', 'InputFormat', fmt,'Format', fmt);
	time_run1 = t_start_run1 + time;
	t_end_run1 = time_run1(end);
	
	% RUN2: 128 transmissions, each of 22.5 s
	t_start_run2 = duration('12:12:23.0', 'InputFormat', fmt,'Format', fmt);
	time_run2 = t_start_run2 + time;
	t_end_run2 = time_run2(end);
	
	% RUN3: 99 transmissions, each of 22.5 s
	t_start_run3 = duration('13:09:50.0', 'InputFormat', fmt,'Format', fmt);
	time_run3 = t_start_run3 + time(1:99);
	t_end_run3 = time_run3(end);

	% convert timestamp to duration
	datetime_source = datetime(time_and_date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
	source_time = timeofday(datetime_source);

	% check timestamp
	if source_time >= t_start_run1 && source_time <= t_end_run1 % RUN1
		% load distance matrix
		load("ellyandcable_run1.mat", "dist");

		% validity check on channel index
		if channel_idx < 1 || channel_idx > size(dist, 1)
        	error('Channel index out of range. It must be a value between 1 and %d', size(dist, 1));
		end

		% get distance from distance matrix
		d = dist(channel_idx, time_idx);
		
	elseif source_time >= t_start_run2 && source_time <= t_end_run2 % RUN2
		% load distance matrix
		load("ellyandcable_run2.mat", "dist");

		% validity check on channel index
		if channel_idx < 1 || channel_idx > size(dist, 1)
        	error('Channel index out of range. It must be a value between 1 and %d', size(dist, 1));
		end

		% get distance from distance matrix
		d = dist(channel_idx, time_idx);
		
	elseif source_time >= t_start_run3 && source_time <= t_end_run3 % RUN3
		% load distance matrix
		load("ellyandcable_run3.mat", "dist");

		% validity check on channel index
		if channel_idx < 1 || channel_idx > size(dist, 1)
        	error('Channel index out of range. It must be a value between 1 and %d', size(dist, 1));
		end

		% get distance from distance matrix
		d = dist(channel_idx, time_idx);
		
	else
		error('Time out of range');
	end
end
%========================================================================%

%% FIND SOURCE POSITION FROM TIME
function source_pos(time_and_date)

	% get cable geometry
	cable = cable_geometry();

	% set up time axis and format
	load("ellyandcable_run1.mat", "t");
	time = seconds(t + 36); % time starts form -36?
	fmt = 'hh:mm:ss.SSS';

	% RUN1: 128 transmissions, each of 22.5 s
	t_start_run1 = duration('10:59:19.0', 'InputFormat', fmt,'Format', fmt);
	time_run1 = t_start_run1 + time;
	t_end_run1 = time_run1(end);
	
	% RUN2: 128 transmissions, each of 22.5 s
	t_start_run2 = duration('12:12:23.0', 'InputFormat', fmt,'Format', fmt);
	time_run2 = t_start_run2 + time;
	t_end_run2 = time_run2(end);
	
	% RUN3: 99 transmissions, each of 22.5 s
	t_start_run3 = duration('13:09:50.0', 'InputFormat', fmt,'Format', fmt);
	time_run3 = t_start_run3 + time(1:99);
	t_end_run3 = time_run3(end);

	% convert timestamp to duration
	datetime_source = datetime(time_and_date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
	source_time = timeofday(datetime_source);

	% check timestamp
	if source_time >= t_start_run1 && source_time <= t_end_run1 % RUN1
		% find time index on time axis closest to source time
		[~, source_pos_idx] = min(abs(time_run1 - source_time));
		% get elly position
		elly1 = run1();
		source_xE = elly1.xE(source_pos_idx);
		source_yN = elly1.yN(source_pos_idx);
		source_zU = 0;
		
	elseif source_time >= t_start_run2 && source_time <= t_end_run2 % RUN2
		% find time index on time axis closest to source time
		[~, source_pos_idx] = min(abs(time_run2 - source_time));
		% get elly position
		elly2 = run2();
		source_xE = elly2.xE(source_pos_idx);
		source_yN = elly2.yN(source_pos_idx);
		source_zU = 0;
		
	elseif source_time >= t_start_run3 && source_time <= t_end_run3 % RUN3
		% find time index on time axis closest to source time
		[~, source_pos_idx] = min(abs(time_run3 - source_time));
		% get elly position
		elly3 = run1();
		source_xE = elly3.xE(source_pos_idx);
		source_yN = elly3.yN(source_pos_idx);
		source_zU = 0;
		
	else
		error('Time out of range');
	end
	
	% plot cable geometry
	figure(Name="Cable and Source (second run)", NumberTitle="off");
	plot3(cable.xE, cable.yN, cable.zU, 'b.-', 'LineWidth', 1.5); 
	xlim([-50 450]); ylim([-200 100]); zlim([-150 0]);
	grid on; axis equal; view(3);
	xlabel('East (m)'); ylabel('North (m)'); zlabel('Altitude (m)');
	title('Cable geometry and Elly position (second run)', 'FontSize', 12);
	hold on;
	
	% plot source position
	plot3(source_xE, source_yN, source_zU, 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 6);
	subtitle(time_string);
	legend('Cable', 'Source');
	hold off
end
%========================================================================%