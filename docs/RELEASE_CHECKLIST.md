# Release checklist

## Code

- [x] `check_matlab_release(false)` passes.
- [x] `python tools/static_check_repo.py` passes.
- [x] `python code/verify_folds_TFGBeta.py` reproduces both fold values.
- [x] Tracked `.mat` records exist under `code/matlab_outputs/S*/data/`.
- [x] Curated previews exist under `assets/previews/`.
- [x] No local or private paths remain in scripts.
- [x] No editorial markers or obsolete figure labels remain.

The v1.0.1 correction changes labels and metadata only. The numerical figures were therefore not regenerated; equations, parameters, `.mat` records, and curated previews are unchanged.

## Metadata

- [x] `CITATION.cff` contains final authors, affiliations, repository URL, version, and concept DOI.
- [x] `.zenodo.json` contains final authors, affiliations, license, keywords, and repository relation.
- [x] `LICENSE` has the correct copyright holder.
- [x] `README.md` contains the final paper title, repository URL, and concept DOI.

## Manuscript

- [x] Code-availability statement contains the GitHub URL and Zenodo DOI.
- [x] Figure captions and script labels use the same terminology.
- [x] Figure S1 label and caption are consistent with the independently verified fold values.