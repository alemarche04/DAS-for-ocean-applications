% Time-space representation (t-x plot) of the strain data

% --- INPUT ---
% data : [channel x time sample] data matrix (dB scale)
% timestamp : time info
% dist_km : distance axis [km]
% time_start : start time of plot time interval [s]
% time_end : end time of plot time interval[s]
% distance_min : minimum plot distance [km]
% distance_max : maximum plot distance [km]
% strain_min : minimum plot strain (dB)
% strain_max : minimum plot strain (dB)

function time_space_plot(data, time, dist_km, time_start, time_end, distance_min, distance_max, strain_min, strain_max)

    figure;
    imagesc(time, dist_km, data);
    axis xy;
    
    clim([strain_min strain_max]);
    xlim([time_start time_end]);
    ylim([distance_min distance_max]);

    colormap(parula);
    c = colorbar;
    
    title('Time-Space plot', 'FontSize', 16, 'FontWeight', 'bold');
    xlabel('Time (s)', 'FontSize', 14);
    ylabel('Distance (km)', 'FontSize', 14);
    c.Label.String = 'Strain (dB)';
    
end