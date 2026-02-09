# DAS Signal Processing Toolset

A comprehensive MATLAB toolkit for Distributed Acoustic Sensing (DAS) signal processing, filtering, and visualization.

## Overview

This toolset provides a complete suite of functions for processing and analyzing DAS (Distributed Acoustic Sensing) data. It includes advanced filtering techniques, frequency-wavenumber (f-k) domain processing, and various visualization tools designed specifically for DAS applications such as seismic monitoring, acoustic event detection, and marine mammal observation.

## Features

- **Zero-phase Butterworth bandpass filtering**
- **Frequency-wavenumber (f-k) domain filtering** for velocity-selective signal isolation
- **2D median filtering** for impulsive noise reduction
- **Comprehensive visualization tools** including:
  - Time-space (t-x) plots
  - Spectrograms (STFT)
  - Spatio-spectral (f-x) plots with animation export
  - Correlograms and correlation statistics
- **Audio export capabilities** for audible signal analysis
- **Cross-correlation analysis** with automated peak detection

## Function Reference

### Filtering Functions

#### `butterworth_bp_filter`

Applies a zero-phase Butterworth bandpass filter to DAS data.

```matlab
filtered_data = butterworth_bp_filter(data, cutoff_freq, order, sampling_freq)
```

**Input Arguments:**
- `data` - 2D matrix of DAS data [channels × samples]
- `cutoff_freq` - Two-element vector `[f_low, f_high]` defining the passband in Hz
- `order` - Filter order (e.g., 3 or 5). Note: filtfilt doubles the effective order
- `sampling_freq` - Sampling frequency of the data in Hz

**Output Arguments:**
- `filtered_data` - The zero-phase filtered signal, returned in the same orientation as the input

**Note:** The function automatically transposes the data for filtfilt and transposes it back to ensure the output matches the input shape. Zero-phase implementation avoids phase distortion, which is critical for maintaining signal timing in DAS applications.

---

#### `fk_filter_design`

Designs a velocity-selective filter in the frequency-wavenumber (f-k) domain.

```matlab
fk_filter_out = fk_filter_design(trace_shape, dx, dt)
fk_filter_out = fk_filter_design(..., 'c_range', [cs_min cp_min cp_max cs_max])
```

**Input Arguments:**
- `trace_shape` - 2-element vector `[nx, ns]` (channels, samples)
- `dx` - Spatial sampling interval (channel spacing) [m]
- `dt` - Temporal sampling interval [s]

**Optional Parameters (Name-Value):**
- `'c_range'` - Velocity bounds [m/s]: `[stop_low, pass_low, pass_high, stop_high]`. Default: `[1400 1450 3400 3500]`
- `'display_filter'` - Logical. If true, plots the f-k filter mask

**Output Arguments:**
- `fk_filter_out` - A 2D matrix of the same size as the input data's FFT, representing the filter response in the f-k domain

**Algorithm:**
The filter creates a tapered window in the frequency-wavenumber space. Since v = f/k, specific velocities correspond to radial lines in the f-k plane. This filter isolates signals within a velocity cone.

