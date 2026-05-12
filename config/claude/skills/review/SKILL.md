---
name: review
description: Critical code review for R packages — review, fix all issues, run tests until green
user_invocable: true
---

# Critical Code Review

Perform a thorough critical code review of this R package, then fix everything you find.

## Steps

1. **Review** — Analyze the entire codebase for:
   - Bugs and logic errors
   - Code smells and anti-patterns
   - Missing or incorrect roxygen2 documentation
   - Test coverage gaps
   - DESCRIPTION/NAMESPACE issues
   - CRAN compliance problems

2. **Present findings** — Show a numbered list of all issues found, grouped by severity (blocking, important, minor).

3. **Fix all issues** — After user confirms, systematically fix every issue:
   - Create a feature branch (e.g., `review-fixes`)
   - Fix issues one logical group at a time
   - After each group of fixes, run `devtools::test()` and report results
   - If a fix introduces a regression, revert that specific change and try an alternative

4. **Verify** — After all fixes:
   - Run `devtools::test()` — report total test count and pass/fail
   - Run `devtools::check()` — must be clean (0 errors, 0 warnings, ideally 0 notes)
   - If anything fails, debug and fix until green

5. **Report** — Summarize:
   - What was found
   - What was fixed
   - Final test/check output
   - Anything deliberately NOT fixed, with reasoning
