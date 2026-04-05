%% CLEAR VARIABLES
clc
clear all
close all
clearAllMemoizedCaches

%% LOAD DATA FROM DATASET
% add directories to Matlab search path
addpath('Dataset', 'Dataset_Norway', 'Filters', 'Plots', 'SetupAndConfiguration');

dataset_name	    = 'DAS4Whale';
DAS				    = feval(str2func(dataset_name + "_cfg"));
data			    = DAS.load_data("20200627_052441_ch10001_to_ch15000_whale_raw_L160s.mat");
plot_fk_spectrum    = false;

% -----------------------------------------------------------------------%


%% BUTTERWORTH BANDPASS FILTER
% parameters
bp_order = 5;
bp_cutoff_frequency = [30 65];

% apply filter
strain_filtered = butterworth_bp_filter( ...
	data.strain, ...
	bp_cutoff_frequency, ...
	bp_order, ...
	data.sampling_frequency_Hz);

% clear variables
clear bp

% -----------------------------------------------------------------------%


%% FK FILTERING
% parameters
c_range = [1400 1450 2000 2050];

% design fk filter
fk_filter =	fk_filter_design( ...
	data.dimensions, ...
	data.channel_distance_m, ...
	data.sampling_interval_s, ...
    'c_range', c_range);

% apply fk filter
strain_filtered = fk_filter_filt( ...
	strain_filtered, ...
	fk_filter);

if plot_fk_spectrum
    fk_spectrum( ...
        data.strain, ...
        data.channel_distance_m, ...
        data.sampling_interval_s, ...
        'subtitle', [data.time_and_date, "no filters"], ...
        'dB_lim', [-120 0])
end

if plot_fk_spectrum
    fk_spectrum( ...
        strain_filtered, ...
        data.channel_distance_m, ...
        data.sampling_interval_s, ...
        'subtitle', [data.time_and_date, "bandpass + fk filter"], ...
        'dB_lim', [-120 0])
end

% clear variables
clear fk_filter

% -----------------------------------------------------------------------%


%% TIME-SPACE PLOT
% parameters
tx = DAS.tx_plot();

% time-space plot
time_space_plot = get_time_space_plot( ...
	strain_filtered, ...
	data.time, ...
	data.distance_m, ...
	'subtitle', data.time_and_date, ...
    'time_lim', tx.time_lim, ...
	'distance_lim', tx.distance_lim, ...
	'strain_lim', tx.strain_lim, ...
	'norm', true);

% export plot as png
exportgraphics(time_space_plot, ...
['Correlogram_tests/tx_plot_' ...
num2str(bp_cutoff_frequency(1)) '_' ...
num2str(bp_cutoff_frequency(2)) ...
'.png']);

% clear variables
clear tx

% -----------------------------------------------------------------------%


%% CROSS-CORRELATION STATISTICS
% parameters
time_interval = [47 50];
reference_channel_position = 44000;
CPA_position = 42800;
max_offset = 300;
max_time_lag = 0.2;

% plot correlogram
[correlogram, correlation_matrix,time_lags] = get_correlogram( ...
	strain_filtered, ...
	data.sampling_frequency_Hz, ...
	data.distance_m, ...
    reference_channel_position, ...
	max_offset, ...
	max_time_lag, ...
	time_interval, ...
	'subtitle', data.time_and_date, ...
	'resample_factor', 10);

% plot correlation statistics and export data to csv file
[correlation_statistics, xcorr_plot] = get_correlation_statistics( ...
	strain_filtered, ...
	data.sampling_frequency_Hz, ...
	data.distance_m, ...
	data.channel_distance_m, ...
	reference_channel_position, ...
	max_offset, ...
	max_time_lag, ...
	time_interval, ...
	"Correlogram_tests/cross_corr_stats.csv", ...
	'subtitle', data.time_and_date, ...
	'offset_step', 2, ...
	'resample_factor', 10);


% export plot as png
exportgraphics(correlogram, ...
['Correlogram_tests/correlogram_' ...
num2str(time_interval(1)) '_' ...
num2str(time_interval(2)) '_' ...
'ref_' num2str(reference_channel_position) ...
'_band_' ...
num2str(bp_cutoff_frequency(1)) '_' ...
num2str(bp_cutoff_frequency(2)) ...
'.png']);

% export plot as png
exportgraphics(xcorr_plot, ...
['Correlogram_tests/crosscorrelations_' ...
num2str(time_interval(1)) '_' ...
num2str(time_interval(2)) '_' ...
'ref_' num2str(reference_channel_position) ...
'_band_' ...
num2str(bp_cutoff_frequency(1)) '_' ...
num2str(bp_cutoff_frequency(2)) ...
'.png']);

% -----------------------------------------------------------------------%


%% estimate distance between CPA and source

% % reference channel selection
% [~, reference_channel_idx] = min(abs(data.distance_m - reference_channel_position)); 
% actual_channel_position = data.distance_m(reference_channel_idx);
% 
% % spatial subset selection
% distance_from_reference_channel = abs(data.distance_m - actual_channel_position);
% nearby_idx = find(distance_from_reference_channel <= max_offset); 
% nb_channels = length(nearby_idx);
% 
% distance_ref_CPA = (CPA_position - reference_channel_position); % distance btw reference channel and CPA
% distance_ref_k = distance_from_reference_channel(nearby_idx); % cross-correlation offset [m]
% c = data.propagation_speed;
% 
% % find time peaks
% time_peaks = zeros(nb_channels, 1);
% for i = 1:nb_channels
%     [peak_value, peak_idx] = max(correlation_matrix(i, :));
%     time_peaks(i) = time_lags(peak_idx); % store peak time for each channel
% end

