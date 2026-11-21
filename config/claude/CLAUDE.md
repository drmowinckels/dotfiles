# Engineering Principles

- **Prefer long-term solutions over short-term gains.** When fixing bugs, building features, or refactoring: address root causes, not symptoms. Patching the surface (try/except around a flaky call, hardcoded value, special case) buys time but compounds technical debt — fix the underlying issue.
- If a long-term fix is significantly larger than the immediate task, surface the tradeoff explicitly: name the quick fix, name the proper fix, and ask which to take. Don't silently choose the shortcut.
- "We'll clean it up later" almost never happens. Build it right the first time, or open a tracked issue before merging the shortcut.
- Verify empirical/technical claims concretely before asserting them (what a tool checks, how something behaves) rather than guessing, and correct yourself if an earlier claim was wrong. For multi-part or ambiguous requests, state your assumptions (target repo/remote, distribution channel, tooling) and a step-by-step plan before large implementation.

# Coding Standards

- No code comments except when explaining necessary workarounds
- Self-explanatory naming
- Concise, direct responses; write large output (reports, generated files) to disk with Write instead of printing it in full in chat
- Practical, maintainable solutions over clever ones
- R: tidyverse style, roxygen2 docs, testthat (describe/it) structure
- Hugo: semantic CSS classes, minimal JS, npm-based workflows
- When the user reports a visual bug (colors, contrast, dark mode), trust their assessment — investigate the actual CSS/SCSS values, never dismiss as an illusion

# Hugo Development

- Always run `hugo server` or `hugo build` after making styling/layout changes to verify nothing is broken before moving on
- Use Hugo Pipes for asset bundling — do not suggest alternative bundling approaches without checking first
- Test dark mode thoroughly after styling changes
- Never revert styling changes without asking — create a branch instead

# R Package Development

R work is frequent here — proactively load the `r-package` skill (style, docs, API conventions) and `r-testing` skill (testthat conventions) at the start of any R package task, and the `r-release` skill when preparing or executing a release. Don't wait for implicit matching; invoke them explicitly if a task touches an R package and they haven't already loaded.

# Git Workflow

