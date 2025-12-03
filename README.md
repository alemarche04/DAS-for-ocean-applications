# DAS for Ocean Applications

This repository contains matlab scripts for data analysis of Distributed Acoustic Sensing (DAS) data.

## Overview

Two comprehensive datasets demonstrate the use of submarine telecommunication cables for marine acoustic monitoring using DAS technology in the Arctic waters around Svalbard, Norway.

## Datasets

### 1. DAS4Whale Dataset

**Citation:**
> Léa Bouffaut, & Kittinat Taweesintananon. (2022). DAS4Whale: Svalbard distributed acoustic sensing dataset for baleen whale monitoring (1.0.0) [Data set]. Zenodo. https://doi.org/10.5281/zenodo.5823343

#### System Configuration

- **Cable Location:** Uninett submarine telecommunication cable connecting Longyearbyen to Ny-Ålesund, Svalbard
- **Cable Placement:** 1-2 m into soft sediment
- **Water Depth:** 50-400 m
- **Interrogator:** Alcatel Submarine Networks OptoDAS Interrogator
- **Distance Covered:** First 120 km of fiber

#### Geographic Coverage

The DAS crosses Isfjorden out to the open sea, bypassing the South of Prins Karls Forland. The interrogator is located on shore in Longyearbyen.

#### Technical Specifications

| Parameter | Value |
|-----------|-------|
| Light pulses wavelength | 1500 nm |
| Light pulses duration | 100 μs |
| Channel distance | 4.08 m |
| Number of channels | 3000 |
| Gauge length | 8.16 m |
| Sampling frequency | 645.16 Hz |
| Recording duration | 44 days (June 23 - August 5, 2020) |

#### Data Processing

- **Filter:** 5th order Butterworth bandpass filter [5-75] Hz
- **f-k Filter:** Frequency-Wavenumber fan filter to keep waves with [1450-3400] m/s propagation speed

#### Sample Data

**Whale Vocalization Data:**
- **Date/Time:** 2020-06-27, 05:24:41, channels 10001-15000 (40.8 km-61.2 km)

---

### 2. DAS4Tracking Dataset

**Citation:**
> Rørstadbotnen, Robin Andre; Landrø, Martin, 2023, "Replication data for DAS4Tracking - strain data for localization study", https://doi.org/10.18710/Q8OSON, DataverseNO, V1

#### System Configuration

- **Cables Location:** Two submarine telecommunication cables connecting Longyearbyen and Ny-Ålesund
- **Cable Placement:** 
  - First 5 km: Trenched on land at both ends
  - Inner cable: 248 km sub-sea (buried 0-2 m below seafloor)
  - Outer cable: 252 km sub-sea (buried 0-2 m below seafloor)
- **Water Depth:** 50-400 m
- **Interrogator:** Alcatel Submarine Network OptoDAS interrogator (4 units total: 2 in Ny-Ålesund, 2 in Longyearbyen)
- **Distance Covered:** 260 km per cable (~136 km per interrogator)

#### Technical Specifications

| Parameter | Value |
|-----------|-------|
| Light pulses wavelength | 1550 nm |
| Channel distance | 4.08 m |
| Gauge length | 8.16 m |
| Sampling frequency | 625 Hz (downsampled to 78 Hz for whale calls, 125 Hz for airgun) |
| Recording start | First unit: 2022-06-02 (Ny-Ålesund)<br>Other units: 2022-08-17 & 2022-08-19 |

#### Data Processing

- **Whale Calls:** 5th order Butterworth bandpass filter [5-30] Hz
- **Airgun Data:** 5th order Butterworth bandpass filter [5-45] Hz
- **f-k Filter:** Frequency-Wavenumber fan filter to keep waves with [1450-3400] m/s propagation speed

#### Sample Data

**Whale Vocalizations:**
1. 2022-08-22, 12:27:07 to 12:30:37, channels 9803-24509 (40-100 km, inner cable)
2. 2022-08-22, 11:45:07 to 11:48:37, channels 9803-24509 (40-100 km, inner cable)

