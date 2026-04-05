%% CLEAR VARIABLES
clc
clear all
close all
clearAllMemoizedCaches

%% LOAD DATA FROM DATASET
% add directories to Matlab search path
addpath('Dataset', 'Dataset_Norway', 'Filters', 'Plots', 'SetupAndConfiguration');

dataset_name	= 'DAS4Whale';
DAS				= feval(str2func(dataset_name + "_cfg"));
data			= DAS.load_data("20200627_052441_ch10001_to_ch15000_whale_raw_L160s.mat");
% -----------------------------------------------------------------------%

%% BUTTERWORTH BANDPASS FILTER
% parameters
bp = DAS.bandpass();

% apply filter
strain_filtered = butterworth_bp_filter( ...
	data.strain, ...
	bp.cutoff_freq, ...
	bp.order, ...
	data.sampling_frequency_Hz);

% clear variables
clear bp
% -----------------------------------------------------------------------%

%% FK FILTERING
% parameters
fkFilt = DAS.fkFilt();

% design fk filter
fk_filter =	fk_filter_design( ...
	data.dimensions, ...
	data.channel_distance_m, ...
	data.sampling_interval_s);

% apply fk filter
strain_filtered = fk_filter_filt( ...
	strain_filtered, ...
	fk_filter);

% clear variables
clear fkFilt fk_filter
% -----------------------------------------------------------------------%

%% CROSS-CORRELATION STATISTICS - EXPERIMENTAL

% parameterss
channel_position = 42000; % reference channel position [m]
offset = 300; % maximum spatial offset from reference channel [m]
max_time_lag = 0.2; % time limits for correlation analysis [s]
time_interval = [47 50]; % time interval of signal [s]
cpa = 42800; % CPA position [m]

% plot correlogram
correlogram = get_correlogram( ...
	strain_filtered, ...
	data.sampling_frequency_Hz, ...
	data.distance_m, ...
    channel_position, ...
	offset, ...
	max_time_lag, ...
	time_interval, ...
	'subtitle', data.time_and_date, ...
	'resample_factor', 10);

export_plot = false;

if export_plot
	% export plot as png
    exportgraphics(correlogram, ...
    ['Correlogram_Analysis/exp_correlogram_' ...
    num2str(time_interval(1)) '_' ...
    num2str(time_interval(2)) '_' ...
    'ref_' num2str(channel_position) ...
    '.png']);
end

% plot correlation statistics and export data to csv file
[correlation_statistics, xcorr_plot] = get_correlation_statistics( ...
	strain_filtered, ...
	data.sampling_frequency_Hz, ...
	data.distance_m, ...
	data.channel_distance_m, ...
	channel_position, ...
	offset, ...
	max_time_lag, ...
	time_interval, ...
	"Correlogram_Analysis/exp_correlation_statistics.csv", ...
	'subtitle', data.time_and_date, ...
	'offset_step', 2, ...
	'resample_factor', 10);

%% ESTIMATE R - EXPERIMENTAL

distance_from_CPA = (cpa - channel_position); % distance btw reference channel and CPA
channel_dist_12 = correlation_statistics(:, 1); % distance btw reference channel and another within the max offset [m]
time_peak = correlation_statistics(:, 3); % peak time of cross correlations
c = data.propagation_speed;

d12 = channel_dist_12;
pc = time_peak.*c;
d0 = distance_from_CPA;

% A = (pc.^2 + 2.*d0.*d12 - d12.^2) ./ (2 .* pc);
% R = sqrt(A.^2 - d0^2);

R_estimate = sqrt(((d0^2 + (time_peak.^2).*c^2 - (d0 - d12).^2) ...
	./ (2.*time_peak.*c)).^2 - d0^2);
R_estimate(imag(R_estimate) ~= 0) = NaN;
R_med = median(R_estimate, 'omitnan');

figure('Name', "SourceDistance", 'NumberTitle','off');
plot(d12, R_estimate, '-*');
title("Source distance (estimate)");
subtitle(['Median value of R: ' num2str(R_med)]);
xlabel("Distance between channels");
ylabel("Distance (m)");

% linear regression
valid_idx = ~isnan(R_estimate) & (d12 ~= 0); % remove problematic points
valid_channel_dist_12 = d12(valid_idx); % get valid elements
R_valid = R_estimate(valid_idx); % get valid elements

