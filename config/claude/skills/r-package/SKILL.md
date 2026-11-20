---
name: r-package
description: Personal R package development preferences for code style, documentation conventions, and workflow. Complements Posit r-lib skills with specific style choices for minimal comments and neuroimaging package patterns.
license: CC-BY-4.0
compatibility: opencode
metadata:
  language: R
  audience: package-developers
  focus: style-preferences
---

# R Package Development - Personal Preferences

Specific style preferences and workflow choices for R package development. Use alongside Posit `testing-r-packages` for comprehensive guidance.

## Code Style Philosophy

### Self-Explanatory Code Without Comments

Functions and variables should be named clearly enough that comments are unnecessary:

```r
# Good: Self-explanatory without comments
calculate_mean_cortical_thickness <- function(surface_data,
                                               region_labels,
                                               exclude_medial_wall = TRUE) {
  valid_vertices <- identify_valid_vertices(surface_data, exclude_medial_wall)
  regional_means <- compute_regional_means(surface_data, region_labels, valid_vertices)
  regional_means
}

# Bad: Needs comments to explain
calc_mct <- function(sd, rl, emw = TRUE) {
  # Get valid vertices
  vv <- get_vv(sd, emw)
  # Calculate means
  rm <- calc_rm(sd, rl, vv)
  rm
}

# Exception: Comments allowed for workarounds
process_freesurfer_annotation <- function(annot_file) {
  # WORKAROUND: FreeSurfer annot files have non-standard header format
  # that readBin() misinterprets. Skip first 4 bytes manually.
  raw_data <- readBin(annot_file, "raw", n = file.size(annot_file))
  data_without_header <- raw_data[-(1:4)]
  parse_annotation_data(data_without_header)
}
```

**When comments ARE acceptable:**

- Explaining workarounds for upstream bugs
- Documenting non-obvious algorithm choices with citations
- Noting technical constraints (e.g., file format quirks)

### Consistent Naming Patterns

```r
# Good: Consistent verb-noun pattern
read_freesurfer_surface()
read_freesurfer_annotation()
read_freesurfer_curv()

write_freesurfer_surface()
write_freesurfer_annotation()

# Bad: Inconsistent patterns
fs_read_surface()
read_annot_freesurfer()
freesurfer_curv_read()
```

**Naming conventions:**

- Data reading functions: `read_*`
- Data writing functions: `write_*`
- Data transformation: `transform_*`, `convert_*`
- Calculations: `calculate_*`, `compute_*`
- Checks/validation: `is_*`, `has_*`, `validate_*`

## Public API Only

Never rely on internal/unexported functions — R's `tools:::` triple-colon internals, or another package's `pkg:::fn` — in package code unless the user explicitly approves it. Use the public, exported API; if it's missing what you need, that's a signal to request the upstream export or find another approach, not to reach for `:::`. (Test code has its own version of this rule in `r-testing`.)

## Hard Rules

- Never delete test files or vignette sections without explicit user approval
- Preserve existing vignette content — only modify sections the user explicitly asks to change
- Use roxygen2-level documentation (not Rd edits), prefer `cli` over `cat`/`message` for user-facing output
- **Always run the full `R CMD check` (`devtools::check()` or `rcmdcheck::rcmdcheck(error_on = "warning")`) before committing** — `document()` + `testthat` + `lintr` are not enough; they miss whole classes of failures CI fails on (e.g. `checking Rd cross-references` WARNINGs from a `\link{}`/`[fn()]` to an unexported topic). CI fails on WARNINGs, not NOTEs, so `0 errors / 0 warnings` is the bar; pre-existing NOTEs you didn't introduce (e.g. moved URLs) are fine. The PostToolUse hook runs this automatically inside a package with a DESCRIPTION, but when editing a package outside its reach (a freshly cloned external repo/fork), run it by hand.

## Documentation Preferences

### Minimal but Complete roxygen2

Focus on what users need, not implementation details:

```r
# Good: User-focused documentation
#' Read FreeSurfer surface file
#'
#' Reads surface geometry from FreeSurfer format files. Supports both
#' ASCII and binary formats automatically.
#'
#' @param filepath Path to FreeSurfer surface file
#'
#' @return List with two elements:
#'   * `vertices` - Nx3 matrix of vertex coordinates
#'   * `faces` - Mx3 matrix of face indices (1-indexed)
#'
#' @examples
#' surf <- read_freesurfer_surface("lh.pial")
#' n_vertices <- nrow(surf$vertices)
#'
#' @family freesurfer-io
#' @export
read_freesurfer_surface <- function(filepath) {
  # Implementation
}

# Bad: Over-documented with implementation details
#' Read FreeSurfer surface file
#'
#' This function reads a FreeSurfer surface file by first checking
#' if it's binary or ASCII format, then parsing the header to get
#' the number of vertices and faces, and finally reading the data
#' into R matrices using optimized C++ code via Rcpp.
#'
#' The function performs the following steps:
#' 1. Opens file connection
#' 2. Reads magic number
#' 3. Determines format
#' ...
#' [Users don't need implementation details in documentation]
```

