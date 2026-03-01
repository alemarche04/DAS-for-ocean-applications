function trace_out = fk_filter_filt(trace_in, fk_filter_matrix)
% FK_FILTER_FILT Applies a designed f-k filter to a 2D DAS data matrix.
%
%   TRACE_OUT = FK_FILTER_FILT(TRACE_IN, FK_FILTER_MATRIX) transforms the 
%   input data into the f-k domain using a 2D FFT, applies the provided 
%   filter mask, and transforms the result back to the t-x domain.
%
%   Input Arguments:
%       trace_in         - 2D matrix of DAS data [channels x samples].
%       fk_filter_matrix - 2D filter mask (same size as trace_in) designed 
%                          using fk_filter_design.
%
%   Output Arguments:
%       trace_out        - Filtered DAS data in the time-space domain.
%
%   Process:
%       1. Compute 2D FFT of the input signal.
%       2. Shift zero-frequency components to the center (fftshift).
%       3. Element-wise multiplication with the f-k mask.
%       4. Inverse shift and Inverse 2D FFT.
%       5. Extract the real part to remove negligible imaginary components.
%
%   Note:
%       The input data and filter matrix must have identical dimensions. 
%       This process is computationally intensive for large DAS files.
%
%   Adapted from: 
%       https://github.com/DAS4Whales/DAS4Whales 
%
%   See also: FK_FILTER_DESIGN, FFT2, IFFT2, FFTSHIFT

    trace = trace_in;
    
    % --- Step 1: Forward 2D FFT ---
    % Transform data from Time-Space (t-x) to Frequency-Wavenumber (f-k)
    printStep('Calculating fk spectrum (2D FFT)');
    fk_trace = fftshift(fft2(trace));
    printTime();
    
    % --- Step 2: Apply Mask ---
    % Point-by-point multiplication in the f-k domain
    printStep('Applying fk filter');
    fk_filtered_trace = fk_trace .* fk_filter_matrix;
    printTime();
    
    % --- Step 3: Inverse 2D FFT ---
    % Return to Time-Space (t-x) domain
    printStep('Inverse FFT after fk filtering');
    % ifftshift reverts the fftshift before the inverse transform
    trace_out = real(ifft2(ifftshift(fk_filtered_trace)));
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