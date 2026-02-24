---
name: r-testing
description: "Personal R package testing conventions using testthat 3e with describe/it structure, strict signal handling, and clean test output"
license: CC-BY-4.0
compatibility: opencode
metadata:
  language: R
  audience: package-developers
  focus: testing-preferences
---

# R Package Testing Conventions

Personal testing rules for R packages using testthat 3e.
Use alongside Posit `testing-r-packages` for general testthat guidance.

## Test Structure

### describe/it Blocks Only

Always use BDD-style `describe()`/`it()` blocks, never `test_that()`.

```r
describe("read_surface()", {
  it("reads binary format", {
    surf <- read_surface(test_path("fixtures/lh.pial"))
    expect_equal(nrow(surf$vertices), 163842)
  })

  it("errors on missing files", {
    expect_error(
      read_surface("nonexistent.file"),
      "Could not find"
    )
  })
})
```

### File Structure Mirrors Source

Each `R/filename.R` gets a corresponding `tests/testthat/test-filename.R`.
If a source file is split, split the test file to match.

### Integration Tests Live With Companions

Integration tests belong in the same file as the unit tests for that function, behind targeted skip guards.
Never create a separate `test-integration.R`.

```r
describe("run_freesurfer()", {
  it("validates arguments", {
    expect_error(run_freesurfer(NULL))
  })

  it("runs recon-all on real data", {
    skip_if_no_freesurfer()
    result <- run_freesurfer(test_path("fixtures/subject"))
    expect_true(file.exists(result$output))
  })
})
```

## Signal Handling

### Never Suppress Warnings or Messages

Never use `suppressWarnings()` or `suppressMessages()` in tests.
Every warning and message must be caught by an expectation or cause a test failure.

```r
# Good: Expect the warning
it("warns on deprecated argument", {
  expect_warning(
    my_function(old_arg = TRUE),
    "deprecated"
  )
})

# Bad: Silently swallowing signals
it("works with deprecated argument", {
  suppressWarnings(my_function(old_arg = TRUE))
})
```

To force warnings, messages, or errors for testing, use `local_mocked_bindings()` or `withr::local_options()`.

### Never Use capture.output

Use `expect_message()`, `expect_warning()`, or `expect_snapshot()` instead.

```r
# Good: Snapshot for print output
it("prints atlas summary", {
  expect_snapshot(print(my_atlas))
})

# Good: Expect specific message
it("reports progress", {
  expect_message(
    process_data(verbose = TRUE),
    "Processing complete"
  )
})

# Bad: capture.output with string matching
it("prints atlas summary", {
  out <- capture.output(print(my_atlas))
  expect_true(grepl("atlas", out[1]))
})
```

### Clean devtools::test() Output

`devtools::test()` should produce only the test result summary with no leaked messages, CLI output, or verbose function noise.
If a function produces messages during testing, wrap the call in `expect_message()` or `expect_snapshot()`.

## Coverage

### Aim for 100% Where Meaningful

Use `covr::package_coverage()` to measure.
Wrap genuinely untestable code (interactive functions, hardware-dependent code) in `# nocov start` / `# nocov end`.

```r
# nocov start
snapshot_brain <- function(...) {
  requireNamespace("rgl", quietly = TRUE)
  # interactive-only function
}
# nocov end
```

Don't leave false gaps — either test it or mark it `#nocov` because its unreachable.

## Scope

### Each Package Tests Its Own Functions

Tests should exercise the package's own functions and behavior, not re-test data structures or output from dependency packages.

### No Package Namespacing in Tests

Never use `package::` or `package:::` in test code.
testthat loads all functions (including internal ones) via `devtools::load_all()`.

```r
# Good
result <- my_internal_function(x)

# Bad
result <- mypackage:::my_internal_function(x)
```

## Skip Guards

Don't add unnecessary skips.
Run all tests by default.
Only use targeted skip conditions when external tools are genuinely required.

```r
# Good: Targeted skip for specific dependency
skip_if(!freesurfer::have_fs(), "FreeSurfer not available")

# Bad: Broad convenience skips
skip_on_ci()
skip("slow test")
```

