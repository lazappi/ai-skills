---
name: r-package-dev
description: R package development conventions and checks covering formatting, lintr, roxygen2 docs, testthat 3e tests, development versions, NEWS.md, R CMD check and BiocCheck for Bioconductor. Use when working in an R package (a folder with a DESCRIPTION file), when adding or changing package functions, docs or tests, when fixing R CMD check or BiocCheck problems, or when bumping the version and updating NEWS.md.
---

# R package development

Work the way a careful R package maintainer would: the project's own config first, these conventions where the project is silent.

## 1. Read the package

Before changing anything, read:

- `DESCRIPTION`: version, `Imports` versus `Suggests`, `Config/testthat/edition`, `Config/roxygen2/version`, `biocViews` (present means a Bioconductor package)
- Project instructions and contributing guides (`AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`)
- Tool configs: `air.toml` or `.air.toml`, `.lintr`, `.Rbuildignore`, `_pkgdown.yml`, `.github/workflows/`
- Any check script the project provides (for example `scripts/check.sh` or a `Makefile`), which replaces the commands below

Done when you know the formatter, linter, test and check commands and whether the package targets Bioconductor.

## 2. Make the change

Follow [references/conventions.md](references/conventions.md) for code style, errors, dependencies, roxygen2 docs and tests.
Read it before writing R code or tests in the package.

Keep each change to one concern, with code, docs and tests together.

## 3. Regenerate and check

Run, in order, fixing problems before moving on:

1. The package's formatter: `air format .` for Air, `styler::style_pkg()` for styler, or skip this step when it uses neither
2. `lintr::lint_package()`, fixing the lints in code you changed and leaving the rest
3. `devtools::document()`, then confirm `man/` and `NAMESPACE` changed only as expected
4. `devtools::test()`, or `devtools::test(filter = "<file>")` while iterating
5. `devtools::check()` for a change that touches exports, dependencies or docs
6. `BiocCheck::BiocCheck()` for a Bioconductor package

Treat every NOTE from `R CMD check` as a problem to fix, not something to accept.
Done when every step passes, or each remaining failure is reported to the user with its cause.

## 4. Version and NEWS

For a user-visible change, update `NEWS.md` and the version as described in [references/release.md](references/release.md).
Read it also for releases and Bioconductor submission.

## 5. Report

Tell the user what changed, the result of each check and anything left failing.
Leave the changes uncommitted unless the user asks for a commit.
