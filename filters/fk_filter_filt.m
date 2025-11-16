function trace_out = fk_filter_filt(trace_in, fk_filter_matrix)

% adapted from: https://github.com/DAS4Whales/DAS4Whales/blob/main/src/das4whales/dsp.py#L1016

% applies fk filter to data matrix

% --- INPUT ---
% trace_in : [channels x time] data matrix (tx domain)
% fk_filter_matrix : [space x time] filter matrix

% --- OUTPUT ---
% trace_out : [channels x time] filtered data matrix (fx domain)

    trace = trace_in;

    % fk spectrum (2D fft)
    fprintf('Calculating fk spectrum (2D FFT)\n');
    fk_trace = fftshift(fft2(trace));

    % applies filter
    fprintf('Applying fk filter\n');
    fk_filtered_trace = fk_trace .* fk_filter_matrix;

    % back to tx domain
    fprintf('Inverse FFT after fk filtering\n');
    trace_out = real(ifft2(ifftshift(fk_filtered_trace)));
end