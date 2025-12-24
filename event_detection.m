function [events, fig] = event_detection(data, time, distance, varargin)
% EVENT_DETECTION Detect events in DAS data using normalized energy analysis
%
%   [events, fig] = EVENT_DETECTION(data, time, distance) detects events 
%   in DAS strain data by analyzing normalized energy patterns and applying 
%   threshold-based detection with morphological filtering.
%
%   [events, fig] = EVENT_DETECTION(..., 'Name', Value) specifies optional
%   parameters using name-value pairs.
%
%   Inputs:
%       data     - [channels x time] data matrix
%       time     - Time axis vector (s)
%       distance - Distance axis vector (km)
%
%   Optional Parameters:
%       'threshold'      - Detection threshold in standard deviations. 
%                          Default: 3
%       'min_area'       - Minimum event area in pixels. Default: 50
%       'filter_size'    - [1x2] median filter kernel size [time, space]. 
%                          Default: [3 3]
%       'energy_window'  - [1x2] energy computation window size [time, space]. 
%                          Default: [5 5]
%       'save_csv'       - Logical flag to save events to CSV file. 
%                          Default: false
%
%   Outputs:
%       events - [N x 3] matrix where each row contains:
%                Column 1: Event time (s)
%                Column 2: Event distance (km)
%                Column 3: Event area (pixels)
%       fig    - Figure handle showing detection results
%
%   Example:
%       % Detect events with custom threshold and save to CSV
%       [events, fig] = event_detection(strain_data, time, distance, ...
%                                      'threshold', 7, 'min_area', 100, ...
%                                      'save_csv', true, 'csv_filename', 'my_events.csv');
%
%   See also MEDFILT2, REGIONPROPS, BWLABEL

    % parse input parameters
    params = parse_inputs(data, time, distance, varargin{:});
    
    threshold = params.threshold;
    min_area = params.min_area;
    filter_size = params.filter_size;
    energy_window = params.energy_window;
    save_csv = params.save_csv;
    
    % apply 2D median filter to remove outliers and spikes
    % each pixel is replaced by the median of its neighbors
    printStep('Computing 2D median filter');
    data_filt = medfilt2(data, filter_size);
    printTime();
    
    % compute local energy by averaging squared values in a moving window
    % this highlights regions with high signal amplitude
    printStep('Computing local energy');
    data_single = single(data_filt.^2);
    energy_kernel = ones(energy_window) / prod(energy_window);
    energy = imfilter(data_single, energy_kernel, 'replicate');
    printTime();
    
    % convert energy to z-scores (number of standard deviations from mean)
    % this allows using a universal threshold regardless of data scale
    printStep('Converting energy to z-scores');
    energy_mean = mean(energy(:));
    energy_std = std(energy(:));
    energy_norm = (energy - energy_mean) / energy_std;
    printTime();
    
    % create binary mask: 1 where energy exceeds threshold, 0 elsewhere
    % pixels above threshold are potential event locations
    event_mask = energy_norm > threshold;
    
    % Group adjacent pixels into distinct events
    % Each connected region gets a unique label (1, 2, 3, ...)
    events_labeled = bwlabel(event_mask);
    
    % Extract properties of each detected event:
    % - WeightedCentroid: center position weighted by energy intensity
    % - Area: number of pixels occupied by the event
    event_properties = regionprops(events_labeled, energy_norm, ...
                                   'WeightedCentroid', 'Area');
    
    % remove small events that are likely noise
    % keep only events with area larger than minimum threshold
    valid_events = [event_properties.Area] > min_area;
    event_properties = event_properties(valid_events);
    
    % handle case with no events detected
    if isempty(event_properties)
        events = [];
        fig = [];
        warning('No events detected with current parameters');
        return;
    end
    
    % get event coordinates (optimized with vectorized operations)
    % centroid(1) = column index (time)
    % centroid(2) = row index (distance/channel)
    centroids = vertcat(event_properties.WeightedCentroid);
    time_idx = round(centroids(:,1));
    dist_idx = round(centroids(:,2));
    
    % clamp indices to avoid out of bounds
    time_idx = max(1, min(time_idx, length(time)));
    dist_idx = max(1, min(dist_idx, length(distance)));
    
    % build events matrix
    events = [time(time_idx)', distance(dist_idx)', [event_properties.Area]'];
    
    % save to CSV if requested
    if save_csv
        events_table = array2table(events, ...
            'VariableNames', {'Time_s', 'Distance_km', 'Area_pixels'});

		try
        	eventDetection = evalin('caller', 'eventDetection');
    		csv_filename = eventDetection.filename_csv;
    		writetable(events_table, csv_filename);
    	catch
        	warning('Unable to find name for event detection file: used default file name events.csv');
			csv_filename = 'events.csv';
			writetable(events_table, csv_filename);
		end
        fprintf('Events saved to: %s\n', csv_filename);
    end
    
    % visualization
    fig = figure;
    imagesc(time, distance, data);
    colormap('sky');
    colorbar;
    hold on;
    
    % plot detected events
    scatter(events(:,1), events(:,2), 50, 'b', 'filled', 'MarkerEdgeColor', 'w');
    axis xy;
    xlabel('Time (s)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Distance (km)', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('Detected Events (n=%d, threshold=%.1f\\sigma)', ...
                  size(events, 1), threshold), ...
          'FontSize', 14, 'FontWeight', 'bold');
    legend('Events', 'Location', 'best');
    grid on;
    
end

% validates and parses input arguments
function results = parse_inputs(data, time, distance, varargin)
    
    p = inputParser;
    
    % Required parameters
    valid = @(x)validateattributes(x,{'numeric'},{'nonempty'});
    addRequired(p, 'data', valid);
    
    valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'vector'});
    addRequired(p, 'time', valid);
    
    valid = @(x)validateattributes(x,{'numeric'},{'nonempty', 'nonnegative', 'vector'});
    addRequired(p, 'distance', valid);
    
    % Optional parameters
    valid = @(x) isnumeric(x) && isscalar(x) && x > 0;
    addParameter(p, 'threshold', 3, valid);
    
    valid = @(x) isnumeric(x) && isscalar(x) && x > 0;
    addParameter(p, 'min_area', 50, valid);
    
    valid = @(x) isnumeric(x) && isvector(x) && length(x) == 2 && all(x > 0);
    addParameter(p, 'filter_size', [3 3], valid);
    
    valid = @(x) isnumeric(x) && isvector(x) && length(x) == 2 && all(x > 0);
    addParameter(p, 'energy_window', [5 5], valid);
    
    valid = @(x) islogical(x) || (isnumeric(x) && (x == 0 || x == 1));
    addParameter(p, 'save_csv', false, valid);
    
    % Parse inputs
    parse(p, data, time, distance, varargin{:});
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