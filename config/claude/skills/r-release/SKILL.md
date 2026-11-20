---
name: r-release
description: Confirm the distribution channel (CRAN vs r-universe) and execute an R package release — NEWS.md/version consistency, tag, merge, publish, and bump to a dev version. Use when preparing or executing an R package release, not just checking CRAN-readiness (see cran-check for that) or generating a release checklist issue (see the Posit create-release-checklist skill for that).
---

# R Package Release Workflow

Covers the part of releasing that isn't checking or checklisting: deciding where a release goes, and actually cutting it.

## 1. Confirm the Distribution Channel First

Never assume CRAN. Before planning anything, determine (or ask) whether this release targets CRAN, r-universe, or both:

- Check `DESCRIPTION` for a CRAN-style `URL`/`BugReports`, and look for `cran-comments.md` (CRAN signal) or `_pkgdown.yml` + a `.github/workflows` job registering the repo with an r-universe org (r-universe signal).
- Check prior release commits/tags (`git log --grep="release\|CRAN\|bump\|v[0-9]"`) for the repo's established pattern — follow it rather than introducing a new one.
- If it's genuinely ambiguous, ask the user before proceeding. Don't silently default to CRAN.

## 2. Pre-Release Checks

- `NEWS.md`'s top section matches the version being released (organize by minor/major per `r-package` conventions).
- `devtools::check()` clean, tests green. If targeting CRAN specifically, hand off to `cran-check` for the full `--as-cran` fix loop first.
- If a release checklist issue doesn't exist yet, the Posit `open-source:create-release-checklist` skill generates one (version bump type, GitHub issue) — use it for planning, not this skill.

## 3. Execute the Release

1. Tag the release commit following the repo's existing tag convention (e.g. `v1.2.3`).
2. Merge the release PR/branch per the repo's normal merge process.
3. Publish: CRAN submission (`devtools::release()` or `usethis::use_release_issue()` flow) or a GitHub release + r-universe picks it up automatically from the tag, depending on channel confirmed in step 1.
4. Bump to a dev version (`usethis::use_dev_version()` or equivalent `.9000` suffix) and commit.

## Works Well With

- `r-package` — style/documentation/API conventions
- `r-testing` — testthat conventions
- `cran-check` — CRAN `--as-cran` check/fix loop
- `open-source:create-release-checklist` (Posit) — generates the release checklist issue and suggests version bump type

## Do NOT Use For

- Running/fixing R CMD check itself (use `cran-check`)
- Generating a release checklist issue (use the Posit `create-release-checklist` skill)
