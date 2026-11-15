# Versions, NEWS and releases

## Development versions

Use tidyverse-style versions:

- A release is `x.y.z`, for example `0.2.0`
- Development after a release is `x.y.z.9000`, for example `0.2.0.9000`
- Bump the fourth component (`.9001`, `.9002`) only when the project asks for it, for example to mark a finished feature
- Change the release number (`x.y.z`) only when the user asks for a release

Bioconductor packages use their own scheme instead: an even `y` in release, an odd `y` in devel, and every change to the devel branch bumps `z` (for example `1.3.4` to `1.3.5`).
Follow the scheme already in `DESCRIPTION` when it is clear which one the package uses.

## NEWS.md

- Keep one heading per version, newest first, with `# <pkg> (development version)` for unreleased work
- Add one bullet per user-visible change under the development heading: new features, changed behaviour, bug fixes and deprecations
- Write each bullet for users: what changed and what they need to do, naming the function as `` `fun()` ``
- Mention the issue or pull request when there is one, for example `(#123)`
- Leave internal refactors and test-only changes out

## Checks before a release

1. `devtools::check()` passes with 0 errors, 0 warnings and 0 notes.
   A "unable to verify current time" NOTE comes from the environment, and setting `_R_CHECK_SYSTEM_CLOCK_=false` removes it.
2. `urlchecker::url_check()` finds no broken links
3. `devtools::spell_check()` finds no new misspellings
4. The pkgdown site builds with `pkgdown::build_site()`, if the package has one
5. For Bioconductor, `BiocCheck::BiocCheck()` reports no errors or warnings

## Bioconductor

- `DESCRIPTION` needs `biocViews` terms, and `BugReports` and `URL` fields
- Give exported functions runnable examples.
  BiocCheck flags a package where under 80% of man pages have them.
  Also include a vignette with real code.
- Prefer Bioconductor classes (`SummarizedExperiment`, `SingleCellExperiment`, `S4Vectors::DataFrame`) for data the ecosystem shares
- BiocCheck flags lines over 80 characters, tabs, indents that are not a multiple of 4 spaces and functions over 50 lines.
  Fix what is cheap, and report the rest to the user rather than reformatting the whole package against the project's own style.
- Use `vapply()` instead of `sapply()` and `seq_along(x)` or `seq_len(n)` instead of `1:length(x)`, which BiocCheck also flags