- Always create feature branches for fixes — never commit directly to main unless explicitly told to
- When asked to "commit and push", confirm the target branch first
- Create a branch rather than reverting changes unless explicitly asked to revert
- Pull and resolve conflicts before pushing when behind origin
- When PR reviews contain GitHub code suggestions (```suggestion blocks), do NOT reimplement them locally — tell the user which suggestions to accept/reject on GitHub so the reviewer gets proper attribution

# Commit Hygiene

- Before staging, run `git status` and only stage files relevant to the current task
- Never use blanket `git add .` or `git add -A` — stage paths explicitly so pre-existing WIP doesn't get swept in
- Verify shell expansions before destructive git commands; in zsh, history modifiers like `!` can silently drop tokens — quote arguments or `set +H` before running batches
- For bulk PR/branch operations (close, delete, push), dry-run the list first and confirm the count matches expectation before executing

# CI & Quality Gates

- Always run formatter and linter before committing: `cargo fmt && cargo clippy` for Rust, `npm run lint` / `prettier --check` for TS/JS, `air format` + `lintr` for R
- Run the full test suite (all relevant languages) before opening a PR — not just the changed file's tests
- Never commit if formatter or linter fails — fix it first, do not paper over with suppression directives
- Before adding a coverage/lint suppression comment, verify the directive actually applies to the toolchain in use (e.g. `LCOV_EXCL_LINE` does not work with `cargo-llvm-cov`)
- After pushing, monitor CI to green; address codecov/patch failures explicitly rather than ignoring them
- Treat "merged with green CI" as the definition of done, not "code written"
- Monitor CI/PR status by polling (`gh run list`, `gh pr checks`) rather than live-refresh watchers (`gh run watch`) that spam updates
- For repetitive batch fixes across many files (e.g. the same lint/CI failure), consider a headless run (`claude -p "..." --allowedTools ...`) instead of iterating interactively

# PR Workflow

- After implementing changes, open a PR and shepherd it to green CI before declaring done
- Before any final PR/merge, run the `pre-merge-review` skill (risk tier → green checks → parallel fresh-context reviewers → verification → fix → ponytail-review) — `ship` already does this automatically
- PR bodies follow the repo template: Summary / Testing / Risk tier / How to revert. Classify risk from `.github/RISK_TIERS.md`, not from how confident the change feels
- Repos get their reviewer contract from `REVIEW.md` at the root — install it with `review-scaffold` if missing
- Every bug that escapes to users becomes a case in `.review/cases/` via `review-eval`, and the layer that missed it gets fixed, not just the bug
- For multi-step work, prefer stacked PRs over one large PR — each PR should be reviewable on its own
- Write PR descriptions with a Summary; link related issues/PRs
- Add a Test Plan section only for verification CI does not perform — manual checks, depends-only runs, snapshot acceptance rationale. Never restate checks CI already proves green (formatter, linter, test counts, R CMD check status)
- Document any intentionally-failing or skipped checks (e.g. codecov/patch policy exceptions) in the PR description so reviewers know it's deliberate
- When CI fails, fix on the same branch and push — do not open a follow-up PR for CI fixes unless the original is already merged

# Security & Review

- After changes touching auth, network I/O, file I/O, secrets, keychain, or external URLs, proactively run a security review pass
- Never print, echo, or log real credentials, API tokens, or secrets in plaintext — even for diagnostics. Redact values and reference variable/secret names only; don't show partial substrings, prefixes, or suffixes of a real secret either
- Flag any PII, credentials, tokens, or private URLs encountered — but calibrate severity: distinguish exposed credentials (high) from exposed metadata like an email address (low)
- Do not overstate findings; reviewers stop trusting reports that cry wolf
- For security-sensitive features, do a brief threat-model pass before implementing: list inputs, trust boundaries, secrets/PII touched, persistence surfaces, and the top 3 risks the implementation addresses

# ast-grep with R support

R language support configured globally via `~/.config/ast-grep/sgconfig.yml`.

```bash
sg -l r -p 'pattern' .
```

Use `_VAR` for named metavariables and `___` for wildcards (not `$VAR`) because R uses `$` for column access.

# Code Review

- When doing critical code reviews, fix ALL identified issues systematically
- Run the full test suite after each round of fixes and report test counts
- Continue until R CMD check is clean and all tests pass
- Create fixes on a feature branch, not main

# General Workflow

- When the user suggests a tool or approach exists (e.g., an MCP server, a package feature), look for it immediately rather than suggesting manual workarounds

# Test Coverage Discipline

- **New code ships with its tests in the same change.** Don't write the code first, plan to "add tests later," then forget — the test is part of "done."
- For every new function, method, branch, or non-trivial conditional you add, name at least one test that exercises it. If you can't, stop and ask whether the code is really needed.
- Modifying an existing function counts as new code if it changes behaviour or adds a branch. Add or update the corresponding test in the same PR.
- "Untestable" is a specific claim, not an excuse. Acceptable forms: "this rewires a Tauri builder/CLI clap parser with no mockable surface" or "this is a thin shim around an OS syscall with no logic." Generic "it's hard to test" is not acceptable — restructure the code so the testable core is extractable (the `*_impl` / pure-function pattern).
- When the user reports falling coverage, treat it as a process problem: the rule above was skipped on past PRs, not a one-off. Fix the rule's visibility (AGENTS.md, CONTRIBUTING.md) as well as backfilling the missing tests.

# MCP Server Usage

MCP servers are configured in `~/.claude.json` (not `.mcp.json` — that file has a known loading bug when inside `~/.claude/`). Use MCP servers proactively when a task matches their capabilities — don't fall back to manual workarounds. See the `mcp-usage` skill for which server to reach for (filesystem, memory, puppeteer, notebooklm, github, r-btw, Google Workspace).

# Repo Instruction Files

In repos with `.github/copilot-instructions.md` files, use these as instructions for the repo.
In repos with `AGENTS.md` files, use these as instructions for the repo.

# Identity & Attribution

Verified details for authorship, citation files, and package metadata. **Never infer any of these** — in particular, never derive a GitHub handle, username, or profile URL from an email address. If a detail is needed and not listed here, ask rather than guess: wrong identity data propagates into published packages, generated author tables, and permanently archived records (Zenodo, DOIs).

- **Name** (citations, package metadata): Athanasia M. Mowinckel
  - In CITATION.cff: `family-names: "Mowinckel"`, `given-names: "Athanasia M."`
- **GitHub**: [@drmowinckels](https://github.com/drmowinckels)
  - An older handle `athanasiamo` was abandoned years ago; it 404s rather than redirecting, so any link to it is dead. Do not reconstruct it from the gmail address.
- **ORCID**: 0000-0002-5756-0223
- **Affiliation**: Center for Lifespan Changes in Brain and Cognition (LCBC), University of Oslo
- **Website**: https://drmowinckels.io
- **No contact email in public citation metadata** (CITATION.cff, package.json, `.zenodo.json`). ORCID and the repository are sufficient, and these files are mirrored and archived permanently.
