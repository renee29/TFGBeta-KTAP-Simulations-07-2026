# Release checklist

## Code

- [ ] `run_all_figures("release")` runs successfully in MATLAB.
- [ ] `check_matlab_release(false)` passes.
- [ ] `python tools/static_check_repo.py` passes.
- [ ] `python code/verify_folds_TFGBeta.py` runs successfully.
- [ ] Generated `.mat` files exist under `code/matlab_outputs/S*/data/`.
- [ ] Generated PNG/PDF files exist under `code/matlab_outputs/S*/panels/`.
- [ ] No local paths or private paths remain in scripts.
- [ ] No editorial comments such as `AÑADIR` or `era [` remain.

## Metadata

- [ ] `CITATION.cff` contains final authors, repository URL, version, and DOI.
- [ ] `.zenodo.json` contains final authors, license, keywords, and description.
- [ ] `LICENSE` has the correct copyright holder.
- [ ] `README.md` contains final paper title and repository URL.

## Manuscript

- [ ] Code-availability statement contains GitHub URL and Zenodo DOI.
- [ ] Figure captions match regenerated figures.
- [ ] Figure S1 label and caption are consistent with the fold values used in the manuscript.
