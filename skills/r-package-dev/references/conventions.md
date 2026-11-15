# R package conventions

Apply these where the package's own config and instructions say nothing.

## Formatting and lint

Use these conventions for new packages or when there is evidence they are used in the package.
Follow the existing conventions of the package otherwise.

- Format with [Air](https://posit-dev.github.io/air/): `air format .`, and `air format --check .` in CI.
  A typical `air.toml` sets `line-width = 80`, `indent-width = 2` and `persistent-line-breaks = true`.
- Format vignettes and other R Markdown with `styler::style_dir("vignettes")`, because Air formats only `.R` files
- Lint with `lintr::lint_package()`, using `linters_with_defaults()` in `.lintr` with project-specific changes on top
- Names are `snake_case`.
  When a class or field name must break this (for example a name from another language's API), allow it in `object_name_linter` rather than suppressing the lint at each use.
- Variables used only inside `cli` `{}` strings trip `object_usage_linter`, so compute the value inline or pass it as a condition field

## Code

- One concern per file in `R/`, with the file named after its main function or class
- Signal conditions with `cli::cli_abort()`, `cli::cli_warn()` and `cli::cli_inform()`, giving errors a class (`class = "<pkg>_error_<kind>"`) so tests and callers can catch them
- Validate arguments at the exported boundary and keep internal helpers trusting
- Call other packages as `pkg::fun()`, or with `@importFrom` for heavily used functions
- Packages needed only for some features go in `Suggests`.
  Guard each use with `rlang::check_installed()` or the project's own helper, and skip the matching tests with `testthat::skip_if_not_installed()`.
- Keep internal functions unexported, and never export a function only to test it

## Documentation

- Document every exported function with roxygen2: `@title` (first line), `@description`, `@param` for every argument, `@returns`, `@examples` that run, and `@export`
- Use `@inheritParams` instead of repeating parameter docs, and `@family` or `@seealso` to link related functions
- Internal helpers get a short roxygen block with `@noRd`
- Regenerate with `devtools::document()` using the roxygen2 version in `Config/roxygen2/version`, so the generated files don't churn
- Add or update vignette examples when user-facing behaviour changes, and add new pages to `_pkgdown.yml` if the package has a site

## Tests

- Use testthat 3rd edition (`Config/testthat/edition: 3` in `DESCRIPTION`)
- Name test files `tests/testthat/test-<file>.R` to match the `R/` file they test
- Start each `test_that()` with a description of the behaviour, and add a short comment on why the test exists when that is not obvious
- Cover errors and edge cases as well as the happy path: empty input, `NA`, zero-length vectors, one row or column, wrong types
- Test errors by class with `expect_error(..., class = "<pkg>_error_<kind>")`, and use `expect_snapshot()` for messages whose wording matters
- Build test data in helpers (`tests/testthat/helper-*.R`) or with `withr::local_*()` so tests leave no files or options behind
- Keep each test fast and independent so `Config/testthat/parallel: true` can run them in parallel
