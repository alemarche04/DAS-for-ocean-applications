function filtered_data = butterworth_bp_filter(data, cutoff_freq, order, sampling_freq)

    cutoff_bp = cutoff_freq/(sampling_freq/2);
    [B, A] = butter(order, cutoff_bp, 'bandpass');

    printStep('Applying Butterworth bandpass filter');
    filtered_data = filtfilt(B, A, data')';
    printTime();

end

function printStep(msg)
    numDots = 60 - length(msg);
    fprintf('%s%s', msg, repmat('.', 1, max(numDots, 3)));
    tic;
end

function printTime()
    fprintf(' Time elapsed: %.3f s\n', toc);
end