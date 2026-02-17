function fig = get_time_space_plot(data, time, distance, varargin)
% GET_TIME_SPACE_PLOT Generates a 2D visualization of DAS data (t-x plot).
%
%   FIG = GET_TIME_SPACE_PLOT(DATA, TIME, DISTANCE) creates a time-space 
%   (LTT) plot using imagesc. This visualization is standard for DAS data
%   to observe acoustic wave propagation across channels over time.
%
%   Input Arguments:
%       data         - 2D matrix of DAS data [channels x samples].
%       time         - Vector of time samples [s].
%       distance     - Vector of spatial positions [m].
%
%   Optional Parameters (Name-Value Pairs):
%       'subtitle'     - Plot subtitle string (typically time and date)
%       'time_lim'     - 2-element vector [min max] for X-axis limits.
%       'distance_lim' - 2-element vector [min max] for Y-axis limits.
%       'strain_lim'   - 2-element vector [min max] for colorbar limits (clim).
%
%   Output Arguments:
%       fig          - Handle to the generated figure.
%
%   See also: IMAGESC, COLORBAR, CLIM

    % validate input and set up optional parameters
    params = parse_inputs(data, time, distance, varargin{:});
    time_lim = params.time_lim;
    distance_lim = params.distance_lim;
    strain_lim = params.strain_lim;
    %

	% data is plotted in dB scale
	data_dB = 20*log10(abs(data) ./ max(abs(data), [], "all"));
	%

    % plot figure
    fig = figure(Name="Time-Space plot", NumberTitle="off");
    imagesc(time, distance, data_dB);
    axis xy;
    colormap(parula);
    c = colorbar;
    title('Time-Space plot', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('Time (s)', 'FontSize', 12);
    ylabel('Distance (m)', 'FontSize', 12);
    c.Label.String = 'Strain (dB)';
	%
	% apply optional subtitle
	if ~isempty(params.subtitle)
		subtitle(params.subtitle, "FontSize", 12);
	end
    %
    % plot limits configuration
    if ~isempty(time_lim)
    xlim(time_lim);
    end
    if ~isempty(distance_lim)
    ylim(distance_lim);
    end
    if ~isempty(strain_lim)
        clim(strain_lim);
    end
    %
end
% -----------------------------------------------------------------------%

%% INPUT PARSING
function results = parse_inputs(data, time, distance, varargin)
	p = inputParser;
	
	% required parameters
	addRequired(p, 'data', @isnumeric);
	addRequired(p, 'distance', @(x) isnumeric(x) && isvector(x) && all(x>=0));
    addRequired(p, 'time', @(x) isnumeric(x) && isvector(x) && all(x>=0));
	
	% optional parameters
	addParameter(p, 'subtitle', [], @(x) isempty(x) || ischar(x) || isstring(x));
	addParameter(p, 'time_lim', [], @(x) isempty(x) || (isnumeric(x) && isvector(x) && all(x>=0)));
	addParameter(p, 'distance_lim', [], @(x) isempty(x) || (isnumeric(x) && isvector(x) && all(x>=0)));
	addParameter(p, 'strain_lim', [], @(x) isempty(x) || (isnumeric(x) && isvector(x)));
	
	parse(p, data, time, distance, varargin{:});
	results = p.Results;
end