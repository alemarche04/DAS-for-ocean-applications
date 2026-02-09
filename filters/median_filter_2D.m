function trace_out = median_filter_2D(data, filter_dimensions)
% MEDIAN_FILTER_2D Applies a two-dimensional median filter for noise reduction.
%
%   TRACE_OUT = MEDIAN_FILTER_2D(DATA, FILTER_DIMENSIONS) performs 2D median
%   filtering on the input matrix DATA using a neighborhood specified by 
%   FILTER_DIMENSIONS (e.g., [3 3]).
%
%   Input Arguments:
%       data              - 2D input matrix (typically [channels x samples]).
%       filter_dimensions - A 2-element vector [m n] specifying the size of 
%                           the median filtering window.
%
%   Output Arguments:
%       trace_out         - The filtered data matrix.
%
%   Algorithm Details:
%       Median filtering is a non-linear operation often used in DAS to remove
%       impulsive noise (spikes) while preserving the sharp transients of
%       seismic or acoustic events. This implementation uses 'symmetric' 
%       padding at the boundaries to reduce edge artifacts.
%
%   See also: MEDFILT2, PARSE_INPUTS, FK_FILTER_FILT

	% Validate input arguments
	parse_inputs(data, filter_dimensions);
	
	% Log processing step
	printStep('Applying 2D median filter')
    
	% Execute filtering with symmetric boundary padding
	trace_out = medfilt2(data, filter_dimensions, 'symmetric');
	
	% Report execution time
	printTime();
end

% -----------------------------------------------------------------------%
%% INPUT VALIDATION
function results = parse_inputs(data, filter_dimensions)
% PARSE_INPUTS Internal helper to validate data types and dimensions.
	p = inputParser;
	
	% Data must be a non-empty numeric matrix
	validData = @(x) validateattributes(x, {'numeric'}, {'nonempty'});
	addRequired(p, 'data', validData);
	
	% Dimensions must be a positive 2-element numeric vector
	validDims = @(x) validateattributes(x, {'numeric'}, {'positive', 'vector', 'numel', 2});
	addRequired(p, 'filter_dimensions', validDims);
	
	parse(p, data, filter_dimensions);
	results = p.Results;
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