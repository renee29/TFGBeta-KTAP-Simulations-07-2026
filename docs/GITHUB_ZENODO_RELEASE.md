# GitHub and Zenodo release record

## Repository and archive

- Repository: <https://github.com/renee29/TFGBeta-KTAP-Simulations-07-2026>
- Version-independent Zenodo DOI: <https://doi.org/10.5281/zenodo.21298788>
- Initial archived release, v1.0.0: <https://doi.org/10.5281/zenodo.21298789>

## Release procedure

1. Run the independent fold verification and repository checks:

```bash
python code/verify_folds_TFGBeta.py
python tools/static_check_repo.py
```

2. Run the MATLAB static audit:

```matlab
cd code
check_matlab_release(false)
```

3. Regenerate figures only when equations, parameters, numerical settings, or plotted data change. Label-only and metadata releases retain the audited `.mat` records and curated previews.
4. Commit the verified package and create a semantic GitHub release.
5. Confirm that Zenodo archives the release under the concept DOI above.

## Manuscript code-availability text

```latex
The MATLAB and Python scripts, tracked numerical records, and release-profile settings used to generate the numerical figures are publicly available at \url{https://github.com/renee29/TFGBeta-KTAP-Simulations-07-2026} and archived under \url{https://doi.org/10.5281/zenodo.21298788}.
```