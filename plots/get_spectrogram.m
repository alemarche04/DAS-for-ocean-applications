function fig = get_spectrogram(data, distance_km, sampling_frequency, channel_position_km, nfft, N, window, overlap_pct, varargin)
% GET_SPECTROGRAM Generate spectrogram for a single channel
%
%   fig = GET_SPECTROGRAM(data, distance_km, sampling_frequency, 
%   channel_position_km, nfft, N, window, overlap_pct) creates a time-frequency 
%   spectrogram for a specified channel in the DAS data.
%
%   fig = GET_SPECTROGRAM(..., 'Name', Value) specifies optional
%   parameters using name-value pairs.
%
%   Inputs:
%       data               - [channels x time] data matrix (dB scale)
%       distance_km        - Distance axis vector (km)
%       sampling_frequency - Sampling frequency (Hz)
%       channel_position_km - Position of target channel (km)
%       nfft               - Number of FFT samples
%       N                  - Window length (samples)
%       window             - Spectral window (e.g., hamming(N), hann(N))
%       overlap_pct        - Window overlap percentage (0-100)
%
%   Optional Parameters:
%       'time_lim'       - [1x2] vector [tmin, tmax] time axis limits (s)
%       'frequency_lim'  - [1x2] vector [fmin, fmax] frequency axis limits (Hz)
%       'strain_lim'     - [1x2] vector [min, max] strain amplitude limits (dB)
%
%   Output:
%       fig - Figure handle containing spectrogram plot
%
%   Example:
%       % Generate spectrogram with Hamming window and 50% overlap
%       fig = get_spectrogram(strain_data, distance, 1000, 5.2, 2048, ...
%                            512, hamming(512), 50, 'frequency_lim', [0 50]);
%
%   See also SPECTROGRAM, GET_SPACE_FREQUENCY_PLOT, PWELCH

    % validate input and set up optional parameters
    params = parse_inputs(data, distance_km, sampling_frequency, channel_position_km, nfft, N, window, overlap_pct, varargin{:});

    time_lim = params.time_lim;
    frequency_lim = params.frequency_lim;
    strain_lim = params.strain_lim;
    %

	% extract the channel data for the specified position
    channelData = get_channel(data, distance_km, channel_position_km);

    % calculater short-time Fourier Transform
    noverlap = round(overlap_pct*N);

    [spectrogram, freq_axis, time_axis] = stft(channelData, sampling_frequency, ...
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

	try
        time_and_date = evalin('caller', 'data.time_and_date');
        subtitle({sprintf("Channel at km %.2f", channel_position_km), time_and_date}, "FontSize", 12);
    catch
        warning('Unable to create subtitle: time and date not found');
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

function channel = get_channel(data, distance_km, channel_position_km)
	[~, channel_position_idx] = min(abs(distance_km - channel_position_km));
	channel = data(channel_position_idx, :);
end


% function for input validation
    function results = parse_inputs(data, distance_km, sampling_frequency, channel_position_km, nfft, N, window, overlap_pct, varargin)
    p = inputParser;

    % required parameters
    valid = @(x)validateattributes(x,{'numeric'},{'nonempty'});
    addRequired(p, 'data', valid);
	addRequired(p, 'distance_km', valid);

	valid = @(x)validateattributes(x,{'numeric'},{'positive', 'scalar'});
    addRequired(p, 'sampling_frequency', valid);

	valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'nonnegative', 'scalar'});
	addRequired(p, 'channel_position_km', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'positive', 'integer', 'scalar'});
    addRequired(p, 'nfft', valid);
    addRequired(p, 'N', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'vector'});
    addRequired(p, 'window', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'nonnegative', 'scalar', '<=', 100});
    addRequired(p, 'overlap_pct', valid);

    % optional parameters
    valid = @(x) isempty(x) || (isnumeric(x) && isvector(x) && all(x >= 0));
    addParameter(p, 'time_lim', [], valid);
    addParameter(p, 'frequency_lim', [], valid);

    valid = @(x) isempty(x) || (isnumeric(x) && isvector(x));
    addParameter(p, 'strain_lim', [], valid);

    parse(p, data, distance_km, sampling_frequency, channel_position_km, nfft, N, window, overlap_pct, varargin{:});

    results = p.Results;
    end
    %