**Airgun Data:**
1. 2022-09-06, 17:51:07 to 17:54:37, channels 2450-9191 (10-37.5 km, inner cable)
2. 2022-09-06, 17:51:06 to 17:54:36, channels 2450-9191 (10-37.5 km, outer cable)

## Data Access

- DAS4Whale: Available on Zenodo (DOI: 10.5281/zenodo.5823343)
- DAS4Tracking: Available on DataverseNO (DOI: 10.18710/Q8OSON)

## Contact

For questions about the datasets, please contact the authors through the respective data repositories.



# DAS Analysis Toolbox

MATLAB toolbox for analyzing DAS (Distributed Acoustic Sensing) data, with functions for filtering, visualization, and event detection.

## Table of Contents
- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [Available Functions](#available-functions)
  - [Filtering](#filtering)
  - [Visualization](#visualization)
  - [Correlation Analysis](#correlation-analysis)
  - [Event Detection](#event-detection)
  - [Configuration Manager](#configuration-manager)
- [Examples](#examples)

---

## Installation

1. Clone or download this repository
2. Add the folder to MATLAB path:
   ```matlab
   addpath('path/to/das-toolbox');
   ```
3. Access help for any function: `help function_name`

---

## Basic Usage

```matlab
% Load dataset configuration
cfg = ConfigManager('DAS4Whale_bou22');

% Apply bandpass filter
filtered_data = butterworth_bp_filter(cfg.data.strain, [8 12], 4, cfg.data.sampling_frequency);

% Visualize data
fig = get_time_space_plot(filtered_data, cfg.data.time, cfg.data.distance);
```

---

## Available Functions

### Filtering

#### `butterworth_bp_filter`
Applies a Butterworth bandpass filter to multi-channel data.

**Syntax:**
```matlab
filtered_data = butterworth_bp_filter(data, cutoff_freq, order, sampling_freq)
```

**Parameters:**
- `data` - Data matrix [channels × time]
- `cutoff_freq` - [1×2] vector with cutoff frequencies [low, high] (Hz)
- `order` - Filter order (positive integer)
- `sampling_freq` - Sampling frequency (Hz)

**Output:**
- `filtered_data` - Filtered data matrix [channels × time]

**Example:**
```matlab
fs = 250;
filtered = butterworth_bp_filter(eeg_data, [8 12], 4, fs);
```

---

#### `median_filter_2D`
Applies a 2D median filter to reduce noise in multi-channel data.

**Syntax:**
```matlab
trace_out = median_filter_2D(data, filter_dimensions)
```

**Parameters:**
- `data` - Data matrix [channels × time]
- `filter_dimensions` - [1×2] vector [channel_size, time_size] specifying the median filter kernel dimensions

**Output:**
- `trace_out` - Filtered data matrix [channels × time]

**Example:**
```matlab
% Apply 3x3 median filter to reduce spike noise
filtered = median_filter_2D(strain_data, [3 3]);

% Apply asymmetric filter (5 channels, 3 time samples)
filtered = median_filter_2D(strain_data, [5 3]);
```

---

#### `fk_filter_design`
Designs a frequency-wavenumber (f-k) filter for DAS data.

**Syntax:**
```matlab
fk_filter_out = fk_filter_design(trace_shape, dx, dt)
fk_filter_out = fk_filter_design(..., 'Name', Value)
```

**Parameters:**
- `trace_shape` - [1×2] vector with dimensions [n_channels, n_samples]
- `dx` - Channel spacing (m)
- `dt` - Sampling interval (s)

**Optional Parameters (Name-Value):**
- `'c_range'` - [1×4] vector with speed range [cs_min, cp_min, cp_max, cs_max] (m/s)
  - Default: [1450, 1450, 3400, 3400]
- `'display_filter'` - Boolean flag to display the filter
  - Default: false

**Output:**
- `fk_filter_out` - Filter matrix [space × time]

**Example:**
```matlab
filter = fk_filter_design([1000, 5000], 10, 0.001, ...
                         'c_range', [1500, 2000, 3000, 3500], ...
                         'display_filter', true);
```

**Reference:** Adapted from [DAS4Whales](https://github.com/DAS4Whales/DAS4Whales)

---

#### `fk_filter_filt`
Applies an f-k filter to a data matrix.

**Syntax:**
```matlab
trace_out = fk_filter_filt(trace_in, fk_filter_matrix)
```

**Parameters:**
- `trace_in` - Data matrix [channels × time] in t-x domain
- `fk_filter_matrix` - Filter matrix [space × time] (from `fk_filter_design`)

**Output:**
- `trace_out` - Filtered data matrix [channels × time] in f-x domain

**Example:**
```matlab
fk_filter = fk_filter_design([1000, 5000], 10, 0.001);
filtered_data = fk_filter_filt(raw_data, fk_filter);
```

---

### Visualization

#### `get_time_space_plot`
Generates a time-space (t-x) visualization of strain data.

**Syntax:**
```matlab
fig = get_time_space_plot(data, time, distance)
fig = get_time_space_plot(..., 'Name', Value)
```

**Parameters:**
- `data` - Data matrix [channels × time] (dB scale)
- `time` - Time axis vector (s)
- `distance` - Distance axis vector (km)

**Optional Parameters:**
- `'time_lim'` - Time axis limits [tmin, tmax] (s)
- `'distance_lim'` - Distance axis limits [dmin, dmax] (km)
- `'strain_lim'` - Strain amplitude limits [min, max] (dB)

**Output:**
- `fig` - Figure handle

**Example:**
```matlab
fig = get_time_space_plot(strain_data, time_vector, distance, ...
                         'time_lim', [0 30], 'distance_lim', [4 6]);
```

---

#### `get_strain_waveform`
Plots strain waveform for a single channel.

**Syntax:**
```matlab
fig = get_strain_waveform(data, distance_km, time, channel_position_km)
fig = get_strain_waveform(..., 'Name', Value)
```

**Parameters:**
- `data` - Data matrix [channels × time] (dB scale)
- `distance_km` - Distance axis vector (km)
- `time` - Time axis vector (s)
- `channel_position_km` - Target channel position (km)

**Optional Parameters:**
- `'time_lim'` - Time axis limits [tmin, tmax] (s)
- `'strain_lim'` - Amplitude limits [min, max]

**Output:**
- `fig` - Figure handle

**Example:**
```matlab
fig = get_strain_waveform(strain_data, distance, time_vector, 5.2, ...
                         'time_lim', [10 20]);
```

---

#### `get_spectrogram`
Generates a spectrogram for a single channel.

**Syntax:**
```matlab
fig = get_spectrogram(data, distance_km, sampling_frequency, channel_position_km, nfft, N, window, overlap_pct)
fig = get_spectrogram(..., 'Name', Value)
```

**Parameters:**
- `data` - Data matrix [channels × time] (dB scale)
- `distance_km` - Distance axis vector (km)
- `sampling_frequency` - Sampling frequency (Hz)
- `channel_position_km` - Target channel position (km)
- `nfft` - Number of FFT samples
- `N` - Window length (samples)
- `window` - Spectral window (e.g., hamming(N), hann(N))
- `overlap_pct` - Window overlap percentage (0-100)

**Optional Parameters:**
- `'time_lim'` - Time axis limits [tmin, tmax] (s)
- `'frequency_lim'` - Frequency axis limits [fmin, fmax] (Hz)
- `'strain_lim'` - Amplitude limits [min, max] (dB)

**Output:**
- `fig` - Figure handle

**Example:**
```matlab
fig = get_spectrogram(strain_data, distance, 1000, 5.2, 2048, ...
                     512, hamming(512), 50, 'frequency_lim', [0 50]);
```

---

#### `get_space_frequency_plot`
Generates a space-frequency (f-x) visualization for a time window.

**Syntax:**
```matlab
fig = get_space_frequency_plot(data, distance, sampling_frequency, nfft, time_window, time_interval)
fig = get_space_frequency_plot(..., 'Name', Value)
```

**Parameters:**
- `data` - Data matrix [channels × time]
- `distance` - Distance axis vector (km)
- `sampling_frequency` - Sampling frequency (Hz)
- `nfft` - Number of FFT samples
- `time_window` - Duration of each f-x window (s)
- `time_interval` - Time interval [start, end] (s)

**Optional Parameters:**
- `'frequency_lim'` - Frequency axis limits [fmin, fmax] (Hz)
- `'strain_lim'` - Amplitude limits [min, max] (dB)
- `'get_animation'` - Flag to produce animation (default: false)

**Output:**
- `fig` - Figure handle

**Example:**
```matlab
fig = get_space_frequency_plot(strain_data, distance, 1000, 2048, ...
                              1.0, [0 30], 'frequency_lim', [0 100], ...
                              'get_animation', true);
```

---

### Correlation Analysis

#### `get_correlation_statistics`
Computes and visualizes correlation statistics of strain data.

**Syntax:**
```matlab
fig = get_correlation_statistics(data, sampling_frequency, distance_m, channel_distance_m, ...
    channel_reference_position_km, offset_m, max_lag, time_interval)
```

**Parameters:**
- `data` - Data matrix [channels × time]
- `sampling_frequency` - Sampling frequency (Hz)
- `distance_m` - Distance axis vector (m)
- `channel_distance_m` - Spacing between adjacent channels (m)
- `channel_reference_position_km` - Reference channel position (km)
- `offset_m` - Maximum spatial offset (m)
- `max_lag` - Maximum time lag (s)
- `time_interval` - Time interval [start, end] (s)

**Output:**
- `fig` - Figure handle with correlation statistics

**Example:**
```matlab
fig = get_correlation_statistics(strain_data, 1000, distance, 10, ...
                                5.0, 1000, 0.5, [0 10]);
```

---

#### `get_correlogram`
Generates a correlogram of strain data.

**Syntax:**
```matlab
fig = get_correlogram(data, sampling_frequency, distance_m, channel_reference_position_km, ...
    offset_m, max_lag, time_interval)
```

**Parameters:**
- `data` - Data matrix [channels × time]
- `sampling_frequency` - Sampling frequency (Hz)
- `distance_m` - Distance axis vector (m)
- `channel_reference_position_km` - Reference channel position (km)
- `offset_m` - Maximum spatial offset (m)
- `max_lag` - Maximum time lag (s)
- `time_interval` - Time interval [start, end] (s)

**Output:**
- `fig` - Figure handle with correlogram

**Example:**
```matlab
fig = get_correlogram(strain_data, 1000, distance, 5.0, ...
                     500, 0.2, [10 20]);
```

---

### Event Detection

#### `event_detection`
Detects events in DAS data using normalized energy analysis.

**Syntax:**
```matlab
[events, fig] = event_detection(data, time, distance)
[events, fig] = event_detection(..., 'Name', Value)
```

**Parameters:**
- `data` - Data matrix [channels × time]
- `time` - Time axis vector (s)
- `distance` - Distance axis vector (km)

**Optional Parameters:**
- `'threshold'` - Threshold in standard deviations (default: 5)
- `'min_area'` - Minimum event area in pixels (default: 50)
- `'filter_size'` - Median filter size [time, space] (default: [5 5])
- `'energy_window'` - Energy computation window [time, space] (default: [7 7])
- `'save_csv'` - Flag to save events to CSV (default: false)

**Outputs:**
- `events` - [N × 3] matrix where each row contains:
  - Column 1: Event time (s)
  - Column 2: Event distance (km)
  - Column 3: Event area (pixels)
- `fig` - Figure handle with detection results

**Example:**
```matlab
[events, fig] = event_detection(strain_data, time, distance, ...
                               'threshold', 7, 'min_area', 100, ...
                               'save_csv', true);
```

---

### Configuration Manager

#### `ConfigManager`
Class for centralized configuration management for DAS analysis.

**Syntax:**
```matlab
cfg = ConfigManager(dataset_name)
```

**Parameters:**
- `dataset_name` - Dataset identifier, one of the following:
  - `'DAS4Whale_Bou22'`
  - `'DAS4Tracking_Ror23'`
  - `'DAS4Tracking_airgun_inner'`
  - `'DAS4Tracking_airgun_outer'`
  - `'OOI_Wilcock_2023'`

**Properties:**
- `dataset_name` - String identifier for the dataset
- `data` - Structure containing loaded DAS data
- `params` - Structure containing all analysis parameters

**Main Methods:**

| Method | Description |
|--------|-------------|
| `ConfigManager(dataset_name)` | Constructor - loads data and initializes parameters |
| `initialize_parameters()` | Initialize parameters for data processing |
| `load_data_DAS4Whale()` | Load DAS4Whale dataset |
| `load_data_DAS4Tracking()` | Load DAS4Tracking dataset |
| `load_data_OOI()` | Load OOI dataset |
| `reload()` | Reload both data and configuration from source |
| `reload_params()` | Reload only parameters (keeps data in memory) |

**Example:**
```matlab
% Load BOU22 whale dataset
cfg = ConfigManager('DAS4Whale_Bou22');

% Access data and parameters
filtered_data = butterworth_bp_filter(cfg.data.strain, ...
                                      cfg.params.bpFilter.cutoff_freq, ...
                                      cfg.params.bpFilter.order, ...
                                      cfg.data.sampling_frequency);

% Reload parameters if needed
cfg = cfg.reload_params();
```

---

## Examples

### Complete Analysis Pipeline

```matlab
% 1. Initialize configuration
cfg = ConfigManager('DAS4Whale_bou22');

% 2. Apply bandpass filter
filtered = butterworth_bp_filter(cfg.data.strain, [10 50], 4, cfg.data.sampling_frequency);

% 3. Apply f-k filter
fk_filter = fk_filter_design(size(filtered), 10, 1/cfg.data.sampling_frequency, ...
                             'c_range', [1500, 2000, 3000, 3500]);
filtered = fk_filter_filt(filtered, fk_filter);

% 4. Visualize results
fig1 = get_time_space_plot(filtered, cfg.data.time, cfg.data.distance);
fig2 = get_spectrogram(filtered, cfg.data.distance, cfg.data.sampling_frequency, ...
                       5.0, 2048, 512, hamming(512), 50);

% 5. Detect events
[events, fig3] = event_detection(filtered, cfg.data.time, cfg.data.distance, ...
                                'threshold', 6, 'save_csv', true);
```

### Correlation Analysis

```matlab
cfg = ConfigManager('DAS4Whale_bou22');

% Correlation statistics
fig1 = get_correlation_statistics(cfg.data.strain, cfg.data.sampling_frequency, ...
                                  cfg.data.distance*1000, 10, 5.0, 500, 0.3, [0 20], ...
                                  'correlation_stats');

% Correlogram
fig2 = get_correlogram(cfg.data.strain, cfg.data.sampling_frequency, ...
                       cfg.data.distance*1000, 5.0, 300, 0.2, [10 15]);
```

### Multi-Channel Spectral Analysis

```matlab
cfg = ConfigManager('DAS4Whale_bou22');

% f-x plot with animation
fig = get_space_frequency_plot(cfg.data.strain, cfg.data.distance, ...
                              cfg.data.sampling_frequency, 2048, 2.0, [0 60], ...
                              'frequency_lim', [5 100], ...
                              'get_animation', true);
```

---

## Notes

- All functions support MATLAB help: `help function_name`
- Visualization functions return figure handles for further customization
- f-k filters are adapted from [DAS4Whales](https://github.com/DAS4Whales/DAS4Whales)
- For custom datasets, extend the `ConfigManager` class with new methods

---

## Requirements

- MATLAB R2019b or later
- Signal Processing Toolbox
- Image Processing Toolbox (for `event_detection`)

---

## Authors and License

ELEDIA Research Center - All Rights Reserved