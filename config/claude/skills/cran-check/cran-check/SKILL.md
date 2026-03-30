---
name: cran-check
description: Run a full CRAN preparation workflow on an R package. Use when the user says "/cran-check", "prepare for CRAN", "run CRAN checks", or "get this package CRAN-ready". Runs R CMD check --as-cran, fixes NOTEs/WARNINGs/ERRORs, updates roxygen2 docs, runs tests, and commits fixes.
---

# CRAN Check Workflow

Run in the current R package directory.

## Steps

1. Run `Rscript -e "roxygen2::roxygenise()"` to ensure docs are current
2. Run `Rscript -e "devtools::check(args = '--as-cran')"` and capture full output
3. Parse the output for ERRORs, WARNINGs, and NOTEs
4. For each issue found:
   - Fix the underlying code or documentation
   - Use roxygen2-level approaches, never edit .Rd files directly
   - Prefer cli over cat/message for user-facing output
   - Never delete test files or vignette sections without asking
5. After fixes, re-run `Rscript -e "devtools::check(args = '--as-cran')"` to verify
6. Run `Rscript -e "devtools::test()"` to confirm all tests pass
7. Report a summary: what was found, what was fixed, what remains

## Rules

- Fix issues iteratively: ERRORs first, then WARNINGs, then NOTEs
- If a NOTE is about package size or first submission, flag it but don't try to "fix" it
- If unsure whether a change is safe, ask before making it
- Do not commit unless the user asks
