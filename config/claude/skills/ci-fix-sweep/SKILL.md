---
name: ci-fix-sweep
description: Fix CI failures across multiple repos in a GitHub org using parallel sub-agents
user_invocable: true
---

# Multi-Repo CI Fix Sweep

Fix CI failures across repos in a GitHub organisation using parallel sub-agents.

## Usage

```
/ci-fix-sweep <org> [repo-filter]
```

- `<org>` — GitHub organisation (e.g., `ggsegverse`)
- `[repo-filter]` — optional grep pattern to limit repos (e.g., `ggseg` to match only ggseg-prefixed repos)

## Workflow

1. **Discover repos** — List all repos in the org, optionally filtered. Use `gh` CLI:
   ```bash
   gh repo list <org> --limit 100 --json name,defaultBranchRef
   ```

2. **Check CI status** — For each repo, get the latest workflow run status:
   ```bash
   gh run list -R <org>/<repo> --limit 1 --json status,conclusion,name
   ```

3. **Triage** — Present a table of repos with their CI status:
   ```
   | Repo | Workflow | Status | Conclusion |
   ```
   Ask the user which repos to fix (default: all failing).

4. **Fix in parallel** — Spawn sub-agents (4 at a time) using the Agent tool. Each agent gets this brief:

   > Fix CI for `<org>/<repo>`:
   > 1. Clone to a temp directory or use worktree isolation
   > 2. Read the failing workflow YAML from `.github/workflows/`
   > 3. Read recent failure logs: `gh run view <run-id> -R <org>/<repo> --log-failed`
   > 4. Diagnose the root cause (deprecated actions, dependency issues, R CMD check failures, etc.)
   > 5. Create a feature branch: `ci/fix-<issue>`
   > 6. Apply the fix
   > 7. If it's an R package, run `Rscript -e 'devtools::check()'` locally to verify
   > 8. Commit, push, and open a PR with a summary of the issue and fix
   > 9. Return: repo name, issue found, fix applied, PR URL

5. **Report** — After all agents complete, present a summary table:
   ```
   | Repo | Issue | Fix | PR | Status |
   ```

## Guidelines

- Always use feature branches, never push to main/default
- Use `r-lib/actions` for R package CI workflows
- Check if the fix is the same across repos (e.g., action version bump) — if so, mention this pattern
- If a repo needs a fix you can't verify locally (e.g., Windows-only failure), note it and open the PR anyway with a clear description
- Rate-limit API calls: batch 4 repos at a time, not all at once
