function fig = get_strain_waveform(data, distance, time, channel_position_m, ...
	filename_audio, sampling_frequency_Hz, varargin)
% GET_STRAIN_WAVEFORM Extracts a specific channel, plots its waveform, and exports audio.
%
%   FIG = GET_STRAIN_WAVEFORM(DATA, DISTANCE_KM, TIME, CHANNEL_POSITION_KM, ...
%                             FILENAME_AUDIO, SAMPLING_FREQUENCY_HZ)
%   identifies the closest sensor channel to the requested spatial position,
%   visualizes the strain amplitude over time, and writes the signal to a
%   .wav file.
%
%   Input Arguments:
%       data                  - 2D matrix of DAS data [channels x samples].
%       distance              - Vector mapping channel indices to distances [m].
%       time                  - Time vector for the X-axis [s].
%       channel_position_m    - The specific spatial location to extract [m].
%       filename_audio        - String/Path for the output .wav file.
%       sampling_frequency_Hz - System sampling rate [Hz].
%
%   Optional Parameters (Name-Value Pairs):
%       'subtitle'            - Plot subtitle string (typically time and date)
%       'time_lim'            - 2-element vector [min max] for X-axis limits (s).
%       'strain_lim'          - 2-element vector [min max] for Y-axis limits.
%
%   Output Arguments:
%       fig                   - Handle to the generated figure.
%
%   Audio Export Note:
%       The function scales the signal and applies a 3x resampling 
%       factor to the output audio to shift low-frequency signals into 
%       a more audible range.
%
%   See also: AUDIOWRITE, MIN, GET_TIME_SPACE_PLOT

    % validate input and set up optional parameters
    params = parse_inputs(data, distance, time, channel_position_m, filename_audio, sampling_frequency_Hz, varargin{:});
    time_lim = params.time_lim;
    strain_lim = params.strain_lim;
    %

	% extract the channel data for the specified position
    [~, channel_idx] = min(abs(distance - channel_position_m));
	channel_data = data(channel_idx, :);
	%
    
    % plot figure
    fig = figure(Name="Strain Waveform", NumberTitle="off");
    plot(time, channel_data)
    xlabel('Time (s)', 'FontSize', 12);
    ylabel('Strain Amplitude', 'FontSize', 12);
    title('Strain Waveform', 'FontSize', 14, 'FontWeight', 'bold');
    %
	% apply optional subtitle
	if ~isempty(params.subtitle)
		subtitle({sprintf("Channel at m %.2f", channel_position_m), params.subtitle}, "FontSize", 12);
	end
    %
    % plot limits configuration
    if ~isempty(time_lim)
        xlim(time_lim);
    else
        xlim([time(1) time(end)]);
    end
    if ~isempty(strain_lim)
        ylim(strain_lim);
    end
    %
	% Audio file processing and saving
	audioSignal = channel_data - mean(channel_data); % remove DC offset
	peakVal = max(abs(audioSignal)); % find absolute peak
	if peakVal > 0 % normalize non silent signal
    	audioSignal = (audioSignal / peakVal) * 0.9; % scale so max peak is 0.9
	end
	% audiowrite(filename_audio, audioSignal, round(sampling_frequency_Hz*3));
	audiowrite(filename_audio, audioSignal, round(sampling_frequency_Hz*3), 'BitsPerSample', 24);
    
end
% -----------------------------------------------------------------------%

%% INPUT PARSING
function results = parse_inputs(data, distance, time, channel_position_m, filename_audio, sampling_frequency_Hz, varargin)
    p = inputParser;
	
    % required parameters
    addRequired(p, 'data', @isnumeric);
	addRequired(p, 'distance', @(x) isnumeric(x) && isvector(x) && all(x>=0));
    addRequired(p, 'time', @(x) isnumeric(x) && isvector(x) && all(x>=0));
    addRequired(p, 'channel_position_m', @(x) isnumeric(x) && isscalar(x) && x>=0);    
    addRequired(p, 'filename_audio', @ischar); 
    addRequired(p, 'sampling_frequency_Hz', @(x) isnumeric(x) && isscalar(x) && x>=0); 

    % optional parameters
	addParameter(p, 'subtitle', [], @(x) isempty(x) || ischar(x) || isstring(x));
    addParameter(p, 'time_lim', [], @(x) isempty(x) || (isnumeric(x) && isvector(x) && all(x >= 0)));
    addParameter(p, 'strain_lim', [], @(x) isempty(x) || (isnumeric(x) && isvector(x)));
	
    parse(p, data, distance, time, channel_position_m, filename_audio, sampling_frequency_Hz, varargin{:});
    results = p.Results;
end