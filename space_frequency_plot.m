% Spatio-Spectral (fx) plot of a time window

% --- INPUT ---
% data : data matrix [channel x time sample]
% distance : distance axis [km]
% sampling_frequency : sampling frequency [Hz]
% time_window : duration of each fx plot [s]
% nfft : number of FFT samples
% time_start : start time of plot time interval [s]
% time_end : end time of plot time interval[s]
% frequency_min : minimum plot frequency [Hz]
% frequency_max : maximum plot frequency [Hz]
% strain_min : minimum plot strain (dB)
% strain_max : minimum plot strain (dB)

% get_animation : if true, produces an animation of the fx plot

function space_frequency_plot(data, distance, sampling_frequency, nfft, time_window, ...
    time_start, time_end, frequency_min, frequency_max, strain_min, strain_max, get_animation)

    % creates frequency axis centered in zero
    if mod(nfft, 2) == 0
        % nfft even
        frequency_axis = (-nfft/2:nfft/2-1) * (sampling_frequency / nfft);
    else
        % nfft odd
        frequency_axis = (-(nfft-1)/2:(nfft-1)/2) * (sampling_frequency / nfft);
    end

    % selects data in the time window
    time_start_idx = round(time_start * sampling_frequency);
    time_end_idx = min(size(data, 2), round(time_end * sampling_frequency));
    data_window = data(:, time_start_idx:time_end_idx);

    % number of plots
    nb_subplots = ceil(size(data_window, 2) / (time_window * sampling_frequency));

    % subplot strucutre
    nb_columns = floor(sqrt(nb_subplots));
    nb_rows = ceil(nb_subplots / nb_columns);
    
    % open figure
    figure;
    sgtitle('Spatio-Spectral Rapresentation', 'FontSize', 16, 'FontWeight', 'bold');

    % open file for animation
    if(get_animation)
        fx_animation = VideoWriter('space_frequency_animation.avi', 'Motion JPEG AVI');
        fx_animation.Quality = 95;
        fx_animation.FrameRate = 3;
        open(fx_animation);
    end

    % Prepare the figure for subplots
    for i = 1:nb_subplots
        subplot(nb_rows, nb_columns, i);
        
        % Define the time segment for the current subplot
        segment_start = floor((i-1) * time_window * sampling_frequency + 1);
        segment_end = min(floor(segment_start + time_window * sampling_frequency - 1), size(data_window, 2));
        current_segment = data_window(:, segment_start:segment_end);
        
        % Compute the FFT for the current segment
        fft_segment = 2 * abs(fftshift(fft(current_segment, nfft, 2), 2));
        fft_segment = fft_segment / nfft;

        fft_segment_dB = 20*log10(abs(fft_segment) ./ max(abs(fft_segment), [], "all"));

        % plot
        imagesc(frequency_axis, distance, fft_segment_dB);
        axis xy;

        set(gca, 'YDir', 'normal');
        colormap(parula);
    
        clim([strain_min, strain_max]);
        xlim([frequency_min, frequency_max]);
        xlabel('Frequency (Hz)');
        ylabel('Distance (km)');

        if(get_animation)
            f = figure('Visible','off');
            
            imagesc(frequency_axis, distance, fft_segment_dB);
            axis xy;
    
            set(gca, 'YDir', 'normal');
            colormap(parula);
        
            clim([strain_min, strain_max]);
            xlim([frequency_min, frequency_max]);

            frame = getframe(f);
            writeVideo(fx_animation, frame);
            close(f)
        end
        
    end

    c = colorbar;
    c.Label.String = 'Strain (dB)';

    if(get_animation)
        close(fx_animation);
    end

end