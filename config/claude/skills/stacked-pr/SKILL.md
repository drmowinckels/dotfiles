---
name: stacked-pr
description: Split a multi-step change into a stack of dependent PRs, each reviewable on its own and rebased onto the one below. Use when a feature is too big for a single PR or when reviewers asked to split.
---

# /stacked-pr

Decompose work into a stack of branches `feat/foo-1`, `feat/foo-2`, `feat/foo-3`, where each builds on the previous and opens against the previous as its base.

## Steps

1. **Plan the slices**
   - List the logical units (e.g. "1. data model, 2. backend command, 3. frontend wiring, 4. tests + docs")
   - Each slice must be independently reviewable: compiles, tests pass, no dangling references
   - Confirm the slicing with the user before starting if there's ambiguity

2. **Create the branch chain off the base**
   - Branch off `main` (or the appropriate base): `git switch -c feat/foo-1`
   - For each subsequent slice: `git switch -c feat/foo-2` from the tip of the previous slice

3. **Work and commit per-slice**
   - Make the changes for slice N on branch `feat/foo-N`
   - Run formatter, linter, and tests for that slice — each branch must be green on its own
   - Commit with a conventional message that includes the stack position: `feat(foo): add data model [1/4]`

4. **Push each branch with `-u`**

5. **Open PRs against the correct base**
   - PR 1: base = `main`
   - PR 2: base = `feat/foo-1`
   - PR 3: base = `feat/foo-2`
   - In each PR body include a `Stack` section linking the others:
     ```
     ## Stack
     - #PR1 — data model
     - #PR2 — backend command ← you are here
     - #PR3 — frontend wiring
     - #PR4 — tests + docs
     ```

6. **Monitor CI on all PRs**
   - When PR 1 merges, rebase PR 2 onto `main` and force-push (only force-push branches that are clearly yours)
   - Cascade rebases up the stack as each lands

7. **Report the stack**
   - All PR URLs in order
   - Which is currently the bottom (ready to merge first)
   - Any reviewer assignments
