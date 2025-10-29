% Spectrogram of a single channel

% --- INPUT ---
% channel_target : signal of a single channel
% nnft : number of FFT samples
% N : window length
% window : window funciton
% overlap_pct : overlap pencentage
% sampling_frequency : sampling frequency [Hz]
% time_start : start time of plot time interval [s]
% time_end : end time of plot time interval[s]
% frequency_min : minimum plot frequency [Hz]
% frequency_max : maximum plot frequency [Hz]
% strain_min : minimum plot strain (dB)
% strain_max : minimum plot strain (dB)

function plot_spectrogram(channel, nfft, N, window, overlap_pct, sampling_frequency, ...
    time_start, time_end, frequency_min, frequency_max, strain_min, strain_max)
    
    noverlap = round(overlap_pct*N);
    
    [spectrogram, freq_axis, time_axis] = stft(channel, sampling_frequency, "Window", window, "OverlapLength", noverlap, "FFTLength", nfft);
    
    spectrogram_dB = 20*log10(abs(spectrogram) ./ max(abs(spectrogram), [], "all")); % decibel scale

    figure;
    imagesc(time_axis, freq_axis, spectrogram_dB);
    axis xy;
    
    c = colorbar;
    
    clim([strain_min strain_max]);
    xlim([time_start time_end]);
    ylim([frequency_min frequency_max]);

    xlabel('Time (s)', 'FontSize', 14);
    ylabel('Frequency (Hz)', 'FontSize', 14);
    c.Label.String = 'Strain (dB)';
    title('Spectrogram', 'FontSize', 16, 'FontWeight', 'bold');

end