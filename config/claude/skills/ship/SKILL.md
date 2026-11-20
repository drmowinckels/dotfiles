---
name: ship
description: Run formatter, linter, full test suite, commit, push, open a PR, and shepherd it to green CI. Use when the user says "ship it", "open a PR", or wants to finish a feature end-to-end.
---

# /ship

End-to-end shipping flow: from a clean working tree of changes to a merged-ready PR with green CI.

## Steps

1. **Pre-flight check**
   - `git status` to confirm what's staged/unstaged
   - Confirm current branch is not `main` / `master` / `develop`; if it is, create a feature branch first and ask the user for the name
   - Run `git diff` to verify the scope of changes matches what the user asked for

2. **Format & lint** (run the ones that apply to the changed files)
   - Rust: `cargo fmt && cargo clippy --all-targets -- -D warnings`
   - TS/JS: `npm run lint` and/or `prettier --check .`
   - R: `air format <files>` and `Rscript -e 'lintr::lint_package()'`
   - Python: `ruff check . && ruff format --check .`
   - Stop and fix if any of these fail. Do not commit through a failing formatter or linter.

3. **Run the full test suite**
   - Rust: `cargo test --all-features`
   - TS/JS: `npm test`
   - R: `devtools::test()` (and `devtools::check()` if package infrastructure changed)
   - Report counts; do not proceed if anything red.

4. **Pre-merge review** — run the `pre-merge-review` skill (risk tier → green checks → parallel fresh-context reviewers → adversarial verification → fix → simplify → re-test). Do not proceed to commit until it reports clean. If the repo has no `REVIEW.md`, say so and offer `review-scaffold`; don't block on it.

5. **Stage explicitly and commit**
   - List files to add explicitly — no `git add .` or `git add -A`
   - Conventional commit message: `<type>(<scope>): <subject>` (feat/fix/chore/docs/refactor/test)
   - Include Claude Code co-author trailer

6. **Push and open PR**
   - Push the branch with `-u`
   - `gh pr create` with `--title` and a body following the repo's PR template: `## Summary`, `## Testing` (only what CI doesn't prove), `## Risk` (tier from `RISK_TIERS.md`, plus reverse dependencies affected), `## How to revert` (the specific path from `ROLLBACK.md`)
   - Link related issues with `Closes #N` if applicable
   - T0 changes may merge on green CI alone. T1 and T2 get a deliberate cold read of the diff before merge — that read is the only human layer there is, so don't skip it on your own PRs. T2 additionally needs `revdep-check` green and a soak on r-universe before CRAN.

7. **Monitor CI to green**
   - Poll `gh pr checks` until all checks complete
   - If anything red: read the failing log, fix on the same branch, push, and continue monitoring
   - For codecov/patch failures: if the project has a documented exception policy, note it in the PR body; otherwise add the missing tests
   - Do not declare done until every required check is green

8. **Report**
   - PR URL, final commit SHA, check status, any reviewer assignments, and a one-line summary of what pre-merge-review changed