distance_ref_CPA = (CPA_position - reference_channel_position); % distance btw reference channel and CPA
distance_ref_k = correlation_statistics(:, 1); % distance btw reference channel and another within the max offset [m]
time_peaks = correlation_statistics(:, 3); % peak time of cross correlations
c = data.propagation_speed;

d12 = distance_ref_k;
pc = time_peaks.*c;
d0 = distance_ref_CPA;

figure('Name', "TDOA * c", 'NumberTitle','off');
plot(d12, pc, '-*');
legend("TDOA * c");

R = sqrt(((d0^2 + (time_peaks.^2).*c^2 - (d0 - d12).^2) ...
	./ (2.*time_peaks.*c)).^2 - d0^2);
R(imag(R) ~= 0) = NaN;

R_med = median(R, 'omitnan');

figure('Name', "SourceDistance", 'NumberTitle','off');
plot(d12, R, '-*');
title("Source distance (estimate)");
subtitle(['Median value of R: ' num2str(R_med)]);
xlabel("Distance between channels");
ylabel("Distance (m)");

% linear regression
valid_idx = ~isnan(R) & (d12 ~= 0); % remove problematic points
valid_channel_dist_12 = d12(valid_idx); % get valid elements
R_valid = R(valid_idx); % get valid elements

beta = robustfit(valid_channel_dist_12, R_valid); 
R_LR = beta(1) + beta(2) * valid_channel_dist_12;

hold on 
plot(valid_channel_dist_12, R_LR, 'Color', "r");
legend("R estimate", "Linear regression");
hold off

exportgraphics(gcf, ...
    ['Correlogram_tests/estimateR_' ...
    num2str(time_interval(1)) '_' ...
    num2str(time_interval(2)) '_' ...
    'ref_' num2str(reference_channel_position) ...
    '_band_' ...
    num2str(bp_cutoff_frequency(1)) '_' ...
    num2str(bp_cutoff_frequency(2)) ...
    '.png']);

figure(correlogram);
dt = -0.2:data.sampling_interval_s:0.2;


d1 = sqrt( ( sqrt(R_med^2 + distance_ref_CPA^2) - dt*c ).^2 - R_med^2 );
if distance_ref_CPA < 0
	dx = distance_ref_CPA + d1;
else
	dx = distance_ref_CPA - d1;
end
hold on
plot(dt, dx, 'k--', 'LineWidth', 1)
hold off

% export plot as png
exportgraphics(correlogram, ...
['Correlogram_tests/correlogram_' ...
num2str(time_interval(1)) '_' ...
num2str(time_interval(2)) '_' ...
'ref_' num2str(reference_channel_position) ...
'_band_' ...
num2str(bp_cutoff_frequency(1)) '_' ...
num2str(bp_cutoff_frequency(2)) '_' ...
'with_R_line.png']);

fprintf('Median value of R: %d [m]\n', R_med);

% -----------------------------------------------------------------------%


%% Cross-correlation between two channels
% Define the channels for cross-correlation
CPA = 42800;
distance_ref_k = data.gauge_length_m;

channel1_position = 42000;
channel2_position = 42000 + distance_ref_k;

channel_dist_1CPA = abs(CPA-channel1_position);

c = data.propagation_speed; % [m/s]
max_lag = 300 / c;
time_interval = [47 50];

[peak_lag, cross_corr] = corss_correlation( ...
	strain_filtered, ...
	data.sampling_frequency_Hz, ...
	data.distance_m, ...
	data.channel_distance_m, ...
    channel1_position, ...
	channel2_position, ...
	max_lag, ...
	time_interval, ...
	'subtitle', data.time_and_date, ...
	'resample_factor', 1000);

R = sqrt(((channel_dist_1CPA^2 + (peak_lag.^2).*c^2 - (channel_dist_1CPA - distance_ref_k).^2) ...
		./ (2.*peak_lag.*c)).^2 - channel_dist_1CPA^2);

fprintf("\nR = %.2f\n", R);

% -----------------------------------------------------------------------%


%% estimate angle of arrival (AoA)
distance_ref_k = correlation_statistics(:, 1); % cross-correlation offset [m]
time_peak = correlation_statistics(:, 3); % peak time of cross correlations
c = data.propagation_speed;

% ratio between the distance traveled by the acoustic wave and the distance between the two channels
arg = (time_peak .* c) ./ distance_ref_k;

% clipping to avoid numeric instability (asin/acos take as argument [-1, 1])
arg(arg > 1) = 1;
arg(arg < -1) = -1;

% angle (radiants)
theta_rad = acos(arg);

% angle (degrees)
theta_deg = rad2deg(theta_rad);

% plot angle of arrival as a function of the distance between the two channels
figure('Name', "Angle of Arrival", 'NumberTitle','off');
plot(distance_ref_k, theta_deg, '-*');

% Linear regression
valid_idx = isfinite(theta_deg) & (distance_ref_k ~= 0); % remove problematic points
valid_channel_dist_12 = distance_ref_k(valid_idx); % get valid elements
theta_deg_valid = theta_deg(valid_idx); % get valid elements

% robustfit(x,y) returns a vector b of coefficient estimates for a robust 
% multiple linear regression of the responses in vector y on the predictors
% in matrix x; uses bisquare robust fitting weight function
beta = robustfit(valid_channel_dist_12, theta_deg_valid); 
theta_LR = beta(1) + beta(2) * valid_channel_dist_12;

% plot weighted linear regression result
hold on;
plot(valid_channel_dist_12, theta_LR);
legend("Angle of Arrival", "Linear regression");
title("Angle of Arrival (estimate)");
xlabel("Distance between channels");
ylabel("Angle (degrees)");
hold off

% -----------------------------------------------------------------------%