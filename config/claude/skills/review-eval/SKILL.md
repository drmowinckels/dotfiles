---
name: review-eval
description: Maintain the review regression corpus — record bugs that escaped to users as test cases the reviewers must catch, and measure the false-positive rate against known-clean code. Use after an incident or bad release, or when review findings start feeling noisy.
---

# Review Eval

Reviewers that are never measured drift. This skill keeps two numbers honest: what the review
gate **misses**, and what it **invents**.

Corpus lives in `.review/cases/` in each repo, one Markdown file per case, committed.

## Recording an escape

When a bug reaches users that `pre-merge-review` should have caught, write
`.review/cases/<yyyy-mm-dd>-<slug>.md`:

```markdown
---
kind: escape
severity: important
found_by: user report | CRAN check | revdep | me
commit: <sha that introduced it>
fixed_in: <sha that fixed it>
---

## What broke
One paragraph. The user-visible symptom.

## The diff that caused it
The specific hunk, inline.

## Why review missed it
Which layer should have caught it — a reviewer dimension, REVIEW.md, a test, CI — and why it
didn't. This is the useful part; be specific.

## What the reviewer should say now
The exact finding, in the format fresh-eyes-reviewer emits: location, claim, failure scenario.
```

Then **fix the layer**, not just the bug: add the rule to `REVIEW.md`, add the dimension to the
fan-out, add the CI check, or add the test. A case with no layer change is a note, not a fix.

## Running the corpus

On request, or before changing reviewer prompts or `REVIEW.md`:

1. For each `kind: escape` case, hand the recorded diff to `fresh-eyes-reviewer` with no other
   context — no answer key, no hint about where the bug is.
2. Score: did it produce the finding? Partially — right file, wrong reason? Not at all?
3. Report pass rate, and name every case that regressed since the last run.

A prompt or `REVIEW.md` change that drops the pass rate gets reverted, however good it looks.

## Measuring false positives

The failure mode that kills a review channel isn't missing bugs, it's crying wolf.

1. Pick 3–5 diffs from commits that have been in release for months with no incident. These are
   the clean set.
2. Run the full `pre-merge-review` fan-out on each, through verification.
3. Count **Important** findings that survive verification. On clean code the expected count is
   zero; anything confirmed here is either a real latent bug — investigate it — or the reviewers
   are too aggressive.
4. Record the rate in `.review/fp-log.md` with the date and reviewer version.

Also track, informally, what you do with each finding in real reviews: fixed, dismissed, or
"intentional". A dimension whose findings you dismiss most of the time should be narrowed or cut.

## Cadence

- After every incident, bad release, or CRAN complaint — record the case immediately
- Before any edit to reviewer prompts or `REVIEW.md` — run the corpus
- Quarterly — run the false-positive check

## Works Well With

- `pre-merge-review` — Phase 8 feeds this skill
- `review-scaffold` — corpus results tell you what belongs in `REVIEW.md`