## Code Quality in Tests

### Use vapply() Over sapply()

Follows goodpractice recommendations — applies to test code too.

```r
# Good
vapply(surfaces, nrow, integer(1))

# Bad
sapply(surfaces, nrow)
```

### Visual Regression Testing

Use `vdiffr::expect_doppelganger()` for ggplot output.
Cover all atlas/position/palette combinations.

```r
it("renders default atlas plot", {
  p <- ggplot(my_atlas) + geom_brain()
  vdiffr::expect_doppelganger("default-atlas", p)
})
```

### Prefer local_* Over with_*

Always use `local_*()` variants, never `with_*()` wrappers.
`local_*()` is cleaner — it avoids nesting and automatically cleans up when the test scope exits.

```r
# Good: local_ variant
it("writes output files", {
  tmp <- local_tempdir()
  write_surface(surf, file.path(tmp, "output.surf"))
  expect_true(file.exists(file.path(tmp, "output.surf")))
})

# Bad: with_ wrapper adds unnecessary nesting
it("writes output files", {
  with_tempdir({
    write_surface(surf, "output.surf")
    expect_true(file.exists("output.surf"))
  })
})
```

### Mocking With local_mocked_bindings

Use `local_mocked_bindings()` to stub out functions for testing.
This replaces the deprecated `with_mock()` and `local_mock()`.

```r
# Mock an internal function
it("handles missing FreeSurfer gracefully", {
  local_mocked_bindings(
    have_fs = function() FALSE
  )
  expect_message(fs_sitrep(), "not found")
})

# Mock a function from another package
it("handles download failure", {
  local_mocked_bindings(
    download.file = function(...) stop("no internet"),
    .package = "utils"
  )
  expect_error(fetch_atlas("dk"), "no internet")
})

# Mock multiple bindings at once
it("runs in offline mode", {
  local_mocked_bindings(
    has_internet = function() FALSE,
    check_api_key = function() "fake-key"
  )
  result <- get_cached_data("atlas")
  expect_s3_class(result, "data.frame")
})
```

Use mocking to:
- Simulate unavailable external tools (FreeSurfer, rgl, webshot)
- Force error/warning/message conditions for testing signal handling
- Avoid network calls in unit tests
- Test code paths that depend on system state

## Fixtures

### Naming and Location

Store fixtures in `tests/testthat/fixtures/`.
Name fixture files after the format or scenario they represent.

```r
# Good: Descriptive fixture names
test_path("fixtures/lh.pial")
test_path("fixtures/malformed-annotation.annot")
test_path("fixtures/empty-surface.surf")

# Bad: Generic names
test_path("fixtures/test1.dat")
test_path("fixtures/input.bin")
```

### Fixtures vs Inline Data

Use fixtures for binary files, real data samples, and anything that can't be meaningfully constructed inline.
Use inline data for simple cases where construction is clearer than a file reference.

```r
# Inline: Simple, obvious test data
it("calculates mean thickness", {
  thickness <- c(2.1, 2.3, 2.5, 2.2)
  expect_equal(mean(thickness), 2.275)
})

# Fixture: Binary format that can't be constructed inline
it("reads FreeSurfer surface", {
  surf <- read_surface(test_path("fixtures/lh.pial"))
  expect_equal(ncol(surf$vertices), 3)
})
```

## Snapshot Testing

Use `expect_snapshot()` for complex output that is hard to specify exactly — printed summaries, CLI output, error messages with dynamic content.

```r
it("prints a readable summary", {
  expect_snapshot(summary(my_atlas))
})

it("produces informative error", {
  expect_snapshot(read_surface("nonexistent"), error = TRUE)
})
```

Avoid snapshots for simple values — use specific expectations instead.
Review snapshot files in `tests/testthat/_snaps/` during code review.

## Works Well With

- `r-package` — code style and documentation conventions
- `r-lib:testing-r-packages` (Posit) — comprehensive testthat 3+ patterns
- `r-lib:lifecycle` (Posit) — deprecation testing patterns
