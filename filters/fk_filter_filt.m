function trace_out = fk_filter_filt(trace_in, fk_filter_matrix)
% FK_FILTER_FILT Apply frequency-wavenumber filter to data matrix
%
%   trace_out = FK_FILTER_FILT(trace_in, fk_filter_matrix) applies an f-k
%   filter to the input data in the time-space domain.
%
%   Inputs:
%       trace_in         - [channels x time] data matrix in t-x domain
%       fk_filter_matrix - [space x time] filter matrix (from FK_FILTER_DESIGN)
%
%   Output:
%       trace_out - [channels x time] filtered data matrix in f-x domain
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
    fprintf('\nCalculating fk spectrum (2D FFT)...\n');
    tic
    fk_trace = fftshift(fft2(trace));
    toc

    % applies filter
    fprintf('\nApplying fk filter...\n');
    tic
    fk_filtered_trace = fk_trace .* fk_filter_matrix;
    toc

    % back to tx domain
    fprintf('\nInverse FFT after fk filtering...\n');
    tic
    trace_out = real(ifft2(ifftshift(fk_filtered_trace)));
    toc
end