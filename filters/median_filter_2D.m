function trace_out = median_filter_2D(data, filter_dimensions)
% MEDIAN_FILTER_2D Apply 2D median filter to data matrix
%
%   trace_out = MEDIAN_FILTER_2D(data, filter_dimensions) applies a 2D 
%   median filter to reduce noise in multi-channel time-series data.
%
%   Inputs:
%       data              - [channels x time] data matrix
%       filter_dimensions - [1x2] vector [channel_size, time_size] specifying 
%                           the median filter kernel dimensions
%
%   Output:
%       trace_out - [channels x time] filtered data matrix
%
%   Example:
%       % Apply 3x3 median filter to reduce spike noise
%       filtered = median_filter_2D(strain_data, [3 3]);
%
%       % Apply asymmetric filter (5 channels, 3 time samples)
%       filtered = median_filter_2D(strain_data, [5 3]);
%
%   See also MEDFILT2, MEDIAN_FILTER_1D

	parse_inputs(data, filter_dimensions);

	printStep("Applying 2D median filter")
	trace_out = medfilt2(data, filter_dimensions, 'symmetric');
	printTime();
end

function results = parse_inputs(data, filter_dimensions)
	p = inputParser;
	
	valid = @(x)validateattributes(x,{'numeric'},{'nonempty'});
	addRequired(p, 'data', valid);
	
	valid = @(x)validateattributes(x,{'numeric'},{'positive', 'vector'});
	addRequired(p, 'filter_dimensions', valid);
	
	parse(p, data, filter_dimensions);
	
	results = p.Results;
end

function printStep(msg)
    numDots = 60 - length(msg);
    fprintf('%s%s', msg, repmat('.', 1, max(numDots, 3)));
    tic;
end

function printTime()
    fprintf(' Time elapsed: %.3f s\n', toc);
end