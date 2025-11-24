function trace_out = fk_filter_filt(trace_in, fk_filter_matrix)
% FK_FILTER_FILT Apply frequency-wavenumber filter to data matrix
%
%   trace_out = FK_FILTER_FILT(trace_in, fk_filter_matrix) applies an f-k
%   filter to the input data in the time-space domain.
%
%   Inputs:
%       trace_in			- [channels x time] data matrix in t-x domain
%       fk_filter_matrix	- [space x time] filter matrix (from FK_FILTER_DESIGN)
%
%   Output:
%       trace_out	- [channels x time] filtered data matrix in f-x domain
%
%   Example:
%       % Design and apply f-k filter
%       fk_filter = fk_filter_design([1000, 5000], 10, 0.001);
%       filtered_data = fk_filter_filt(raw_data, fk_filter);
%
%   Reference:
%       Adapted from: https://github.com/DAS4Whales/DAS4Whales
%
%   See also FK_FILTER_DESIGN, FFT2, IFFT2

    trace = trace_in;

    % fk spectrum (2D fft)
    printStep('Calculating fk spectrum (2D FFT)');
    fk_trace = fftshift(fft2(trace));
    printTime()

    % applies filter
    printStep('Applying fk filter');
    fk_filtered_trace = fk_trace .* fk_filter_matrix;
    printTime()

    % back to tx domain
    printStep('Inverse FFT after fk filtering');
    trace_out = real(ifft2(ifftshift(fk_filtered_trace)));
    printTime()
end

function printStep(msg)
    numDots = 60 - length(msg);
    fprintf('%s%s', msg, repmat('.', 1, max(numDots, 3)));
    tic;
end

function printTime()
    fprintf(' Time elapsed: %.3f s\n', toc);
end