beta = robustfit(valid_channel_dist_12, R_valid); 
R_LR = beta(1) + beta(2) * valid_channel_dist_12;

hold on 
plot(valid_channel_dist_12, R_LR, 'Color', "r");
legend("R estimate", "Linear regression");
hold off

exportgraphics(gcf, ...
    ['Correlogram_Analysis/exp_estimateR_' ...
    num2str(time_interval(1)) '_' ...
    num2str(time_interval(2)) '_' ...
    'ref_' num2str(channel_position) ...
    '.png']);

figure(correlogram);
dt = -0.2:data.sampling_interval_s:0.2;

d1 = sqrt( ( sqrt(R_med^2 + distance_from_CPA^2) - dt*c ).^2 - R_med^2 );

if distance_from_CPA < 0
	dx = distance_from_CPA + d1;
else
	dx = distance_from_CPA - d1;
end

hold on
plot(dt, dx, 'k--', 'LineWidth', 1)
hold off

fprintf('Median value of R: %d [m]\n', R_med);

%% CROSS-CORRELATION STATISTICS - SYNTHETIC

% Parametri dell'analisi
sampling_period     = 1/6450; % periodo di campionamento [s]
time_axis           = 0:sampling_period:0.4;
time_axis           = [-1*flip(time_axis(2:end)) time_axis]; % asse temporale simmetrico tra -0.4s e 0.4s
% ----------------------------------------------------------------------- %


% Parametri chirp
B                   = 30; % larghezza di banda [Hz]
f0                  = 44; % frequenza centrale [Hz]
T                   = 1.3; % durata impulso [s]
chirp_t_axis        = 0:sampling_period:T; % asse temporale dell'impulso
chirp_rate          = B/T; % rate di variazione della frequenza (chirp rate) [Hz/s]

chirp_signal        = sin(2*pi*(f0 - chirp_rate * (chirp_t_axis - T) / 2) .* chirp_t_axis) .* triang(length(chirp_t_axis))';
% chirp lineare discendente
% frequenza che parte da f0+B/2 (t=0) e scende fino a f0-B/2 (t=T)
% viene applicata una finestra triangolare

% chirp_signal_w_noise = awgn(chirp_signal, 3);

chirp_signal_norm   = chirp_signal / sqrt(sum(chirp_signal .^ 2) * sampling_period); % normalizzazione energetica
% ----------------------------------------------------------------------- %


% Auto-Correlazione
auto_correlation    = xcorr(chirp_signal_norm, chirp_signal_norm, (length(time_axis) - 1) / 2);
auto_corr_samples   = length(auto_correlation);
% ----------------------------------------------------------------------- %


% Parametri ambientali
bottom_depth            = 260; % profondità fondale [m]
target_depth            = 20; % profondità target [m]
target_height           = bottom_depth - target_depth; % altezza del target rispetto al fondale [m]

sediment_first_layer    = 55; % profonditò primo layer di sedimenti [m]
K_reflection_bottom     = 0.85; % coefficiente di riflessione sullo strato di roccia

c                       = 1480; % velocità di propagazione del suono in acqua [m/s]

% R                       = 405; % distanza del target dal fondale [m]
R                       = 420;
CPA_pos                 = 42800;
ref_pos                 = 42000;
distance_ref_CPA        = CPA_pos - ref_pos; % distanza tra canale di riferimento e CPA [m]

% ------------------- Parametri canale di riferimento ------------------- %
R0                  = sqrt(R^2+distance_ref_CPA^2); % distanza tra target e canale di riferimento [m]

Delta0              = (sqrt(R0^2 + 4*bottom_depth*target_depth)-R0)/c; 
% ritardo temporale con cui il segnale riflesso dalla superficie raggiunge il canale di riferimento [s]

Gamma0              = (sqrt(R0^2 + 4*target_height*sediment_first_layer + 4*sediment_first_layer^2)-R0)/c;
% ritardo temporale con cui il segnale riflesso dallo strato roccioso raggiunge il canale di riferimento [s]

