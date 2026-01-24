function trace_out = fk_filter_filt(trace_in, fk_filter_matrix)
% Adapted from: https://github.com/DAS4Whales/DAS4Whales

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