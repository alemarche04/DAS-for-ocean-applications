function trace_out = median_filter_2D(data, filter_dimensions)

	parse_inputs(data, filter_dimensions);

	printStep('Applying 2D median filter')
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