% coefficienti (ampiezza) dei segnali che arrivano al canale di riferimento
alfa_0              = 1; % coefficiente segnale diretto
beta_0              = R0/sqrt(R0^2 + 4*bottom_depth*target_depth); % coeff segnale riflesso dalla superficie
gamma_0             = R0/sqrt(R0^2 + 4*target_height*sediment_first_layer + 4*sediment_first_layer^2); % coeff riflesso dallo strato roccioso
% ----------------------------------------------------------------------- %

% ----------------------- Parametri altri canali ------------------------ %
channel_idx         = -74:74; % indici dei canali (74*4.08 = 302.29)
channel_distance    = 4.085; % distanza tra canali adiacenti [m]
gauge_length        = 8.17;
distance_k_CPA      = distance_ref_CPA - channel_idx * channel_distance; % distanza canale k-esimo dal CPA [m]
num_of_channels     = length(channel_idx); % numero di canali
offset_ref          = channel_distance .* channel_idx;

Rk                  = sqrt(R^2 + distance_k_CPA.^2); % distanza canale k-esimo dal target [m]

tk                  = (R0-Rk)/c; % ritardo temporale con cui il segnale arriva al canale k-esimo rispetto al canale di riferimento [s]
Rk_surf_refl        = sqrt(Rk.^2 + 4*bottom_depth*target_depth); % lunghezza del percorso target-superficie-canaleDAS [m]
Rk_bottom_refl      = sqrt(Rk.^2 + 4*target_height*sediment_first_layer + 4*sediment_first_layer^2);  % lunghezza del percorso target-roccia-canaleDAS

Deltak              = (Rk_surf_refl - Rk)/c;
% ritardo temporale con cui il segnale riflesso dalla superficie raggiunge il canale k-esimo [s]

Gammak              = (Rk_bottom_refl - Rk)/c;
% ritardo temporale con cui il segnale riflesso dallo strato roccioso raggiunge il canale k-esimo [s]

% coefficienti (ampiezza) dei segnali che arrivano al canale di riferimento
alfa_k              = R0 ./ Rk; % coefficiente segnale diretto
beta_k              = R0 ./ Rk_surf_refl; % coeff segnale riflesso dalla superficie
gamma_k             = R0 ./ Rk_bottom_refl; % coeff segnale riflesso dallo strato roccioso
% ----------------------------------------------------------------------- %


% Correlogramma
Correlogramma = zeros(num_of_channels, auto_corr_samples);

for n = 1:num_of_channels
    fA = ritardafunz(auto_correlation, sampling_period, tk(n));
    fB = ritardafunz(auto_correlation, sampling_period, tk(n) + Delta0 - Deltak(n));
    fC = ritardafunz(auto_correlation, sampling_period, tk(n) - Deltak(n));
    fD = ritardafunz(auto_correlation, sampling_period, tk(n) + Delta0);
    fE = ritardafunz(auto_correlation, sampling_period, tk(n) + Gamma0 - Gammak(n));
    fF = ritardafunz(auto_correlation, sampling_period, tk(n) - Gammak(n));
    fG = ritardafunz(auto_correlation, sampling_period, tk(n) + Delta0 - Gammak(n));
    fH = ritardafunz(auto_correlation, sampling_period, tk(n) + Gamma0);
    fI = ritardafunz(auto_correlation, sampling_period, tk(n) + Gamma0 - Deltak(n));

    Correlogramma(n,:) = ...
    alfa_0 * alfa_k(n) * fA ...
    + beta_0 * beta_k(n) * fB ...
    - alfa_0 * beta_k(n) * fC ...
    - alfa_k(n) * beta_0 * fD ...
    + K_reflection_bottom^2 * gamma_0 *gamma_k(n) * fE ...
    + K_reflection_bottom * alfa_0 * gamma_k(n) * fF ...
    - K_reflection_bottom * beta_0 * gamma_k(n) * fG ...
    + K_reflection_bottom * gamma_0 * alfa_k(n) * fH ...
    - K_reflection_bottom * gamma_0 * beta_k(n) * fI;
end
% ----------------------------------------------------------------------- %


% Plot
correlogram_synthetic = figure(Name="Synthetic Correlogram", NumberTitle="off");
imagesc(time_axis, distance_ref_CPA - distance_k_CPA, Correlogramma)
xlim([-0.2 0.2])
ylim([-300 300])
currax = gca;
currax.YDir = "normal";
colormap(redblue);
colormap;

