% Strain waveform of one single channel

% --- INPUT ---
% channel : signal of a single channel
% time : time axis [s]
% time_start : start time of plot time interval [s]
% time_end : end time of plot time interval[s]
% amplitude_min : lower y-axis (amplitute) limit
% amplitude_max : higher y-axis (amplitute) limit

function strain_waveform(channel, time, time_start, time_end, amplitude_min, amplitude_max)
    
    figure;
    plot(time, channel)

    xlim([time_start, time_end]);
    ylim([amplitude_min, amplitude_max]);

    xlabel('Time (s)', 'FontSize', 14);
    ylabel('Strain Amplitude', 'FontSize', 14);
    title('Strain Waveform', 'FontSize', 16, 'FontWeight', 'bold');

end