function fig = get_spectrogram(data, distance_km, sampling_frequency, ...
	channel_position_km, nfft, N, window, overlap_pct, varargin)
% GET_SPECTROGRAM Computes and plots the STFT of a specific DAS channel.
%
%   FIG = GET_SPECTROGRAM(DATA, DISTANCE_KM, SAMPLING_FREQUENCY, ...
%                         CHANNEL_POSITION_KM, NFFT, N, WINDOW, OVERLAP_PCT)
%   extracts a single channel from the DAS matrix, computes the Short-Time 
%   Fourier Transform (STFT), and displays it on a dB-normalized scale.
%
%   Input Arguments:
%       data                - 2D matrix of DAS data [channels x samples].
%       distance_km         - Vector mapping channel indices to distances [km].
%       sampling_frequency  - System sampling rate [Hz].
%       channel_position_km - The specific spatial location to analyze [km].
%       nfft                - Number of FFT points.
%       N                   - Segment length (window size in samples).
%       window              - Window coefficients (vector, e.g., hann(N)).
%       overlap_pct         - Overlap percentage between segments (0 to 1).
%
%   Optional Parameters (Name-Value Pairs):
%       'subtitle'          - Plot subtitle string (typically time and date)
%       'time_lim'          - 2-element vector [min max] for X-axis limits (s).
%       'frequency_lim'     - 2-element vector [min max] for Y-axis limits (Hz).
%       'strain_lim'        - 2-element vector [min max] for colorbar limits (dB).
%		'norm'              - Logical (true/false) to enable normalization
%		(deafult: false)
%
%   Output Arguments:
%       fig                 - Handle to the generated figure.
%
%   Scaling Note:
%       The spectrogram is normalized such that the maximum value is 0 dB:
%       dB = 20 * log10( |S| / max(|S|) )
%
%   See also: STFT, IMAGESC, HANN, GET_STRAIN_WAVEFORM

    % validate input and set up optional parameters
    params = parse_inputs(data, distance_km, sampling_frequency, channel_position_km, nfft, N, window, overlap_pct, varargin{:});
    time_lim = params.time_lim;
    frequency_lim = params.frequency_lim;
    strain_lim = params.strain_lim;
	norm = params.norm;
    %
	% extract the channel data for the specified position
    channel = get_channel(data, distance_km, channel_position_km);
    % calculater short-time Fourier Transform
    noverlap = round(overlap_pct*N);
    [spectrogram, freq_axis, time_axis] = stft(channel.data, sampling_frequency, ...
        "Window", window, "OverlapLength", noverlap, "FFTLength", nfft);
    %
	if norm
    	% normalized dB scale
    	spectrogram_dB = 20*log10(abs(spectrogram) ./ max(abs(spectrogram), [], "all"));
    	c.Label.String = 'Strain (dB) (normalized)';
	else
    	% dB scale (no normalization)
    	spectrogram_dB = 20*log10(abs(spectrogram));
    	c.Label.String = 'Strain (dB)';
	end
    % plot spectrogram
	fig = figure(Name="Spectrogram", NumberTitle="off");
	imagesc(time_axis, freq_axis, spectrogram_dB);
	axis xy;
	c = colorbar;
	xlabel('Time (s)', 'FontSize', 12);
	ylabel('Frequency (Hz)', 'FontSize', 12);
    title('Spectrogram', 'FontSize', 14, 'FontWeight', 'bold');
	%
	% apply optional subtitle
	if ~isempty(params.subtitle)
		subtitle({sprintf("Channel at km %.3f (n° %d)", channel_position_km, channel.idx), params.subtitle}, "FontSize", 12);
	end
    %
    
    % plot limits configuration
    if ~isempty(time_lim)
        xlim(time_lim);
    end
    if ~isempty(frequency_lim)
        ylim(frequency_lim);
    end
    if ~isempty(strain_lim)
        clim(strain_lim);
    end
    %
end
% -----------------------------------------------------------------------%

%% HELP FUNCTIONS
function channel = get_channel(data, distance_km, channel_position_km)
% GET_CHANNEL Helper function to find the nearest channel by distance.
	[~, channel.idx] = min(abs(distance_km - channel_position_km));
	channel.data = data(channel.idx, :);
end
% -----------------------------------------------------------------------%

%% INPUT PARSING
function results = parse_inputs(data, distance_km, sampling_frequency, channel_position_km, nfft, N, window, overlap_pct, varargin)
    p = inputParser;

    % required parameters
    addRequired(p, 'data', @isnumeric);
    addRequired(p, 'distance', @(x) isnumeric(x) && isvector(x) && all(x>=0));
    addRequired(p, 'sampling_frequency', @(x) isnumeric(x) && isscalar(x) && x > 0);
	addRequired(p, 'channel_position_km', @(x) isnumeric(x) && isscalar(x) && x>=0);
    addRequired(p, 'nfft', @(x) isnumeric(x) && x > 0);
    addRequired(p, 'N', @(x) isnumeric(x) && x > 0);
    addRequired(p, 'window', @(x) isnumeric(x) && isvector(x));
    addRequired(p, 'overlap_pct', @(x) isnumeric(x) && isscalar(x) && x>=0 && x <=1);

    % optional parameters
	addParameter(p, 'subtitle', [], @(x) isempty(x) || ischar(x) || isstring(x));
    addParameter(p, 'time_lim', [], @(x) isempty(x) || (isnumeric(x) && isvector(x) && all(x >= 0)));
    addParameter(p, 'frequency_lim', [], @(x) isempty(x) || (isnumeric(x) && isvector(x) && all(x >= 0)));
    addParameter(p, 'strain_lim', [], @(x) isempty(x) || (isnumeric(x) && isvector(x)));
	addParameter(p, 'norm', false, @islogical);

    parse(p, data, distance_km, sampling_frequency, channel_position_km, nfft, N, window, overlap_pct, varargin{:});
    results = p.Results;
end