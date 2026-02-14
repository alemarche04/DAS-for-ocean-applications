function fig = get_space_frequency_plot(data, distance, sampling_frequency, ...
	nfft, time_window, time_interval, filename_animation, varargin)
% GET_SPACE_FREQUENCY_PLOT Generates spatio-spectral (f-x) plots and animations.
%
%   FIG = GET_SPACE_FREQUENCY_PLOT(DATA, DISTANCE, SAMPLING_FREQUENCY, ...
%          NFFT, TIME_WINDOW, TIME_INTERVAL, FILENAME_ANIMATION)
%   computes the Fourier Transform across the temporal dimension for multiple
%   overlapping segments. It displays these as a tiled layout of frequency-distance 
%   images and can optionally export the process as a VideoWriter animation.
%
%   Input Arguments:
%       data                - 2D matrix of DAS data [channels x samples].
%       distance            - Vector of spatial coordinates for channels [m].
%       sampling_frequency  - System sampling rate [Hz].
%       nfft                - Number of FFT points for frequency resolution.
%       time_window         - Duration of each analysis segment [s].
%       time_interval       - 2-element vector [start end] for data selection [s].
%       filename_animation  - String path for the output .avi video file.
%
%   Optional Parameters (Name-Value Pairs):
%       'subtitle'          - Plot subtitle string (typically time and date)
%       'frequency_lim'     - 2-element vector [min max] for Frequency axis [Hz].
%       'strain_lim'        - 2-element vector [min max] for Colorbar/dB limits.
%       'get_animation'     - Logical (true/false) to enable video export.
%
%   Output Arguments:
%       fig                 - Handle to the main tiled figure.
%
%   Notes:
%       The function uses dB scaling: 20*log10(|S|/max(|S|)).
%       Animation frames are rendered at 3 FPS using 'Motion JPEG AVI' codec.
%
%   See also: TILEDLAYOUT, FFT, VIDEOWRITER, GET_SPECTROGRAM

    % validate input and set up optional parameters
    params = parse_inputs(data, distance, sampling_frequency, nfft, ...
    time_window, time_interval, filename_animation, varargin{:});
  
    frequency_lim = params.frequency_lim;
    strain_lim = params.strain_lim;
    get_animation = params.get_animation;

    % creates frequency axis centered in zero
    if mod(nfft, 2) == 0
        frequency_axis = (-nfft/2:nfft/2-1) * (sampling_frequency / nfft);
    else
        frequency_axis = (-(nfft-1)/2:(nfft-1)/2) * (sampling_frequency / nfft);
    end

    % ensure start index is at least 1
    time_start_idx = max(1, round(time_interval(1) * sampling_frequency));
    time_end_idx = min(size(data, 2), round(time_interval(2) * sampling_frequency));
    data_window = data(:, time_start_idx:time_end_idx);

    % subplot structure
    nb_subplots = ceil(size(data_window, 2) / (time_window * sampling_frequency));
    nb_columns = floor(sqrt(nb_subplots));
    nb_rows = ceil(nb_subplots / nb_columns);

    % open figure and set up subplots
    fig = figure(Name="Space-Frequency plot", NumberTitle="off");
    t = tiledlayout(nb_rows, nb_columns, 'TileSpacing', 'Compact', 'Padding', 'compact');
    
    % prepare VideoWriter
    if ~isempty(get_animation) && get_animation
        fx_animation = VideoWriter(filename_animation, 'Motion JPEG AVI');
        fx_animation.Quality = 95;
        fx_animation.FrameRate = 3;
        open(fx_animation);
        
        % pre-create a single invisible figure for animation frames
        fig_anim = figure('Visible', 'off');
        ax_anim = axes(fig_anim);
        % initialize with zeros
        hImg = imagesc(ax_anim, frequency_axis, distance, zeros(length(distance), length(frequency_axis)));
        axis xy; colormap(parula);
        xlabel('Frequency (Hz)'); ylabel('Distance (m)');
        c_anim = colorbar; c_anim.Label.String = 'Strain (dB)';
        if ~isempty(strain_lim), clim(ax_anim, strain_lim); end
        if ~isempty(frequency_lim), xlim(ax_anim, frequency_lim); end
	end

	% flush graphics queue before loop
    drawnow;

    % plot subplots
    for i = 1:nb_subplots
        nexttile
        
        % define segment
        segment_start = floor((i-1) * time_window * sampling_frequency + 1);
        segment_end = min(floor(segment_start + time_window * sampling_frequency - 1), size(data_window, 2));
        current_segment = data_window(:, segment_start:segment_end);
        
        % compute the FFT
        fft_segment = 2 * abs(fftshift(fft(current_segment, nfft, 2), 2));
        fft_segment = fft_segment / nfft;
        fft_segment_dB = 20*log10(abs(fft_segment) ./ max(abs(fft_segment), [], "all"));
        
        % title plot
        imagesc(frequency_axis, distance, fft_segment_dB);
        axis xy;
        title(sprintf("%0.2f - %0.2f s", ...
            (time_interval(1) + segment_start/sampling_frequency), ...
            (time_interval(1) + segment_end/sampling_frequency)));
        
        if ~isempty(frequency_lim), xlim(frequency_lim); end
        if ~isempty(strain_lim), clim(strain_lim); end

        % animation frame generation
        if ~isempty(get_animation) && get_animation
            % verify that the hidden figure and image still exist
            if isgraphics(hImg) && isvalid(hImg)
                set(hImg, 'CData', fft_segment_dB); 
                title(ax_anim, sprintf("Time: %0.2f - %0.2f s", ...
                    (time_interval(1) + segment_start/sampling_frequency), ...
                    (time_interval(1) + segment_end/sampling_frequency)));
                
                % capture frame from hidden figure
                frame = getframe(fig_anim);
                writeVideo(fx_animation, frame);
            else
                % if handle is lost stop animation but allow tiled plot to finish
                warning('Animation figure handle was lost. Video export stopped.');
                get_animation = false;
            end
        end
    end

    % set title
	if ~isempty(params.subtitle)
		sgtitle({"Spatio-Spectral Representation", sprintf("From %.2f s to %.2f s", time_interval), params.subtitle});
	else
		sgtitle(t, "Spatio-Spectral Representation");
	end
    %
	
    % finalize and close animation
    if ~isempty(get_animation) && get_animation
        close(fx_animation);
        close(fig_anim);
    end
end
% -----------------------------------------------------------------------%

%% INPUT PARSING
function results = parse_inputs(data, distance, sampling_frequency, nfft, ...
    time_window, time_interval, filename_animation, varargin)
    p = inputParser;

	% required parameters
    addRequired(p, 'data', @isnumeric);
    addRequired(p, 'distance', @(x) isnumeric(x) && isvector(x) && all(x>=0));
    addRequired(p, 'sampling_frequency', @(x) isnumeric(x) && x>0);
    addRequired(p, 'nfft', @(x) isnumeric(x) && x > 0);
    addRequired(p, 'time_window', @(x) isnumeric(x) && x>0);
    addRequired(p, 'time_interval', @(x) isnumeric(x) && isvector(x) && all(x>=0));
    addRequired(p, 'filename_animation', @ischar);
    
	% optional parameters
	addParameter(p, 'subtitle', [], @(x) isempty(x) || ischar(x) || isstring(x));
    addParameter(p, 'frequency_lim', [], @isnumeric);
    addParameter(p, 'strain_lim', [], @isnumeric);
    addParameter(p, 'get_animation', false, @islogical);
    
    parse(p, data, distance, sampling_frequency, nfft, ...
        time_window, time_interval, filename_animation, varargin{:});
    results = p.Results;
end