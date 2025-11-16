% Butterworth bandpass filter

% --- INPUT ---
% data : [channels x time] data matrix
% lower_freq : lower cutoff frequency
% higher_freq : higher cutoff frequency
% order : filter order
% sampling_freq : sampling frequency

% --- OUTPUT ---
% filtered_data : [channels x time] data matrix filtered

function filtered_data = butterworth_bp_filter(data, lower_freq, higher_freq, order, sampling_freq)

    cutoff_freq = [lower_freq higher_freq]/(sampling_freq/2);
    [B, A] = butter(order, cutoff_freq, 'bandpass');

    fprintf('Applying Butterworth bandpass filter\n');
    filtered_data = filtfilt(B, A, data')';

end