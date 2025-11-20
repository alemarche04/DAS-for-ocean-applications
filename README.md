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
