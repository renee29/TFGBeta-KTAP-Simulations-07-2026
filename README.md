# TFGBeta messenger KTAP simulations

This repository contains the MATLAB and Python scripts used to reproduce the numerical figures and fold checks for the manuscript:

**Kinetic Theory of Active Particles with Sub-Cellular Messengers: A Multiscale Mediator Framework with Application to Tumour-Immune Bistability**

The code implements the reduced tumour-immune-TGF-beta ODE model, figure-generation scripts for supplementary Figures S1-S4, and an independent Python fold-verification script.

## Repository layout

```text
code/
  make_S1_matlab.m          # Figure S1: bifurcation diagram and time series
  make_S2_matlab.m          # Figure S2: basins and intervention trajectories
  make_S3_matlab.m          # Figure S3: robustness in (lambda_1, beta)
  make_S4_matlab.m          # Figure S4: eigenvalue continuation
  run_all_figures.m         # one-command MATLAB driver
  check_matlab_release.m    # MATLAB static/smoke checks
  verify_folds_TFGBeta.py   # independent Python fold verification
docs/
  REPRODUCIBILITY.md
  GITHUB_ZENODO_RELEASE.md
  RELEASE_CHECKLIST.md
outputs_reference/
  README.md                 # location for regenerated reference outputs
tools/
  static_check_repo.py      # repository-level static checker
```

## Requirements

### MATLAB

Recommended:

- MATLAB R2021a or newer.
- Optimization Toolbox for `fsolve`, used in `make_S4_matlab.m`.

The scripts use `ode113`, `deval`, `fzero`, `fsolve`, `exportgraphics`, and standard plotting utilities.

### Python

For the independent fold-verification script:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python code/verify_folds_TFGBeta.py
```

## Reproduce all MATLAB figures

From the repository root:

```matlab
cd code
run_all_figures("release")
```

Fast smoke-test mode:

```matlab
cd code
run_all_figures("fast")
```

Individual figures:

```matlab
make_S1_matlab("publication")
make_S2_matlab("publication")
make_S3_matlab("final")
make_S4_matlab("final")
```

## Outputs

Each figure script writes:

```text
code/matlab_outputs/S*/panels/    # individual panel PNG/PDF files
code/matlab_outputs/S*/previews/  # combined preview PNG/PDF files
code/matlab_outputs/S*/data/      # .mat files with data, parameters, config, metadata
```

The `.mat` files are part of the reproducibility record. They store the numerical arrays used to make the figures together with the parameter structure and the script configuration.

## Checks before release

Python static package check:

```bash
python tools/static_check_repo.py
```

MATLAB static check:

```matlab
cd code
check_matlab_release(false)
```

Optional MATLAB smoke test:

```matlab
cd code
check_matlab_release(true)
```

## How to cite

This software is archived on Zenodo. Please cite the specific version you used. Machine-readable metadata is provided in `CITATION.cff`.

```bibtex
@software{torres2026tfgbeta,
  author    = {Elena Torres Lozano and Juan Calvo and Rene Fabregas and Juan Soler},
  title     = {TFGBeta messenger KTAP simulations},
  year      = {2026},
  publisher = {Zenodo},
  version   = {v1.0.0},
  doi       = {10.5281/zenodo.xxxxxxx},
  url       = {https://doi.org/10.5281/zenodo.xxxxxxx}
}
```

Replace `zenodo.xxxxxxx` with the DOI minted when the GitHub release is archived on Zenodo, and update the same DOI in `CITATION.cff` and `.zenodo.json`.

## License

The code is distributed under the MIT License. Confirm with all authors before public release.
