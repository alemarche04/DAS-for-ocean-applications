% Spectrogram of a single channel

% --- INPUT ---
% channel_target : signal of a single channel
% nnft : number of FFT samples
% N : window length
% window : spectral window
% overlap_pct : overlap pencentage
% sampling_frequency : sampling frequency [Hz]

% --- OPTIONAL PARAMETERS ---
% time_start : start time of plot time interval [s]
% time_end : end time of plot time interval[s]
% frequency_min : minimum plot frequency [Hz]
% frequency_max : maximum plot frequency [Hz]
% strain_min : minimum plot strain (dB)
% strain_max : minimum plot strain (dB)

function fig = plot_spectrogram(data, nfft, N, window, overlap_pct, sampling_frequency, varargin)

    % validate input and set up optional parameters
    params = parse_inputs(data, nfft, N, window, overlap_pct, sampling_frequency, varargin{:});

    time_start = params.time_start;
    time_end = params.time_end;
    frequency_min = params.frequency_min;
    frequency_max = params.frequency_max;
    strain_min = params.strain_min;
    strain_max = params.strain_max;
    %

    % calculater short-time Fourier Transform
    noverlap = round(overlap_pct*N);

    [spectrogram, freq_axis, time_axis] = stft(data, sampling_frequency, ...
        "Window", window, "OverlapLength", noverlap, "FFTLength", nfft);
    %

    % dB scale
    spectrogram_dB = 20*log10(abs(spectrogram) ./ max(abs(spectrogram), [], "all"));
    %

    % plot spectrogram
    fig = figure;
    imagesc(time_axis, freq_axis, spectrogram_dB);
    axis xy;
    c = colorbar;
    xlabel('Time (s)', 'FontSize', 12);
    ylabel('Frequency (Hz)', 'FontSize', 12);
    c.Label.String = 'Strain (dB)';
    title('Spectrogram', 'FontSize', 14, 'FontWeight', 'bold');
    %
    
    % plot limits configuration
    if ~isempty(time_start) & ~isempty(time_end)
    xlim([time_start time_end]);
    end

    if ~isempty(frequency_min) & ~isempty(frequency_max)
    ylim([frequency_min frequency_max]);
    end

    if ~isempty(strain_min) & ~isempty(strain_max)
        clim([strain_min strain_max]);
    end
    %

end


% function for input validation
    function results = parse_inputs(data, nfft, N, window, overlap_pct, sampling_frequency, varargin)
    p = inputParser;

    valid = @(x)validateattributes(x,{'numeric'},{'nonempty'});
    addRequired(p, 'data', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'positive', 'integer', 'scalar'});
    addRequired(p, 'nfft', valid);
    addRequired(p, 'N', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'vector'});
    addRequired(p, 'window', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'nonnegative', 'scalar', '<=', 100});
    addRequired(p, 'overlap_pct', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'positive', 'scalar'});
    addRequired(p, 'sampling_frequency', valid);


    valid = @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 0);
    addParameter(p, 'time_start', [], valid);
    addParameter(p, 'time_end', [], valid);
    addParameter(p, 'frequency_min', [], valid);
    addParameter(p, 'frequency_max', [], valid);

    valid = @(x) isempty(x) || (isnumeric(x) && isscalar(x));
    addParameter(p, 'strain_min', [], valid);
    addParameter(p, 'strain_max', [], valid);

    parse(p, data, nfft, N, window, overlap_pct, sampling_frequency, varargin{:});


    results = p.Results;
    end
    %