exportgraphics(gcf, ...
    ['Correlogram_Analysis/syn_correlogram_' ...
    num2str(time_interval(1)) '_' ...
    num2str(time_interval(2)) '_' ...
    'ref_' num2str(channel_position) ...
    '.png']);

% ----------------------------------------------------------------------- %

%% ESTIMATE R - SYNTHETIC
channel_dist_12_syn = offset_ref; % distance btw reference channel and another within the max offset [m]
time_peak_syn = tk'; % peak time of cross correlations

CPA_pos                 = 42800;
ref_pos                 = 42000;
distance_ref_CPA        = CPA_pos - ref_pos;

d12_syn = channel_dist_12_syn';
pc_syn = time_peak_syn.*c;
d0_syn = distance_ref_CPA;

% A = (pc.^2 + 2.*d0.*d12 - d12.^2) ./ (2 .* pc);
% R = sqrt(A.^2 - d0^2);

R_estimate_syn = sqrt(((d0_syn^2 + (time_peak_syn.^2).*c^2 - (d0_syn - d12_syn).^2) ...
	./ (2.*time_peak_syn.*c)).^2 - d0_syn^2);
R_estimate_syn(imag(R_estimate_syn) ~= 0) = NaN;
R_med_syn = median(R_estimate_syn, 'omitnan');

figure('Name', "SourceDistance", 'NumberTitle','off');
plot(d12_syn, R_estimate_syn, '-*');
title("Source distance (estimate)");
subtitle(['Median value of R: ' num2str(R_med_syn)]);
xlabel("Distance between channels");
ylabel("Distance (m)");

% linear regression
valid_idx_syn = ~isnan(R_estimate_syn) & (d12_syn ~= 0); % remove problematic points
valid_channel_dist_12_syn = d12_syn(valid_idx_syn); % get valid elements
R_valid_syn = R_estimate_syn(valid_idx_syn); % get valid elements

beta_syn = robustfit(valid_channel_dist_12_syn, R_valid_syn); 
R_LR_syn = beta_syn(1) + beta_syn(2) * valid_channel_dist_12_syn;

hold on 
plot(valid_channel_dist_12_syn, R_LR_syn, 'Color', "r");
legend("R estimate", "Linear regression");
hold off

exportgraphics(gcf, ...
    ['Correlogram_Analysis/syn_estimateR_' ...
    num2str(time_interval(1)) '_' ...
    num2str(time_interval(2)) '_' ...
    'ref_' num2str(channel_position) ...
    '.png']);

figure(correlogram_synthetic);
dt_syn = -0.2:sampling_period:0.2;

d1_syn = sqrt( ( sqrt(R_med_syn^2 + distance_ref_CPA^2) - dt_syn*c ).^2 - R_med_syn^2 );

if distance_ref_CPA < 0
	dx_syn = distance_ref_CPA + d1_syn;
else
	dx_syn = distance_ref_CPA - d1_syn;
end

hold on
plot(dt_syn, dx_syn, 'k--', 'LineWidth', 1)
hold off

fprintf('Median value of R: %d [m]\n', R_med_syn);





%% helper functions
function FR = ritardafunz(F,tcamp,ritardo)
    if ritardo >= 0
        ncamp = round(ritardo/tcamp);
        FR = [zeros(1,ncamp) F(1:end-ncamp)];
    else
        ncamp = round(-ritardo/tcamp);
        FR = [F(1+ncamp:end) zeros(1,ncamp)];
    end
end

function cmap = redblue(m)
    % Red Blue Colormap
    if nargin < 1
        m = size(get(gcf,'colormap'), 1);
    end
    
    if m == 1
        cmap = [1 1 1];
        return;
    end
    
    n_half = ceil(m/2);
    r_lower = linspace(0, 1, n_half)';
    g_lower = linspace(0, 1, n_half)';
    b_lower = ones(n_half, 1);
    
    n_upper = m - n_half;
    r_upper = ones(n_upper, 1);
    g_upper = linspace(1, 0, n_upper)';
    b_upper = linspace(1, 0, n_upper)';
    
    cmap = [r_lower, g_lower, b_lower; r_upper, g_upper, b_upper];
    
    cmap = cmap(1:m, :);
end
