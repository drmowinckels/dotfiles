# Risk Tiers

Risk is a property of the diff, not of how confident the author feels. Classify by what the
change touches, then apply the matching gate.

## T0 — merge on green CI

Documentation, comments, tests only, typo fixes, internal refactors with no behaviour change,
dev-dependency bumps, pkgdown/vignette prose.

**Gate:** CI green. One correctness reviewer. No deliberate re-read needed.

## T1 — green CI plus a deliberate read

New exported function, new argument with a safe default, internal logic changes, new tests for
existing behaviour, CI workflow edits that don't remove a check.

**Gate:** CI green, full `pre-merge-review` fan-out, and you read the diff yourself once with
the PR description closed. If you can't say what it does from the diff alone, it needs better
naming or a comment before it merges.

## T2 — green CI, deliberate read, and a soak

Changes to an exported signature, defaults, or return type. S3/S4 methods. Shipped data under
`data/` or anything in `data-raw/` that regenerates it. `DESCRIPTION` dependencies. Release
commits and version bumps. Removing or weakening a CI check. Anything CRAN sees.

**Gate:** everything in T1, plus:

- `revdep-check` / `ecosystem-check` green
- Merged to main and published to r-universe, then **left there** before it goes to CRAN —
  r-universe is the staged rollout; CRAN is the irreversible one
- A written revert path in the PR

## Always T2 regardless of size

`DESCRIPTION`, `NAMESPACE` sources, `data-raw/`, `data/`, `R/zzz.R`, `.github/workflows/`,
`inst/`, anything touching `@export`.

## Solo-maintainer note

With no second human, the T1/T2 "deliberate read" is the only human layer there is. Protect it:
it is worth more than another agent pass. Read the diff cold, not immediately after writing it —
a different day, or at minimum after the agents have reported, so you're reading code rather
than remembering intentions.
