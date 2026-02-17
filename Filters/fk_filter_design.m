function fk_filter_out = fk_filter_design(trace_shape, dx, dt, varargin)
% FK_FILTER_DESIGN Designs a velocity-selective filter in the f-k domain.
%
%   FK_FILTER_OUT = FK_FILTER_DESIGN(TRACE_SHAPE, DX, DT) creates an f-k mask
%   based on default velocity ranges (1400-3500 m/s).
%
%   FK_FILTER_OUT = FK_FILTER_DESIGN(..., 'c_range', [cs_min cp_min cp_max cs_max])
%   defines the velocity passband and transition zones.
%
%   Input Arguments:
%       trace_shape    - 2-element vector [nx, ns] (channels, samples).
%       dx             - Spatial sampling interval (channel spacing) [m].
%       dt             - Temporal sampling interval [s].
%
%   Optional Parameters (Name-Value):
%       'c_range'      - Velocity bounds [m/s]: [stop_low, pass_low, pass_high, stop_high].
%                        Default: [1400 1450 3400 3500].
%       'display_filter' - Logical. If true, plots the f-k filter mask.
%
%   Output Arguments:
%       fk_filter_out  - A 2D matrix of the same size as the input data's FFT,
%                        representing the filter response in the f-k domain.
%
%   Algorithm:
%       The filter creates a tapered window in the frequency-wavenumber space.
%       Since v = f/k, specific velocities correspond to radial lines in 
%       the f-k plane. This filter isolates signals within a velocity cone.
%
%   Example:
%       % Design a filter for water-borne signals (approx. 1500 m/s)
%       mask = fk_filter_design([1000 5000], 2.0, 0.001, 'c_range', [1400 1480 1520 1600]);
%
%   Adapted from: 
%       https://github.com/DAS4Whales/DAS4Whales 
%
%   See also: FFT2, FFTSHIFT, IMAGESC

    % Validate input and set up parameters
    params = parse_inputs(trace_shape, dx, dt, varargin{:});
    c_range = params.c_range;
    display_filter = params.display_filter;
    
    cs_min = c_range(1); % Stopband min velocity
    cp_min = c_range(2); % Passband min velocity
    cp_max = c_range(3); % Passband max velocity
    cs_max = c_range(4); % Stopband max velocity
    
    nnx = trace_shape(1);
    nns = trace_shape(2);

    % --- Frequency Axis Calculation ---
    printStep('Calculating frequency axis');
    if mod(nns, 2) == 0
        freq = double([0:nns/2-1 -nns/2:-1]) / double(nns*dt);
    else
        freq = double([0:(nns-1)/2 -(nns-1)/2:-1]) / double(nns*dt);
    end
    freq = fftshift(freq);
    printTime();

    % --- Wavenumber Axis Calculation ---
    printStep('Calculating wavenumber axis');
    if mod(nnx, 2) == 0
        knum = double([0:nnx/2-1 -nnx/2:-1]) / double(nnx*dx);
    else
        knum = double([0:(nnx-1)/2 -(nnx-1)/2:-1]) / double(nnx*dx);
    end
    knum = fftshift(knum);
    printTime();

    % --- Filter Matrix Generation ---
    % radial velocity filtering: f = v * k
    
    printStep('Creating fk filter matrix');
    fk_filter_matrix = zeros(length(knum), length(freq));
    
    for i = 1:length(knum)
        k = knum(i);
        % Map velocity bounds to frequency bounds for current wavenumber k
        fs_min = k * cs_min;
        fp_min = k * cp_min;
        fp_max = k * cp_max;
        fs_max = k * cs_max;
        
        filter_line = ones(1, length(freq));
        
        % Transition band: cs_min to cp_min (Sine taper)
        if fs_min ~= fp_min
            mask = (freq >= fs_min) & (freq <= fp_min);
            filter_line(mask) = sin(0.5*pi*(freq(mask) - fs_min)/(fp_min - fs_min));
        end
        
        % Transition band: cp_max to cs_max (Cosine taper)
        if fs_max ~= fp_max
            mask = (freq >= fp_max) & (freq <= fs_max);
            filter_line(mask) = cos(0.5*pi*(freq(mask) - fp_max)/(fs_max - fp_max));
        end
        
        % Apply stopbands
        filter_line(freq >= fs_max) = 0;
        filter_line(freq < fs_min) = 0;
        
        fk_filter_matrix(i,:) = filter_line;
    end

    % Symmetrize filter to handle all four quadrants of the f-k plane
    fk_filter_matrix = fk_filter_matrix + flipud(fk_filter_matrix);
    fk_filter_matrix = fk_filter_matrix + fliplr(fk_filter_matrix);
    
    % Trim to original dimensions and output
    fk_filter_out = fk_filter_matrix(1:nnx, 1:nns);
    printTime();

    % Visualization
    if display_filter
        figure('Name', 'F-K Filter Mask');
        imagesc(freq, knum, fk_filter_matrix);
        xlabel('Frequency (f) [Hz]'); ylabel('Wavenumber (k) [m^{-1}]');
        axis xy; colorbar; colormap('jet');
        title(sprintf('F-K Filter Mask (V range: %.1f - %.1f m/s)', cp_min, cp_max));
    end
end

% -----------------------------------------------------------------------%
%% INPUT PARSING
function results = parse_inputs(trace_shape, dx, dt, varargin)
    p = inputParser;
    % Required
    addRequired(p, 'trace_shape', @(x) validateattributes(x, {'numeric'}, {'vector', 'numel', 2}));
    addRequired(p, 'dx', @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive'}));
    addRequired(p, 'dt', @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive'}));
    
    % Optional parameters
    addParameter(p, 'c_range', [1400 1450 3400 3500], @(x) isnumeric(x) && numel(x)==4);
    addParameter(p, 'display_filter', false, @islogical);
    
    parse(p, trace_shape, dx, dt, varargin{:});
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