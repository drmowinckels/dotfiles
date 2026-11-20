# Rollback Runbook

R packages have no feature flags. Reversibility comes from the release channel you're on, so
the cost of a bad change depends entirely on how far it has travelled.

## Stage 1 — merged to main, not released

Cheapest. Revert the commit, push.

```sh
git revert <sha> && git push
```

The dev version on r-universe rebuilds within the hour. Nobody on CRAN is affected.

## Stage 2 — published to r-universe

Users installing from r-universe have it. Still cheap.

1. Revert on main and push — r-universe rebuilds from main.
2. If the bad build is already installed by someone, tell them: `install.packages("<pkg>",
   repos = "https://<org>.r-universe.dev")` after the rebuild completes.

This is why r-universe comes before CRAN. **Let a T2 change sit here before submitting.**

## Stage 3 — on CRAN

Not revertible. There is no unpublish, and the archived version stays archived.

Options, in order of preference:

1. **Patch forward.** Fix, bump the patch version, resubmit. Normal CRAN review latency applies.
   Say in the submission comment that it fixes a regression in the current version — that is
   understood and generally expedited.
2. **Reinstate the old behaviour behind the old default** if the break was a changed default.
   Faster to review than a redesign.
3. **Ask CRAN to archive** only if the package is actively harmful — data corruption, not a
   broken plot. This removes it for everyone and costs reverse dependencies their build.

## Reverse dependencies

Before any T2 reaches stage 3, `revdep-check` must be green. A break that passes your tests and
fails a downstream package's is the expensive kind: you'll learn about it from CRAN's automated
mail, with a deadline attached.

## After any rollback

Write the case into the review eval corpus (`review-eval`). Every incident is a test the
reviewers should have passed, and the point of recording it is that they pass it next time.