### Exported Docs Reference Only Exported Things

Documentation for an exported function must only make users think about other
_exported_ functions. Never name, describe, or link an internal (unexported)
helper in an exported function's roxygen — users can't call it, it leaks
implementation detail rather than explaining behaviour, and a `[internal_fn()]`
markdown link becomes a `\link{internal_fn}` that fails `R CMD check` ("missing
link / provide package anchors"). Describe `...` and behaviour in user terms
(what they pass, what happens), not by pointing at internal plumbing.

```r
# Bad: exposes an internal helper users can't use
#' @param ... passed to run_check_fs_cmd()

# Good: user-facing
#' @param ... Additional arguments controlling command execution, such as a timeout.
```

Only link (`[fn()]`) to EXPORTED topics; for internal helpers use plain code
(`` `fn()` ``) or prose.

### Example-Driven Documentation

Prioritize realistic examples over abstract descriptions:

```r
# Good: Practical workflow example
#' Calculate cortical thickness statistics
#'
#' @param thickness_file Path to thickness data
#' @param parcellation_file Path to parcellation
#'
#' @examples
#' # Typical neuroimaging workflow
#' thickness <- read_freesurfer_curv("lh.thickness")
#' parcellation <- read_freesurfer_annotation("lh.aparc.annot")
#'
#' # Get mean thickness per region
#' regional_stats <- calculate_regional_thickness(
#'   thickness,
#'   parcellation,
#'   exclude_unknown = TRUE
#' )
#'
#' # Extract specific regions of interest
#' motor_thickness <- regional_stats$thickness[
#'   regional_stats$region == "precentral"
#' ]
```

### Vignettes

Vignettes should use skill codex-voice and markdown. Preserve existing content — only modify sections the user explicitly asks to change.

## Testing

See the `r-testing` skill for all testing conventions.

## Updating NEWS.md

NEWS.md should contain information on what has changed in the R-package architecture, not other repository changes.
Organize by minor and major (breaking) changes.

## Workflow Integration

### Development Cycle

```r
# Typical development workflow
devtools::load_all()              # Load package
devtools::document()              # Update documentation
devtools::test()                  # Run tests
devtools::check()                 # R CMD check

# Before committing
lintr::lint_package()             # Check style
covr::package_coverage()          # Check coverage
goodpractice::gp()                # Check best practice
```

The PostToolUse hook already runs `air format` → `lintr::lint()` → `devtools::test()` → `devtools::check()` automatically on every `.R` edit (gated on finding a `DESCRIPTION` file) — `devtools::check()` re-documents via roxygen by default, so this pipeline is enforced automatically rather than being a manual pre-commit step.

### Pre-CRAN Checklist

Beyond standard checks, verify:

```r
# Check that examples run
devtools::run_examples()

# Verify vignettes build
devtools::build_vignettes()

# Test on multiple platforms
devtools::check_win_devel()
devtools::check_mac_release()

# Spell check
spelling::spell_check_package()

# Ensure URLs work
urlchecker::url_check()

# Check reverse dependencies if updating existing package
revdepcheck::revdep_check(
```

## CI/CD with GitHub Actions

Use `r-lib/actions` for standard R package workflows.

### Standard Workflows

- `check-standard.yaml` — R CMD check on multiple OS/R versions
- `pkgdown.yaml` — build and deploy documentation site
- `test-coverage.yaml` — upload coverage to Codecov/Coveralls

### Conventions

- Cache R packages and dependencies
- Run checks on ubuntu (release, devel, oldrel), macOS (release), and Windows (release)
- Use `r-lib/actions/setup-r@v2` and `r-lib/actions/setup-r-dependencies@v2`
- Pin action versions to major tags (e.g., `@v2`), not specific commits

## Works Well With

- `r-testing` — personal testing conventions
- `r-release` — confirming distribution channel and executing a release
- `cran-check` — CRAN-readiness check/fix loop
- `r-lib:testing-r-packages` (Posit) — comprehensive testthat 3+ patterns
- `open-source:release-post` (Posit) — release announcements
- `straight-talk:codex-voice` — writing voice for vignettes

## When to Use Me

Use this skill when:

- Setting up a new R package and want style guidance
- Need preferences for code organization and naming
- Updating documentation and vignettes
- Want to understand the "no comments" philosophy

**Do NOT use for:**

- Testing patterns (use `r-testing` instead)
- General R package structure (covered in Posit skills)
- CRAN submission (use `cran-check`) or release execution (use `r-release`)

## Quick Reference

**Code style:** Self-explanatory names, no comments except workarounds

**Naming:** `verb_noun()` pattern, consistent prefixes

**Documentation:** User-focused, example-driven

**Testing focus:** Public API, file I/O, edge cases

**Workflow:** `load_all()` → `document()` → `test()` → `check()`