**Adapted from:** [DAS4Whales](https://github.com/DAS4Whales/DAS4Whales)

---

#### `fk_filter_filt`

Applies a designed f-k filter to a 2D DAS data matrix.

```matlab
trace_out = fk_filter_filt(trace_in, fk_filter_matrix)
```

**Input Arguments:**
- `trace_in` - 2D matrix of DAS data [channels × samples]
- `fk_filter_matrix` - 2D filter mask (same size as trace_in) designed using `fk_filter_design`

**Output Arguments:**
- `trace_out` - Filtered DAS data in the time-space domain

**Process:**
1. Compute 2D FFT of the input signal
2. Shift zero-frequency components to the center (fftshift)
3. Element-wise multiplication with the f-k mask
4. Inverse shift and Inverse 2D FFT
5. Extract the real part to remove negligible imaginary components

**Note:** The input data and filter matrix must have identical dimensions. This process is computationally intensive for large DAS files.

**Adapted from:** [DAS4Whales](https://github.com/DAS4Whales/DAS4Whales)

---

#### `median_filter_2d`

Applies a two-dimensional median filter for noise reduction.

```matlab
trace_out = median_filter_2d(data, filter_dimensions)
```

**Input Arguments:**
- `data` - 2D matrix of DAS data [channels × samples]
- `filter_dimensions` - A 2-element vector `[m n]` specifying the size of the median filtering window

**Output Arguments:**
- `trace_out` - The filtered data matrix

**Algorithm Details:**
Median filtering is a non-linear operation often used in DAS to remove impulsive noise (spikes) while preserving the sharp transients of seismic or acoustic events. This implementation uses 'symmetric' padding at the boundaries to reduce edge artifacts.

---

### Visualization Functions

#### `get_time_space_plot`

Generates a 2D visualization of DAS data (time-space or t-x plot).

```matlab
fig = get_time_space_plot(data, time, distance)
```

**Input Arguments:**
- `data` - 2D matrix of DAS data [channels × samples]
- `time` - Vector of time samples [s]
- `distance` - Vector of spatial positions [km]

**Optional Parameters (Name-Value Pairs):**
- `'subtitle'` - Plot subtitle string (typically time and date)
- `'time_lim'` - 2-element vector `[min max]` for X-axis limits
- `'distance_lim'` - 2-element vector `[min max]` for Y-axis limits
- `'strain_lim'` - 2-element vector `[min max]` for colorbar limits (clim)

**Output Arguments:**
- `fig` - Handle to the generated figure

---

#### `draw_prop_speed_lines`

Overlays velocity slopes and position markers on a t-x plot.

```matlab
draw_prop_speed_lines(time, prop_speed_km_s, speed_line_points, ...
                      cpa_km, channel_position_km)
```

**Input Arguments:**
- `time` - Time vector used for the X-axis [s]
- `prop_speed_km_s` - Target propagation speed [km/s]
- `speed_line_points` - 2-element vector `[t0, x0]` defining the anchor point for the speed line
- `cpa_km` - Distance coordinate for the CPA marker [km]
- `channel_position_km` - Distance coordinate for the second marker [km]

**Notes:**
The function uses 'w--' (white dashed) for the speed line and hex-coded colors for the horizontal position markers.

---

#### `get_strain_waveform`

Extracts a specific channel, plots its waveform, and exports audio.

```matlab
fig = get_strain_waveform(data, distance_km, time, channel_position_km, ...
                          filename_audio, sampling_frequency_Hz)
```

**Input Arguments:**
- `data` - 2D matrix of DAS data [channels × samples]
- `distance_km` - Vector mapping channel indices to distances [km]
- `time` - Time vector for the X-axis [s]
- `channel_position_km` - The specific spatial location to extract [km]
- `filename_audio` - String/Path for the output .wav file
- `sampling_frequency_Hz` - System sampling rate [Hz]

**Optional Parameters (Name-Value Pairs):**
- `'subtitle'` - Plot subtitle string (typically time and date)
- `'time_lim'` - 2-element vector `[min max]` for X-axis limits (s)
- `'strain_lim'` - 2-element vector `[min max]` for Y-axis limits

**Output Arguments:**
- `fig` - Handle to the generated figure

**Audio Export Note:**
The function scales the signal and applies a 3× resampling factor to the output audio to shift low-frequency signals into a more audible range.

---

#### `get_spectrogram`

Computes and plots the STFT of a specific DAS channel.

```matlab
fig = get_spectrogram(data, distance_km, sampling_frequency, ...
                      channel_position_km, nfft, N, window, overlap_pct)
```

**Input Arguments:**
- `data` - 2D matrix of DAS data [channels × samples]
- `distance_km` - Vector mapping channel indices to distances [km]
- `sampling_frequency` - System sampling rate [Hz]
- `channel_position_km` - The specific spatial location to analyze [km]
- `nfft` - Number of FFT points
- `N` - Segment length (window size in samples)
- `window` - Window coefficients (vector, e.g., `hann(N)`)
- `overlap_pct` - Overlap percentage between segments (0 to 1)

**Optional Parameters (Name-Value Pairs):**
- `'subtitle'` - Plot subtitle string (typically time and date)
- `'time_lim'` - 2-element vector `[min max]` for X-axis limits (s)
- `'frequency_lim'` - 2-element vector `[min max]` for Y-axis limits (Hz)
- `'strain_lim'` - 2-element vector `[min max]` for colorbar limits (dB)

**Output Arguments:**
- `fig` - Handle to the generated figure

**Scaling Note:**
The spectrogram is normalized such that the maximum value is 0 dB:
```
dB = 20 × log10(|S| / max(|S|))
```

---

#### `get_space_frequency_plot`

Generates spatio-spectral (f-x) plots and animations.

```matlab
fig = get_space_frequency_plot(data, distance, sampling_frequency, ...
                               nfft, time_window, time_interval, ...
                               filename_animation)
```

**Input Arguments:**
- `data` - 2D matrix of DAS data [channels × samples]
- `distance` - Vector of spatial coordinates for channels [km]
- `sampling_frequency` - System sampling rate [Hz]
- `nfft` - Number of FFT points for frequency resolution
- `time_window` - Duration of each analysis segment [s]
- `time_interval` - 2-element vector `[start end]` for data selection [s]
- `filename_animation` - String path for the output .avi video file

**Optional Parameters (Name-Value Pairs):**
- `'subtitle'` - Plot subtitle string (typically time and date)
- `'frequency_lim'` - 2-element vector `[min max]` for Frequency axis [Hz]
- `'strain_lim'` - 2-element vector `[min max]` for Colorbar/dB limits
- `'get_animation'` - Logical (true/false) to enable video export

**Output Arguments:**
- `fig` - Handle to the main tiled figure

**Notes:**
- The function uses dB scaling: `20 × log10(|S| / max(|S|))`
- Animation frames are rendered at 3 FPS using 'Motion JPEG AVI' codec

---

### Correlation Analysis Functions

#### `get_correlogram`

Computes and plots spatial cross-correlation (correlogram).

```matlab
fig = get_correlogram(data, sampling_frequency, distance_m, ...
                      channel_reference_position_km, offset_m, ...
                      max_lag, time_interval)
```

**Input Arguments:**
- `data` - 2D matrix of DAS data [channels × samples]
- `sampling_frequency` - System sampling rate [Hz]
- `distance_m` - Vector of spatial coordinates for channels [meters]
- `channel_reference_position_km` - Target position for the reference [km]
- `offset_m` - Maximum distance from reference to correlate [m]
- `max_lag` - Maximum time lag for correlation [s]
- `time_interval` - 2-element vector `[start end]` for signal segment [s]

**Optional Parameters (Name-Value Pairs):**
- `'subtitle'` - Plot subtitle string (typically time and date)

**Output Arguments:**
- `fig` - Handle to the generated figure

**Visualization:**
Uses a 'Red-Blue' colormap where white typically represents zero correlation, emphasizing phase alignment.

---

#### `get_correlation_statistics`

Quantifies cross-correlation peaks across the array.

```matlab
[stats, fig] = get_correlation_statistics(data, sampling_frequency, ...
                                          distance_m, channel_distance_m, ...
                                          channel_reference_position_km, ...
                                          offset_m, max_lag, time_interval, ...
                                          filename_xcorr_table)
```

**Input Arguments:**
- `data` - 2D matrix of DAS data [channels × samples]
- `sampling_frequency` - System sampling rate [Hz]
- `distance_m` - Vector of spatial coordinates for channels [m]
- `channel_distance_m` - Nominal spacing between channels [m]
- `channel_reference_position_km` - Target position for the reference [km]
- `offset_m` - Maximum distance from reference to analyze [m]
- `max_lag` - Maximum time lag for correlation [s]
- `time_interval` - 2-element vector `[start end]` for data segment [s]
- `filename_xcorr_table` - Filename (string) for the output CSV table

**Output Arguments:**
- `correlation_statistics` - Matrix `[Offset, Peak Value, Time Lag]`
- `fig` - Handle to the tiled layout figure

**Notes:**
- The function uses an 'offset_step' of 2, skipping every other channel to optimize processing and visualization
- Red vertical lines in the plots indicate the identified peak lag

---

## Data Format Requirements

All functions expect DAS data in the following format:

- **Matrix orientation:** `[channels × samples]`
  - Rows represent spatial channels (fiber length)
  - Columns represent temporal samples
- **Distance vectors:** Can be provided in meters or kilometers (check function documentation)
- **Time vectors:** Typically in seconds
- **Sampling parameters:**
  - `fs` or `sampling_frequency`: Temporal sampling rate [Hz]
  - `dx`: Spatial channel spacing [m]
  - `dt`: Temporal sampling interval [s]

---

## Performance Considerations

- **f-k filtering** is computationally intensive for large datasets. Consider processing data in smaller segments or using parallel processing
- **Median filtering** with large window sizes can be slow; optimize `filter_dimensions` based on noise characteristics
- **Animation export** requires significant disk I/O; ensure adequate storage space
- For very large files, consider downsampling in time or space before visualization

---

## Dependencies

- MATLAB R2019b or later (recommended)
- Signal Processing Toolbox
- Image Processing Toolbox

---

## Acknowledgments

The f-k filtering implementation is adapted from the [DAS4Whales](https://github.com/DAS4Whales/DAS4Whales) project.

---

## Contributing

Contributions, bug reports, and feature requests are welcome. Please submit issues or pull requests through the repository.

---

## Contact

For questions or support, please contact alessia.marchese@eledia.org.

---

## Citation

If you use this toolset in your research, please cite:

```
MARCHESE Alessia, ELEDIA ETRP
ELEDIA Research Center (ELEDIA@UniGE - University of Genova)
```