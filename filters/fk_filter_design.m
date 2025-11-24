function fk_filter_out = fk_filter_design(trace_shape, dx, dt, varargin)
% FK_FILTER_DESIGN Design frequency-wavenumber (f-k) filter for DAS data
%
%   fk_filter_out = FK_FILTER_DESIGN(trace_shape, dx, dt) designs an f-k
%   filter with default propagation speed range [1450-3400] m/s.
%
%   fk_filter_out = FK_FILTER_DESIGN(..., 'Name', Value) specifies optional
%   parameters using name-value pairs.
%
%   Inputs:
%       trace_shape - [1x2] vector [n_channels, n_samples] specifying matrix dimensions
%       dx          - Channel spacing (m)
%       dt          - Sampling interval (s)
%
%   Optional Parameters:
%       'c_range'         - [1x4] vector specifying filter speed range (m/s):
%                           [cs_min, cp_min, cp_max, cs_max] where:
%                           cs_min: minimum speed for stopband filtering
%                           cp_min: minimum speed for bandpass filtering
%                           cp_max: maximum speed for bandpass filtering
%                           cs_max: maximum speed for stopband filtering
%                           Default: [1450, 1450, 3400, 3400]
%       'display_filter'  - Logical flag to plot the filter. Default: false
%
%   Output:
%       fk_filter_out - [space x time] matrix containing the f-k filter
%
%   Example:
%       % Design f-k filter with custom speed range
%       filter = fk_filter_design([1000, 5000], 10, 0.001, ...
%                                 'c_range', [1500, 2000, 3000, 3500], ...
%                                 'display_filter', true);
%
%   Reference:
%       Adapted from: https://github.com/DAS4Whales/DAS4Whales
%
%   See also FFT2, IFFT2

    % validate input and set up optional parameters
    params = parse_inputs(trace_shape, dx, dt, varargin{:});

    c_range = params.c_range;
    display_filter = params.display_filter;
    %

    if isempty(c_range)
        c_range = [1400 1450 3400 3500];
    end
    
    cs_min = c_range(1);
    cp_min = c_range(2);
    cp_max = c_range(3);
    cs_max = c_range(4);

    nnx = trace_shape(1);
    nns = trace_shape(2);

    % Frequency axis
    printStep('Calculating frequency axis');
    if mod(nns, 2) == 0
        freq = double([0:nns/2-1 -nns/2:-1]) / double(nns*dt); % n even
    else
        freq = double([0:(nns-1)/2 -(nns-1)/2:-1]) / double(nns*dt); % n odd
    end
    freq = fftshift(freq);
	printTime();

    % Wavenumber axis
    printStep('Calculating wavenumber axis');
    if mod(nnx, 2) == 0
        knum = double([0:nnx/2-1 -nnx/2:-1]) / double(nnx*dx);   % n even
    else
        knum = double([0:(nnx-1)/2 -(nnx-1)/2:-1]) / double(nnx*dx); % n odd
    end
    knum = fftshift(knum);
	printTime();

    % creates matrix filter
    printStep('Creating fk filter matrix');
    fk_filter_matrix = zeros(length(knum), length(freq));

    % iteration on wavenumbers
    for i = 1:length(knum)
        k = knum(i);

        % transition band
        fs_min = k * cs_min;
        fp_min = k * cp_min;
        fp_max = k * cp_max;
        fs_max = k * cs_max;

        filter_line = ones(1, length(freq));

        % transition band from cs_min to cp_min
        if fs_min ~= fp_min
            mask = (freq >= fs_min) & (freq <= fp_min);
            filter_line(mask) = sin(0.5*pi*(freq(mask) - fs_min)/(fp_min - fs_min));
        end

        % transition band from cp_max to cs_max
        if fs_max ~= fp_max
            mask = (freq >= fp_max) & (freq <= fs_max);
            filter_line(mask) = cos(0.5*pi*(freq(mask) - fp_max)/(fs_max - fp_max));
        end

        % stopband
        filter_line(freq >= fs_max) = 0;
        filter_line(freq < fs_min) = 0;
        
        % fills the filter matrix
        fk_filter_matrix(i,:) = filter_line;
    end

    fk_filter_matrix = fk_filter_matrix + flipud(fk_filter_matrix);
    fk_filter_matrix = fk_filter_matrix + fliplr(fk_filter_matrix);

    fk_filter_trim = fk_filter_matrix(1:nnx, 1:nns);
    fk_filter_out = fk_filter_trim;
    printTime();

    % optional plot
    if display_filter
        figure;
        imagesc(freq, knum, fk_filter_matrix);
        xlabel('f [Hz]'); ylabel('k [m^{-1}]');
        axis xy; colorbar;
        title('f-k filter');
    end

end


% function for input validation
function results = parse_inputs(trace_shape, dx, dt, varargin)
    p = inputParser;

    valid = @(x)validateattributes(x,{'numeric'},{'nonempty'});
    addRequired(p, 'trace_shape', valid);

    valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'scalar'});
    addRequired(p, 'dx', valid);
    addRequired(p, 'dy', valid);

    valid = @(x) isempty(x) || (isnumeric(x) && isvector(x) && all(x >= 0));
    addParameter(p, 'c_range', [1400 1450 3400 3500], valid)

    valid = @(x) isempty(x) || (islogical(x));
    addParameter(p, 'display_filter', false, valid);

    parse(p, trace_shape, dx, dt, varargin{:});

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