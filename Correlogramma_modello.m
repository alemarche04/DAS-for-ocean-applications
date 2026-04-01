%% Parametri dell'analisi
sampling_period     = 1/645; % periodo di campionamento [s]
time_axis           = 0:sampling_period:0.4;
time_axis           = [-1*flip(time_axis(2:end)) time_axis]; % asse temporale simmetrico tra -0.4s e 0.4s

%% Parametri chirp
B                   = 30; % larghezza di banda [Hz]
f0                  = 44; % frequenza centrale [Hz]
T                   = 1.67; % durata impulso [s]
chirp_t_axis        = 0:sampling_period:T; % asse temporale dell'impulso
chirp_rate          = B/T; % rate di variazione della frequenza (chirp rate) [Hz/s]

chirp_signal        = sin(2*pi*(f0 - chirp_rate * (chirp_t_axis - T) / 2) .* chirp_t_axis) .* triang(length(chirp_t_axis))';
% chirp lineare discendente
% frequenza che parte da f0+B/2 (t=0) e scende fino a f0-B/2 (t=T)
% viene applicata una finestra triangolare

chirp_signal_norm   = chirp_signal / sqrt(sum(chirp_signal .^ 2) * sampling_period); % normalizzazione energetica
% ----------------------------------------------------------------------- %

%% Auto-Correlazione
auto_correlation    = xcorr(chirp_signal_norm, chirp_signal_norm, (length(time_axis) - 1) / 2);
auto_corr_samples   = length(auto_correlation);
% ----------------------------------------------------------------------- %

%% Parametri ambientali
bottom_depth            = 295; % profondità fondale [m]
target_depth            = 25; % profondità target [m]
target_height           = bottom_depth - target_depth; % altezza del target rispetto al fondale [m]

sediment_first_layer    = 65; % profonditò primo layer di sedimenti [m]
K_reflection_bottom     = 0.75; % coefficiente di riflessione sullo strato di roccia

c                       = 1480; % velocità di propagazione del suono in acqua [m/s]

R                       = 405; % distanza del target dal fondale [m]
distance_ref_CPA        = 800; % distanza tra canale di riferimento e CPA [m]

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
channel_idx         = -75:75; % indici dei canali (75*4.08 = 306)
channel_distance    = 4.08; % distanza tra canali adiacenti [m]
distance_k_CPA      = distance_ref_CPA - channel_idx*channel_distance; % distanza canale k-esimo dal CPA [m]
num_of_channels     = length(channel_idx); % numero di canali

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

%% Correlogramma
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

%% Plot
figure
imagesc(time_axis, distance_ref_CPA - distance_k_CPA, Correlogramma)
xlim([-0.2 0.2])
ylim([-300 300])
currax = gca;
currax.YDir = "normal";
colormap(redblue);
colormap;

figure
plot(time_axis, Correlogramma(120,:))
xlim([-0.2 0.2])
ylim([-3000 3000])
% ----------------------------------------------------------------------- %

%% Funzioni ausiliarie
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