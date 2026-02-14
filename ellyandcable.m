%% FIRST RUN

% load data file (first run)
load("ellyandcable_run1.mat");

Earth = referenceSphere('Earth'); % ECEF coordinates system uses a shperical model

% get geodetic coordinates for the cable
[lat_cable, lon_cable, alt_cable] = ecef2geodetic(Earth, cable(3, :), cable(1, :), cable(2, :));
% origin (reference point for cartesian coordinate system)
lat0 = lat_cable(1);
lon0 = lon_cable(1);
alt0 = 0;
% transforms geodetic coordinates (lat, lon, alt) of the cable to the local east-north-up (ENU) Cartesian coordinates
[xE_cable, yN_cable, zU_cable] = geodetic2enu(lat_cable, lon_cable, alt_cable, lat0, lon0, alt0, wgs84Ellipsoid);
% plot 3D geometry of the FO cable
figure(Name="Cable and Source (first run)", NumberTitle="off");
plot3(xE_cable, yN_cable, zU_cable, 'b.-', 'LineWidth', 1.5); 
grid on; axis equal; view(3);
xlabel('East (m)'); ylabel('North (m)'); zlabel('Altitude (m)');
hold on;

% get geodetic coordinates for Elly (source)
[lat_elly, lon_elly, alt_elly] = ecef2geodetic(Earth, elly(3, :), elly(1, :), elly(2, :));
% transforms geodetic coordinates (lat, lon, alt) of Elly to the local east-north-up (ENU) Cartesian coordinates
[xE_elly, yN_elly, zU_elly] = geodetic2enu(lat_elly, lon_elly, alt_elly, lat0, lon0, alt0, wgs84Ellipsoid);
% plot 3D geometry of the source
plot3(xE_elly, yN_elly, zU_elly, '-o', 'Color', 'r', 'MarkerSize', 3);
view(3);

% add colormap for time progression
colormap("jet");
scatter3(xE_elly, yN_elly, zU_elly, 50, t, 'filled');
cb = colorbar;
cb.Label.String = 'Time (s)';
clim([min(t) max(t)]);
xlim([-50 450]); ylim([-200 100]); zlim([-150 0]);
hold off;

% print distance info
fprintf("\n --- FIRST RUN --- \n");
fprintf('\nDistance info:\n');
[dist_min, idx_min] = min(dist(:));
[channel_min, sample_min] = ind2sub(size(dist), idx_min);
fprintf('  -Minimum distance: %.2f\n', dist_min);
fprintf('     Channel: %d, Sample: %d (t = %.1f)\n', channel_min, sample_min, t(sample_min));
[dist_max, idx_max] = max(dist(:));
[channel_max, sample_max] = ind2sub(size(dist), idx_max);
fprintf('  -Maximum distance: %.2f m\n', dist_max);
fprintf('     Channel: %d, Sample: %d (t = %.1f)\n', channel_max, sample_max, t(sample_max));