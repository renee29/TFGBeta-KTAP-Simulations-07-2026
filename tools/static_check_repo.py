#!/usr/bin/env python3
"""Static release checks for the TFGBeta MATLAB GitHub package."""
from __future__ import annotations
from pathlib import Path
import hashlib
import sys

ROOT = Path(__file__).resolve().parents[1]
CODE = ROOT / "code"
REQUIRED = [
    "README.md",
    "LICENSE",
    "CITATION.cff",
    ".zenodo.json",
    "requirements.txt",
    "code/run_all_figures.m",
    "code/check_matlab_release.m",
    "code/make_S1_matlab.m",
    "code/make_S2_matlab.m",
    "code/make_S3_matlab.m",
    "code/make_S4_matlab.m",
    "code/verify_folds_TFGBeta.py",
    "docs/REPRODUCIBILITY.md",
    "docs/GITHUB_ZENODO_RELEASE.md",
    "docs/RELEASE_CHECKLIST.md",
]
FORBIDDEN = [
    "'Color', [cfg.colors.fold_line, 0.7]",
    "'BackgroundColor', [1 1 1 0.80]",
    "Stable focus",
    "TGF-$\\beta$ clearance rate",
    "Asymptotic tumor density",
    "Initial tumor load",
    "Tumor escape",
    "Tumor density",
    "Eigenvalue $\\lambda$",
    "Re$(\\lambda)$",
    "\\mathrm{Im}(\\lambda)",
    "AÑADIR",
    "era [",
]
FORBIDDEN_RELEASE_TEXT = [
    "zenodo.XXXXXXX",
    "Update the DOI after the Zenodo release is created",
    "Zenodo DOI is pending",
]

def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

def main() -> int:
    errors: list[str] = []
    for rel in REQUIRED:
        if not (ROOT / rel).exists():
            errors.append(f"missing required file: {rel}")
    for path in CODE.glob("*.m"):
        if path.name == "check_matlab_release.m":
            continue
        text = path.read_text(encoding="utf-8")
        for token in FORBIDDEN:
            if token in text:
                errors.append(f"forbidden token in {path.relative_to(ROOT)}: {token}")
        if path.name.startswith("make_") and "save_run_data" not in text:
            errors.append(f"missing save_run_data in {path.relative_to(ROOT)}")
    for path in sorted(ROOT.rglob("*")):
        if not path.is_file() or ".git" in path.parts:
            continue
        if path.suffix.lower() not in {".md", ".cff", ".json"}:
            continue
        text = path.read_text(encoding="utf-8")
        for token in FORBIDDEN_RELEASE_TEXT:
            if token in text:
                errors.append(f"obsolete release text in {path.relative_to(ROOT)}: {token}")
    manifest = ROOT / "manifest_sha256.txt"
    with manifest.open("w", encoding="utf-8") as fh:
        for path in sorted(p for p in ROOT.rglob("*") if p.is_file() and ".git" not in p.parts):
            if path == manifest:
                continue
            fh.write(f"{sha256(path)}  {path.relative_to(ROOT).as_posix()}\n")
    if errors:
        print("STATIC CHECK FAILED")
        for e in errors:
            print(f"- {e}")
        return 1
    print("STATIC CHECK PASSED")
    print(f"Manifest written to {manifest}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
