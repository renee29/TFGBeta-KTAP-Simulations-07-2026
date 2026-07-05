# Reproducibility protocol

## Model

The numerical scripts use the nondimensional reduced ODE system from the manuscript:

```text
dX/dt   = r X (1 - X/K) - alpha X^2 T/(g1^2 + X^2) + beta X phi/(1 + phi)
dT/dt   = sigma - mu T - gamma T phi/(1 + phi)
dphi/dt = delta1 X + delta2 T - lambda_1 phi
```

Baseline parameters are defined inside each MATLAB script through `base_params()`.

## MATLAB figure profiles

- `draft`: fast internal checks.
- `final`: denser publication-quality computation.
- `publication`: highest-quality profile where available.
- `release`: driver profile used by `run_all_figures.m`.

`run_all_figures("release")` executes:

```matlab
make_S1_matlab("publication")
make_S2_matlab("publication")
make_S3_matlab("final")
make_S4_matlab("final")
```

## Data preservation

Each script saves a `.mat` file containing:

- `data`: numerical arrays used in the figure.
- `p`: baseline parameter structure.
- `ic`: initial-condition structure, when applicable.
- `cfg`: script configuration and tolerances.
- `metadata`: figure ID, profile, generation timestamp, MATLAB version.

## Fold verification

The MATLAB figure script for S1 is a figure generator. It is not the sole source of truth for fold values. The independent Python script `verify_folds_TFGBeta.py` computes the fold conditions using equilibrium and determinant constraints.

Run:

```bash
python code/verify_folds_TFGBeta.py
```

Expected rounded values used in the manuscript:

```text
lambda_c approx 0.185
lambda_upper approx 1.058
```

## Recommended archival workflow

1. Run `python tools/static_check_repo.py`.
2. Run `check_matlab_release(false)` in MATLAB.
3. Run `run_all_figures("release")` in MATLAB.
4. Confirm generated `matlab_outputs/S*/data/*.mat` files exist.
5. Commit code and generated outputs if output size is acceptable.
6. Create a GitHub release `v1.0.0`.
7. Archive the GitHub release in Zenodo.
8. Update `CITATION.cff`, `.zenodo.json`, and the manuscript code-availability statement with the Zenodo DOI.
