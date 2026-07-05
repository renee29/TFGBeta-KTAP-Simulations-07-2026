# Changelog

## v1.0.0-draft

Initial reproducibility package for TFGBeta messenger KTAP simulations.

### Changed from working scripts

- Added `run_all_figures.m` release driver.
- Added MATLAB static/smoke checker `check_matlab_release.m`.
- Added Python repository checker `tools/static_check_repo.py`.
- Added `.mat` data export to S1-S4 scripts.
- Replaced fragile RGBA plotting properties in S4 with RGB-compatible properties.
- Changed S4 info box from `Stable focus` to `No Hopf detected` when no Hopf crossing is found.
- Aligned S4 gamma labels with the eight sampled gamma values.
- Removed Spanish editorial markers in S3 plotting comments.
- Added README, reproducibility documentation, GitHub/Zenodo release instructions, license, citation metadata, and release checklist.
