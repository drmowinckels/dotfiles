---
name: pre-merge-review
description: Layered pre-PR review — green checks first, then parallel fresh-context reviewers, adversarial verification of every finding, fix, simplify, re-test. Use before opening or merging any final PR, or when the user asks for a "final review", "pre-merge check", or to run the review trio. Also invoked automatically by /ship.
---

# Pre-Merge Review

The most valuable review happens before anyone else looks at the change. This skill is that gate: it runs the checks, dispatches reviewers who have never seen your reasoning, throws away the findings that don't survive scrutiny, fixes what's left, and proves the result still passes.

Findings are tagged **Important**, **Nit**, or **Pre-existing**. Only Important blocks.

## Phase 0 — Context and risk tier

1. Read the repo's review contract — `.review/REVIEW.md` first, then `REVIEW.md` at the root for repos not yet moved. It is the code owner's contract: what counts as failure here, what to skip, how many nits are tolerable. It outranks your defaults. If there is none, say so once and suggest `review-scaffold`.
2. Read `AGENTS.md` / `CLAUDE.md` for stack and conventions.
3. State the diff's **risk tier** (see `RISK_TIERS.md` if present, else judge it) and say which paths pushed it there. The tier sets review depth: T0 gets one reviewer, T1 gets the full fan-out, T2 gets the full fan-out plus reverse-dependency and ecosystem checks.

## Phase 1 — Green before review

Run the formatter, linter, build, and full test suite **first**.

Name each command you ran and its result in the report. A phase that was
skipped is reported as skipped, never as passed: this gate exists because a
green CI run and a human review both missed a change that disabled every
boundary edge in ggseg3d, and the test that should have caught it asserted
against a literal.

- R: `air format`, `lintr::lint_package()`, `devtools::test()`, and `devtools::check()` when package infrastructure changed
- Rust: `cargo fmt`, `cargo clippy --all-targets -- -D warnings`, `cargo test --all-features`
- TS/JS: `npm run lint`, `npm test`
- Hugo: `hugo build`

Do not review a red diff. Reviewing code that is about to change is wasted effort, and reviewers will chase failures that the test suite already named. Fix, then proceed.

## Phase 2 — Fan out (parallel, fresh context)

Dispatch in a single message so they run concurrently. Each gets the diff, the stated intent, and `REVIEW.md`:

- `fresh-eyes-reviewer` on **correctness** — logic, edge cases, `NA`/`NULL`/zero-length/length-mismatch, error paths
- `fresh-eyes-reviewer` on **contracts and blast radius** — callers, exported API, S3/S4 dispatch, reverse dependencies, anything the diff breaks that isn't in the diff
- `fresh-eyes-reviewer` on **test coverage** — every new branch, every modified behaviour; name the test that exercises it or flag it. For each new or changed test, the reviewer answers one question: **what would have to break for this test to fail?** A test whose assertion holds for a literal, an empty object, or a mock compared against itself is a coverage gap reported as coverage, and is an Important finding. Where the answer is not obvious, mutate the code or data and confirm the test goes red — under `devtools::load_all()` that means editing the source and reloading, because `assignInNamespace()` does not take effect.
- the `posit-dev:critical-code-reviewer` **skill** for the structured severity pass — it is a skill, not an agent, so invoke it with `Skill`, or hand its SKILL.md to an `Agent` as the reviewer's brief. There is no agent by that name; dispatching one as an agent type fails silently and the pass never runs.
- a security pass over the pending changes. `/security-review` is a built-in the **user** types; you cannot invoke it. Dispatch a `fresh-eyes-reviewer` on security instead — auth, network and file I/O, secrets, external URLs — and say in the report that this stood in for `/security-review`.

For T0 changes, correctness alone is enough. Don't spend five agents on a typo fix.

## Phase 3 — Verify before you trust

Every **Important** finding goes to `review-verifier`, one agent per finding, dispatched in parallel.

- Drop anything returned `REJECTED`. Do not relay it, do not mention it as a maybe.
- Where two reviewers independently found the same thing, that agreement raises confidence — note it, but still verify.
- Nits skip verification; apply judgment and keep them few.

This phase is the point of the whole skill. A review channel people trust is one where nothing arrives that isn't real.

## Phase 4 — Fix

Fix **every** confirmed Important finding, not a subset. Re-run the relevant tests after each logical group. Take the nits worth taking; for each one you skip, say why in one line.

**New code ships with its tests in the same change.** For every new branch or changed behaviour, name the test that covers it. If you can't, that is itself an Important finding.

## Phase 5 — Simplify, then re-test

Run `/simplify` last, once correctness and security fixes have landed, so it isn't tidying code that's about to change. It edits directly. Then run the full suite once more.

## Phase 6 — Converge or stop

Track the round count.

- Rounds 2 and 3 review **only the new diff** since the previous round. Do not re-raise findings already dismissed with a reason.
- After **three** rounds with Important findings still appearing, stop fixing and say so: the approach is probably wrong, not the details. Put the question to the user rather than starting round four.

## Phase 7 — Report

- Risk tier and what set it
- Important findings: confirmed, fixed
- Findings raised but **rejected in verification** — count only, with one example. This number is the health metric for the reviewers; if it's consistently high, the prompts or `REVIEW.md` need work.
- Nits taken vs skipped, with reasons
- What `/simplify` changed
- Final test counts and check status
- Rounds used

## Phase 8 — Feed the eval loop

If a bug reaches users that this gate should have caught, record it as a case with `review-eval`. That corpus is what keeps the reviewers improving instead of drifting.

## Works Well With

- `ship` — calls this skill before commit/push
- `review-scaffold` — creates the `REVIEW.md`, risk tiers, PR template, and rollback runbook this skill reads
- `review-eval` — regression corpus and false-positive measurement
- `cran-check` / `r-release` — run this after `cran-check` passes, before `r-release` executes

## Do NOT Use For

- Quick WIP checkpoints — this is a final gate, not a per-commit habit
- Bug hunting alone (use `/code-review` directly)
