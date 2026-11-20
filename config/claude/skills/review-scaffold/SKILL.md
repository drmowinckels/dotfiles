---
name: review-scaffold
description: Install the per-repo review contract into a repository — REVIEW.md, RISK_TIERS.md, ROLLBACK.md, and a PR template with Testing/Risk/How-to-revert. Use when a repo has no REVIEW.md, when pre-merge-review says the reviewer contract is missing, or when setting up a new package.
---

# Review Scaffold

Drops the four files that make automated review specific to a repository instead of generic.
Templates live in `~/.claude/templates/review/`.

## What goes where

| Template | Destination | Purpose |
|---|---|---|
| `REVIEW.md` | `.review/` | The reviewer contract: what failure means here, nit budget, skip paths. Keep it out of the repo root — the root is for the package, not for agent files. In an R package, add `^\.review$` to `.Rbuildignore`. |
| `RISK_TIERS.md` | `.github/` | T0/T1/T2 definitions and the gate each one gets |
| `ROLLBACK.md` | `.github/` | One-step revert path per release stage |
| `pull_request_template.md` | `.github/` | Forces Testing / Risk / How to revert on every PR |

## Steps

1. **Check what's already there.** Never overwrite an existing `REVIEW.md` or PR template — read
   it, report the gaps against the template, and offer to merge rather than replace.

2. **Copy the templates in**, then **fill the brackets from the actual repo** — this is the whole
   value of the skill; a scaffold left generic is worse than none, because reviewers will treat
   its placeholders as real rules. Read the repo first and write real content:
   - `DESCRIPTION` → package purpose, dependencies, who depends on it
   - `NAMESPACE` → the exported surface that T2 protects
   - `.github/workflows/` → which checks already run, so `REVIEW.md` doesn't ask reviewers to
     duplicate them
   - `R/` → the project-specific failure modes worth naming (for ggsegverse: atlas region counts,
     palette integrity, `ggseg.formats` compatibility)
   - existing `AGENTS.md` / `CLAUDE.md` → conventions, so the two files don't contradict

3. **Trim the skip-paths list** to what the repo actually generates. A skip path for a directory
   that doesn't exist teaches the reviewer nothing.

4. **Add the always-T2 paths** that are real for this repo.

5. **Report** which files were created, which were left alone, and every placeholder still
   unfilled — those are decisions only the maintainer can make.

## Rules

- `REVIEW.md` is short. If it grows past a screen, reviewers skim it and the specificity is lost.
- It states standards, never file inventories or version numbers — those rot.
- Don't add a rule CI already enforces. Duplicated gates produce duplicate findings.

## Works Well With

- `pre-merge-review` — reads every file this creates
- `review-eval` — the corpus that proves `REVIEW.md` is tuned correctly
