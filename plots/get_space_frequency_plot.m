function fig = get_space_frequency_plot(data, distance, sampling_frequency, ...
	nfft, time_window, time_interval, filename_animation, varargin)

    % validate input and set up optional parameters
    params = parse_inputs(data, distance, sampling_frequency, nfft, ...
    time_window, time_interval, filename_animation, varargin{:});
  
    frequency_lim = params.frequency_lim;
    strain_lim = params.strain_lim;
    get_animation = params.get_animation;
    %

    % creates frequency axis centered in zero
    if mod(nfft, 2) == 0
        % nfft even
        frequency_axis = (-nfft/2:nfft/2-1) * (sampling_frequency / nfft);
    else
        % nfft odd
        frequency_axis = (-(nfft-1)/2:(nfft-1)/2) * (sampling_frequency / nfft);
    end
    %

    % selects data in the time window
    time_start_idx = round(time_interval(1) * sampling_frequency);
    time_end_idx = min(size(data, 2), round(time_interval(2) * sampling_frequency));
    data_window = data(:, time_start_idx:time_end_idx);
    %

    % subplot strucutre
    nb_subplots = ceil(size(data_window, 2) / (time_window * sampling_frequency));
    nb_columns = floor(sqrt(nb_subplots));
    nb_rows = ceil(nb_subplots / nb_columns);
    %
    
    % open figure and set up subplots
    fig = figure;
    t = tiledlayout(nb_rows,nb_columns,'TileSpacing','Compact', 'Padding', 'compact');
    %
    
    % open file for animation
    if ~isempty(get_animation) & get_animation
		fx_animation = VideoWriter(filename_animation, 'Motion JPEG AVI');
        fx_animation.Quality = 95;
        fx_animation.FrameRate = 3;
        open(fx_animation);
    end

    % plot subplots
    for i = 1:nb_subplots
        
        nexttile
        
        % Define the time segment for the current subplot
        segment_start = floor((i-1) * time_window * sampling_frequency + 1);
        segment_end = min(floor(segment_start + time_window * sampling_frequency - 1), size(data_window, 2));
        current_segment = data_window(:, segment_start:segment_end);
        %

        % Compute the FFT for the current segment
        fft_segment = 2 * abs(fftshift(fft(current_segment, nfft, 2), 2));
        fft_segment = fft_segment / nfft;

        fft_segment_dB = 20*log10(abs(fft_segment) ./ max(abs(fft_segment), [], "all"));
        %

        % plot
        imagesc(frequency_axis, distance, fft_segment_dB);
        axis xy;
        title_subplot = sprintf("%0.2f s - %0.2f s", (time_interval(1) + segment_start/sampling_frequency), (time_interval(1) + segment_end/sampling_frequency));
        title(title_subplot);
        set(gca, 'YDir', 'normal');
        colormap(parula);
        xlabel('Frequency (Hz)');
        ylabel('Distance (km)');
        %

        % plot limits configuration
        if ~isempty(frequency_lim)
            xlim(frequency_lim);
        end
    
        if ~isempty(strain_lim)
            clim(strain_lim);
        end
        %

        try
            time_and_date = evalin('caller', 'data.time_and_date');
            sgtitle({"Spatio-Spectral Representation", sprintf("From %.2f s to %.2f s", time_interval), time_and_date});
        catch
            warning('Unable to create subtitle: time and date not found');
        end

        % generates animation frame
        if(get_animation)
            f = figure('Visible','off');
            
            imagesc(frequency_axis, distance, fft_segment_dB);
            axis xy;
    
            set(gca, 'YDir', 'normal');
            colormap(parula);
        
            clim(strain_lim);
            xlim(frequency_lim);

            xlabel('Frequency (Hz)');
            ylabel('Distance (km)');

            c = colorbar;
            c.Label.String = 'Strain (dB)';

            frame = getframe(f);
            writeVideo(fx_animation, frame);
            close(f)
        end
        %
        
    end

    % creates colorbar for last subplot
    c = colorbar;
    c.Label.String = 'Strain (dB)';
    %

    % close and save animation
    if ~isempty(get_animation) & get_animation
        close(fx_animation);
    end
    %
    
end


% function for input validation
function results = parse_inputs(data, distance, sampling_frequency, nfft, ...
time_window, time_interval,filename_animation, varargin)

p = inputParser;

valid = @(x)validateattributes(x,{'numeric'},{'nonempty'});
addRequired(p, 'data', valid);

valid = @(x)validateattributes(x,{'numeric'},{'nonnegative'});
addRequired(p, 'distance', valid);

valid = @(x)validateattributes(x,{'numeric'},{'positive', 'scalar'});
addRequired(p, 'sampling_frequency', valid);

valid = @(x)validateattributes(x,{'numeric'},{'positive', 'integer', 'scalar'});
addRequired(p, 'nfft', valid);

valid = @(x)validateattributes(x,{'numeric'},{'positive', 'scalar'});
addRequired(p, 'time_window', valid);

valid = @(x)validateattributes(x,{'numeric'},{'nonnegative', 'vector'});
addRequired(p, 'time_interval', valid);

valid = @(x)validateattributes(x,{'char'},{'nonempty'});
addRequired(p, 'filename_animation', valid);


valid = @(x) isempty(x) || (isnumeric(x) && isvector(x) && all(x >= 0));
addParameter(p, 'frequency_lim', [], valid);

valid = @(x) isempty(x) || (isnumeric(x) && isvector(x));
addParameter(p, 'strain_lim', [], valid);

valid = @(x) isempty(x) || (islogical(x));
addParameter(p, 'get_animation', false, valid);

parse(p, data, distance, sampling_frequency, nfft, ...
    time_window, time_interval, filename_animation, varargin{:});

results = p.Results;
end
%