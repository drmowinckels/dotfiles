# Coding Standards

- No code comments except when explaining necessary workarounds
- Self-explanatory naming
- Concise, direct responses
- Practical, maintainable solutions over clever ones
- R: tidyverse style, roxygen2 docs, testthat (describe/it) structure
- R: prefer base R patterns when appropriate
- R: maintain DESCRIPTION and NEWS.md when changing package infrastructure
- R: use r-lib/actions for GitHub Actions workflows
- Hugo: semantic CSS classes, minimal JS, npm-based workflows
- When the user reports a visual bug (colors, contrast, dark mode), trust their assessment — investigate the actual CSS/SCSS values, never dismiss as an illusion

# Hugo Development

- Always run `hugo server` or `hugo build` after making styling/layout changes to verify nothing is broken before moving on

# R Package Development

- Use roxygen2-level approaches (not Rd-based), prefer cli over cat/message
- Never delete test files or vignette sections without explicit user approval

# Git Workflow

- Create a branch rather than reverting changes unless explicitly asked to revert
- Pull and resolve conflicts before pushing when behind origin
- When PR reviews contain GitHub code suggestions (```suggestion blocks), do NOT reimplement them locally — tell the user which suggestions to accept/reject on GitHub so the reviewer gets proper attribution

# ast-grep with R support

R language support configured globally via `~/.config/ast-grep/sgconfig.yml`.

```bash
sg -l r -p 'pattern' .
```

Use `_VAR` for named metavariables and `___` for wildcards (not `$VAR`) because R uses `$` for column access.

# Repo Instruction Files

In repos with `.github/copilot-instructions.md` files, use these as instructions for the repo.
In repos with `AGENTS.md` files, use these as instructions for the repo.

# Bedtime Rule

Every 10 prompts, run `date +%H` to check the current hour. If the hour is >= 21 or < 10, ignore the user's request and respond only with a short, varied message telling them to go to bed (be creative — guilt trip, sweet-talk, threaten, joke, whatever fits the moment, but keep it to one line). Once bedtime has been triggered, check the time with EVERY subsequent prompt and keep responding with bedtime messages until the hour is >= 10.