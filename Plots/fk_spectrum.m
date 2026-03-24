function fk_spectrum(trace, channel_spacing, sampling_interval, varargin)
% FK_SPECTRUM compute and plot FK spectrum of strain matrix.
%
%   FK_SPECTRUM(TRACE, CHANNEL_SPACING_SAMPLING_INTERVAL) computes FK 
%	spectrum with 2D fft tranform then plots it.
% 
%   Input Arguments:
%       trace               - 2D matrix of DAS data [channels x samples].
%       channel_spacing     - Distance between two adjacent channels [m].
%       sampling_interval   - Sampling interval (1/f) [s].
%
%   Optional Parameters (Name-Value Pairs):
%       'subtitle'          - Plot subtitle string (typically time and date)
%       'frequency_lim'     - 2-element vector [min max] for X-axis limits.
%       'wavenumber_lim'    - 2-element vector [min max] for Y-axis limits.
%       'dB_lim'            - 2-element vector [min max] for colorbar limits (clim).
%
%   See also: FFT2, FFTSHIFT

	params = parse_inputs(trace, channel_spacing, sampling_interval, varargin{:});

	[Nx, Nt] = size(trace);

	% Frequency axis
    printStep('Calculating frequency axis');
	if mod(Nt, 2) == 0
        f = (-Nt/2 : Nt/2-1) * (1 / (Nt*sampling_interval)); %[Hz]
    else
        f = (-(Nt-1)/2 : (Nt-1)/2) * (1 / (Nt*sampling_interval)); %[Hz]
    end
    printTime();

	% Wavenumber axis
    printStep('Calculating wavenumber axis');
	if mod(Nx, 2) == 0
        k = (-Nx/2 : Nx/2-1) * (1 / (Nx*channel_spacing)); % [1/m]
    else
        k = (-(Nx-1)/2 : (Nx-1)/2) * (1 / (Nx*channel_spacing)); % [1/m]
    end
    printTime();
	
	% 2D fft
    printStep('Calculating 2D FFT');
	FK = fftshift(fft2(trace));
    printTime();

	% Plot
	figure;
	imagesc(f, k, 20*log10(abs(FK)));
	colorbar;
	xlabel('Frequency [Hz]');
	ylabel('Wavenumber [1/m]');
	title('F-K Spectrum (dB)');
	axis xy;
	colormap jet;

	% apply optional subtitle
	if ~isempty(params.subtitle)
		subtitle(params.subtitle, "FontSize", 12);
	end
    %

	% plot limits configuration
    if ~isempty(params.frequency_lim)
    xlim(params.frequency_lim);
    end
    if ~isempty(params.wavenumber_lim)
    ylim(params.wavenumber_lim);
    end
    if ~isempty(params.dB_lim)
        clim(params.dB_lim);
    end
    %

end

%% INPUT PARSING
function results = parse_inputs(trace, channel_spacing, sampling_interval, varargin)
    p = inputParser;

	% required parameters
    addRequired(p, 'trace', @isnumeric);
    addRequired(p, 'channel_spacing', @(x) isnumeric(x) && isscalar(x) && x>=0);
    addRequired(p, 'sampling_interval', @(x) isnumeric(x) && isscalar(x) && x>=0);
    
	% optional parameters
	addParameter(p, 'subtitle', [], @(x) isempty(x) || ischar(x) || isstring(x));
    addParameter(p, 'frequency_lim', [], @isnumeric);
    addParameter(p, 'wavenumber_lim', [], @isnumeric);
	addParameter(p, 'dB_lim', [], @isnumeric);
    
    parse(p, trace, channel_spacing, sampling_interval, varargin{:});
    results = p.Results;
end

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