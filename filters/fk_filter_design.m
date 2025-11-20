% adapted from: https://github.com/DAS4Whales/DAS4Whales/blob/main/src/das4whales/dsp.py#L290

% design of fk filter
% (default propagation speed: [1450-3400] m/s)

% --- INPUT ---
% trace_shape : [n_channels, n_samples] matrix dimensions
% selected_channels : [start, end, step] list of selected channels
% dx : channel distance [m]
% dt : sampling interval [s]

% --- OPTIONAL PARAMETERS ---
% cs_min : minimum speed for fk bandpass filtering
% cp_min : minimum speed for fk stopband filtering
% cp_max : maximum speed for fk bandpass filtering
% cs_max : maximum speed for fk stopband filtering
% display_filter: if true, plots the filter

% --- OUTPUT ---
% fk_filter_matrix : [space x time] matrix containing the fk filter

function fk_filter_out = fk_filter_design(trace_shape, dx, dt, varargin)

    % validate input and set up optional parameters
    params = parse_inputs(trace_shape, dx, dt, varargin{:});

    cs_min = params.cs_min;
    cp_min = params.cp_min;
    cp_max = params.cp_max;
    cs_max = params.cs_max;
    display_filter = params.display_filter;
    %
    
    nnx = trace_shape(1);
    nns = trace_shape(2);

    % Frequency axis
    if mod(nns, 2) == 0
        freq = double([0:nns/2-1 -nns/2:-1]) / double(nns*dt); % n even
    else
        freq = double([0:(nns-1)/2 -(nns-1)/2:-1]) / double(nns*dt); % n odd
    end
    freq = fftshift(freq);

    % Wavenumber axis
    if mod(nnx, 2) == 0
        knum = double([0:nnx/2-1 -nnx/2:-1]) / double(nnx*dx);   % n even
    else
        knum = double([0:(nnx-1)/2 -(nnx-1)/2:-1]) / double(nnx*dx); % n odd
    end
    knum = fftshift(knum);

    % creates matrix filter
    fprintf('Creating fk filter matrix\n');
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
    fprintf('Created fk filter matrix\n');

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

    valid = @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 0);
    addParameter(p, 'cs_min', 1400, valid);
    addParameter(p, 'cp_min', 1450, valid);
    addParameter(p, 'cp_max', 3400, valid);
    addParameter(p, 'cs_max', 3500, valid);

    valid = @(x) isempty(x) || (islogical(x));
    addParameter(p, 'display_filter', false, valid);

    parse(p, trace_shape, dx, dt, varargin{:});

    results = p.Results;
    end
    %