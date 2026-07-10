# Reference outputs

The release profiles write their full output to `code/matlab_outputs/S*/`. The four light-background previews shown on the GitHub landing page are tracked separately under `assets/previews/`.

Regenerate the results in MATLAB with:

```matlab
cd code
run_all_figures("release")
```

Use this directory only for additional outputs that need a stable location in the repository. Larger result bundles can instead be attached to the GitHub release or deposited with the Zenodo archive.
