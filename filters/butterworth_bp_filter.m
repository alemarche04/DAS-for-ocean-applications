function filtered_data = butterworth_bp_filter(data, cutoff_freq, order, sampling_freq)
% BUTTERWORTH_BP_FILTER Applies a zero-phase Butterworth bandpass filter.
%
%   FILTERED_DATA = BUTTERWORTH_BP_FILTER(DATA, CUTOFF_FREQ, ORDER, SAMPLING_FREQ)
%   filters the input signal using a digital Butterworth filter. It utilizes 
%   a forward-backward (zero-phase) implementation to avoid phase distortion,
%   which is critical for maintaining signal timing in DAS applications.
%
%   Input Arguments:
%       data          - Input signal (matrix or vector). If a matrix, filtering 
%                       is applied across the second dimension (time).
%       cutoff_freq   - Two-element vector [f_low, f_high] defining the 
%                       passband in Hz.
%       order         - Filter order (e.g., 3 or 5). Note: filtfilt doubles 
%                       the effective order.
%       sampling_freq - Sampling frequency of the data in Hz.
%
%   Output Arguments:
%       filtered_data - The zero-phase filtered signal, returned in the same 
%                       orientation as the input.
%
%   Note:
%       The function automatically transposes the data for filtfilt and 
%       transposes it back to ensure the output matches the input shape.
%
%   See also: BUTTER, FILTFILT, DESIGNFILT

    % Normalize cutoff frequencies relative to the Nyquist frequency
    cutoff_bp = cutoff_freq / (sampling_freq / 2);
    
    % Design the Butterworth filter coefficients
    [B, A] = butter(order, cutoff_bp, 'bandpass');
    
    % Log processing step and start timer
    printStep('Applying Butterworth bandpass filter');
    
    % Apply zero-phase filtering
    % Data is transposed to ensure filtering occurs along the time dimension
    filtered_data = filtfilt(B, A, data')';
    
    % Output elapsed time
    printTime();
end

% -----------------------------------------------------------------------%
%% UTILITY FUNCTIONS
function printStep(msg)
% PRINTSTEP Formats and displays the current processing step in the command window.
%
%   Displays the message followed by a progress line of dots and starts 
%   a tic timer for benchmarking.

    numDots = 60 - length(msg);
    fprintf('%s%s', msg, repmat('.', 1, max(numDots, 3)));
    tic;
end

function printTime()
% PRINTTIME Displays the time elapsed since the last printStep call.
%
%   Stops the toc timer and prints the duration in seconds with 3-decimal 
%   point precision.

    fprintf(' Time elapsed: %.3f s\n', toc);
end