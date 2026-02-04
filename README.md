
# When the Brightest Is Not the Best (raw data + analysis code)

This repository contains raw behavioural data and MATLAB code to reproduce the main analyses and figures for the project.

---

## Contents

* [Repository structure](#repository-structure)
* [Requirements](#requirements)
* [Quick start](#quick-start)
* [Raw data format](#raw-data-format)
* [Data files in `data/`](#data-files-expected-in-data)
* [Code overview (file-by-file)](#code-overview-file-by-file)
* [Outputs](#outputs)
* [Notes and common pitfalls](#notes-and-common-pitfalls)
* [License / citation](#license--citation)
* [Contact](#contact)

---

## Repository structure

Expected layout (paths are relative to the repository root):

```
.
├── main.m
├── analysis_dprimeANDC.m
├── fig2ab.m
├── fig4_5_dprime_C.m
├── set_figParameters.m
├── spectralvectortoMB_400to700nm.m
├── ticklengthcm.m
│
├── data/
│   ├── fig_params.mat
│   ├── separated_idx.mat
│   ├── dprime_human.mat
│   ├── dprime_models.mat
│   ├── material.mat
│   ├── sunlight.spd
│   ├── skylight.spd
│   ├── ill_ref_change_material_idx.mat
│   └── lms_400to700.mat
│
└── rawdata/
    ├── AKH/
    │   ├── AKH_1-1.mat
    │   ├── AKH_1-2.mat
    │   └── ...
    ├── JH/
    └── ...
```

---

## Requirements

* MATLAB (tested with scripts using `exportgraphics`, so **R2020a+** is recommended)
* Statistics functions: `norminv` (used to compute *d′* and criterion)
* Psychtoolbox3 (http://psychtoolbox.org/)
  * You can replace it with MATLAB's interpolation (the figures only use it for smoothing/plotting SPDs).

---

## Quick start

From the repository root in MATLAB:


```matlab
main % Simply run main.m
```
OR

```matlab
% 1) Create / update figure style parameters
set_figParameters

% 2) Compute human SDT metrics from rawdata (optional if dprime_human.mat is already provided)
analysis_dprimeANDC

% 3) Generate figures
fig2ab
fig4_5_dprime_C
```

Figures are written to:

```
./figs/
```

---

## Raw data format

### File naming and location

The human behavioural data are stored per observer, session, and block:

```
rawdata/<observer>/<observer>_<session>-<block>.mat
```

Example:

```
rawdata/AKH/AKH_1-1.mat
```

### Variables inside each raw-data `.mat` file

Each raw-data file is expected to contain **exactly these variables** (this is what `analysis_dprimeANDC.m` loads):

| Variable   |           Type |                              Size (per block) | Meaning                                                                                          |
| ---------- | -------------: | --------------------------------------------: | ------------------------------------------------------------------------------------------------ |
| `response` | numeric vector |                          `trialsPerBlock × 1` | Participant response code. Convention used by analysis: `1 = "RefChange"` and `2 = "IllChange"`. |
| `correct`  | numeric vector |                          `trialsPerBlock × 1` | Correctness per trial (`1 = correct`, `0 = incorrect`).                                          |
| `stimList` |         struct | fields are vectors of length `trialsPerBlock` | Trial metadata (condition/stimulus/trial type).                                                  |

`stimList` must contain the following fields:

| `stimList` field      | Type           | Meaning                                                                                                         |
| --------------------- | -------------- | --------------------------------------------------------------------------------------------------------------- |
| `stimList.condition`  | numeric vector | Condition index (1: sphere-matte, 2: sphere-low, 3: sphere-mid, 4: phase_scrambled-low, 5: phase_scrambled-mid).                                                                                          |
| `stimList.stimn`      | numeric vector | Stimulus index (1–100). Used to look up alignment/separation via `data/separated_idx.mat`.                      |
| `stimList.changeType` | numeric vector | Ground-truth trial type: `1 = "RefChange"` (noise) and `2 = "IllChange"` (signal). |


## Data files in `data/`

Some scripts expect additional supporting files in `./data/`. These are not created automatically unless noted.

| File                              | Produced by             | Used by                           | Purpose                                                                          |
| --------------------------------- | ----------------------- | --------------------------------- | -------------------------------------------------------------------------------- |
| `fig_params.mat`                  | `set_figParameters.m`   | `fig2ab.m`, `fig4_5_dprime_C.m`   | Shared figure size/font settings.         |
| `separated_idx.mat`               | (provided)              | `analysis_dprimeANDC.m`           | Defines which `stimn` belong to aligned vs separated conditions.                 |
| `dprime_human.mat`                | `analysis_dprimeANDC.m` | `fig4_5_dprime_C.m`               | Human SDT results (`dprime` and criterion `C`).                                  |
| `dprime_models.mat`               | (provided)              | `fig4_5_dprime_C.m`               | Model SDT results (expected structure described in that script).                 |
| `material.mat`                    | (provided)              | `fig2ab.m`                        | Reflectance spectra (used to compute chromatic directions).                      |
| `sunlight.spd`, `skylight.spd`    | (provided)              | `fig2ab.m`                        | Illuminant SPDs as 2-column text files: wavelength (nm), energy.                 |
| `ill_ref_change_material_idx.mat` | (provided)              | `fig2ab.m`                        | Index pairs defining reflectance-change and illuminant-change comparisons.       |
| `lms_400to700.mat`                | (provided)              | `spectralvectortoMB_400to700nm.m` | LMS sensitivities sampled from 400–700 nm (used for MacLeod–Boynton conversion). |

---

## Code overview (file-by-file)

### `main.m`

A convenience "run everything" entry point.

It currently calls:

```matlab
analysis_dprimeANDC
fig2ab
fig4_5_dprime_Cd
```

⚠️ **Note:** the repository contains `fig4_5_dprime_C.m`, but `main.m` calls `fig4_5_dprime_Cd` (extra `d`).
To use `main.m` as-is, either rename the function call or update the last line to:

```matlab
fig4_5_dprime_C
```

---

### `analysis_dprimeANDC.m`

Computes **signal detection metrics** for human observers:

* Aggregates trials across blocks into a session-level table.
* Sorts trials into a consistent order: **condition → stimulus index**.
* Splits trials into **All**, **Aligned**, and **Separated** using `separated_idx`.
* Computes:

  * Hits / Misses / False Alarms / Correct Rejections
  * *d′* = `Z(H) − Z(FA)`
  * criterion *C* = `−0.5 × (Z(H) + Z(FA))`
* Clips rates away from 0 and 1 (epsilon = `1e-5`) to avoid infinite `norminv`.

**Output:**

* Saves `dprime_human.mat` containing:

  * `dprime` struct with fields `All`, `Aligned`, `Separated` (size: sessions × conditions × observers)
  * `C` struct with the same shape
  * `observerIDs`

---

### `fig2ab.m`

Generates **three vector PDF figures**:

1. `fig_sunlight_skylight.pdf`
   Plots and compares normalized SPDs of sunlight vs skylight.

2. `fig_chromatic_direction_refchange.pdf`
   Plots chromatic direction segments for **reflectance-change** trials in MacLeod–Boynton space.

3. `fig_chromatic_direction_illchange.pdf`
   Plots chromatic direction segments for **illuminant-change** trials in MacLeod–Boynton space.

Key steps:

* Loads `material.mat` reflectance spectra.
* Loads `sunlight.spd` and `skylight.spd`.
* Uses `SplineSpd` to interpolate SPDs onto 400–700 nm for smooth plotting.
* Converts spectra into MacLeod–Boynton coordinates using `spectralvectortoMB_400to700nm.m`.
* Uses indices in `ill_ref_change_material_idx.mat` to draw the appropriate line segments.

**Output directory:** `./figs/`

---

### `fig4_5_dprime_C.m`

Generates publication-ready plots of:

* Human *d′* (group mean + individual observers)
* Model *d′* (multiple observer models; also includes filter/pixel size effects)
* Human criterion *C* (group mean)

**Inputs:**

* `data/fig_params.mat`
* `data/dprime_human.mat`
* `data/dprime_models.mat`

**Model expectations (structure):**
The script expects fields like:

* `rslt_models.dprime_avg.Aligned.<ModelName>.f_pixel1`
* `rslt_models.dprime_avg.Separated.<ModelName>.f_pixel1`

(where `<ModelName>` includes e.g., `Brightest`, `CoS1`, `CoS2`, `CoS3`)

**Output directory:** `./figs/`

---

### `set_figParameters.m`

Creates/saves shared figure formatting parameters (`figp`) to:

* `data/fig_params.mat`

These include:

* `figp.twocolumn`, `figp.onecolumn` (centimetres)
* font name and font sizes

---

### `spectralvectortoMB_400to700nm.m`

Utility function:

```matlab
MB_vector = spectralvectortoMB_400to700nm(multispectralVector)
```

Converts spectra sampled over **400–700 nm** into MacLeod–Boynton–style coordinates.

* Loads `data/lms_400to700.mat`
* Computes LMS responses from the input spectra
* Produces:

  * `MB_vector(:,1)` = `L/(L+M)` (weighted)
  * `MB_vector(:,2)` = `S/(L+M)` (weighted)
  * `MB_vector(:,3)` = luminance-like term (`Lw*L + Mw*M`)

---

### `ticklengthcm.m`

A small helper from MATLAB File Exchange that allows specifying axis tick lengths in **centimetres**.

This is optional and purely for figure aesthetics.

---

## Outputs

Scripts generate:

* `data/dprime_human.mat` (computed metrics from raw data)
* `figs/*.pdf` (vector figures)

---

## License / citation

Please add a `LICENSE` file before public release.

If you want the repository to be citable, consider adding a `CITATION.cff` file as well.

---

## Contact

Takuma Morimoto, takuma.morimoto@psy.ox.ac.uk

---
