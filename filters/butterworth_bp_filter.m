function filtered_data = butterworth_bp_filter(data, cutoff_freq, order, sampling_freq)
% BUTTERWORTH_BP_FILTER Apply Butterworth bandpass filter to multi-channel data
%
%   filtered_data = BUTTERWORTH_BP_FILTER(data, cutoff_freq, order, sampling_freq)
%   applies a Butterworth bandpass filter to the input data.
%
%   Inputs:
%       data         - [channels x time] data matrix to be filtered
%       cutoff_freq  - [1x2] vector containing [lower, upper] cutoff frequencies (Hz)
%       order        - Filter order (positive integer)
%       sampling_freq - Sampling frequency (Hz)
%
%   Output:
%       filtered_data - [channels x time] filtered data matrix
%
%   Example:
%       % Filter EEG data between 8-12 Hz with 4th order filter
%       fs = 250;  % sampling frequency
%       filtered = butterworth_bp_filter(eeg_data, [8 12], 4, fs);
%
%   See also BUTTER, FILTFILT

    cutoff_bp = cutoff_freq/(sampling_freq/2);
    [B, A] = butter(order, cutoff_bp, 'bandpass');

    tic
    fprintf('\nApplying Butterworth bandpass filter...\n');
    filtered_data = filtfilt(B, A, data')';
    toc

end