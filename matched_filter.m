function output = matched_filter(data, filename)

	% load and prepare template
    [template, fs] = audioread(filename);
    
	% if stereo use only the first channel
    if size(template, 2) > 1
        template = template(:, 1);
    end
    
	% normalize template and create matched filter
    template = template / max(abs(template));
    h = flipud(conj(template));
    
	% preallocate output matrix
    [n_channels, n_samples] = size(data);
    output = zeros(n_channels, n_samples);

	% log processing step and start timer
    printStep('Applying matched filter');

	% process each channel with fftfilt (same result as conv but optimized)
	for i = 1:n_channels
        conv_result = fftfilt(h, data(i, :));
        output(i, :) = conv_result(1:n_samples);
	end

	% output elapsed time
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