%% CABLE GEOMETRY
% load data file first run (cable geometry is the same for all
% runs)kmlat_cable
run1 = load("ellyandcable_run1.mat");

% ECEF coordinates system uses a shperical model
Earth = referenceSphere('Earth'); 

% get geodetic coordinates for the cable
[cable.lat, cable.lon, cable.alt] = ecef2geodetic(Earth, run1.cable(3, :), run1.cable(1, :), run1.cable(2, :));
% origin (reference point for cartesian coordinate system)
cable.lat0 = cable.lat(1);
cable.lon0 = cable.lon(1);
cable.alt0 = 0;
% transforms geodetic coordinates (lat, lon, alt) of the cable to the local east-north-up (ENU) Cartesian coordinates
[cable.xE, cable.yN, cable.zU] = geodetic2enu(cable.lat, cable.lon, cable.alt, cable.lat0, cable.lon0, cable.alt0, wgs84Ellipsoid);

% clear variables
clear run1
%========================================================================%

%% FIRST RUN
% load data file first run (cable geometry is the same for all runs)
run1 = load("ellyandcable_run1.mat");

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

% clear variables
clear run1 elly1 cb
%========================================================================%

%% SECOND RUN
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

% clear variables
clear run2 elly2 cb
%========================================================================%

%% THIRD RUN
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

% clear variables
clear run3 elly3 cb
%========================================================================%

%% DISTANCE INFO (CABLE-ELLY)
function d = get_distance(channel_idx, time_s, dist, t)
    % validity check on channel index
    if channel_idx < 1 || channel_idx > size(dist, 1)
        error('Channel index out of range. It must be a value between 1 and %d', size(dist, 1));
    end

    % find time index
    [~, time_idx] = min(abs(t - time_s));
    
    % validity check on time index
    if time_idx < 1 || time_idx > size(dist, 2)
        error('Time index out of range. It must be a value between 1 and %d', size(dist, 2));
    end
    
    % get distance from distance matrix
    d = dist(channel_idx, time_idx);
end