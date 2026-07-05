# GitHub and Zenodo release instructions

## GitHub setup

1. Create a new repository.
2. Copy this package into the repository root.
3. Replace placeholders in:
   - `CITATION.cff`
   - `.zenodo.json`
   - `README.md`
4. Run static checks:

```bash
python tools/static_check_repo.py
```

5. In MATLAB:

```matlab
cd code
check_matlab_release(false)
run_all_figures("release")
```

6. Commit the code, docs, and selected reference outputs.
7. Tag a release:

```bash
git tag -a v1.0.0 -m "Initial reproducibility release"
git push origin main --tags
```

## Zenodo setup

1. Log into Zenodo.
2. Link the GitHub account in the Zenodo profile.
3. Enable the target repository in the GitHub integration.
4. Create a GitHub release.
5. Zenodo archives the release and mints a DOI.
6. Update `CITATION.cff`, `.zenodo.json`, and the manuscript with the DOI.

## Manuscript code-availability text

Use after the DOI exists:

```latex
The MATLAB and Python scripts used to generate Figures~\ref{fig:bifurcation}, \ref{fig:basin}, \ref{fig:phase_diagram}, and~\ref{fig:hopf_eigenvalues}, together with parameter files and numerical outputs, are available at GitHub: \url{https://github.com/renee29/TFGBeta-KTAP-Simulations-07-2026} and archived in Zenodo under DOI: \url{https://doi.org/10.5281/zenodo.XXXXXXX}.
```

Before the DOI exists:

```latex
The MATLAB and Python scripts used to generate Figures~\ref{fig:bifurcation}, \ref{fig:basin}, \ref{fig:phase_diagram}, and~\ref{fig:hopf_eigenvalues}, together with parameter files and numerical outputs, will be made available in a public GitHub repository and archived in Zenodo before submission.
```
