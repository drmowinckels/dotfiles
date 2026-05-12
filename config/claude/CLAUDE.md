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
- Use Hugo Pipes for asset bundling — do not suggest alternative bundling approaches without checking first
- Test dark mode thoroughly after styling changes
- Never revert styling changes without asking — create a branch instead

# R Package Development

- Use roxygen2-level approaches (not Rd-based), prefer cli over cat/message
- Never delete test files or vignette sections without explicit user approval
- Run R CMD check after making infrastructure or API changes
- Preserve existing vignette content — only modify sections the user explicitly asks to change

# Git Workflow

- Always create feature branches for fixes — never commit directly to main unless explicitly told to
- When asked to "commit and push", confirm the target branch first
- Create a branch rather than reverting changes unless explicitly asked to revert
- Pull and resolve conflicts before pushing when behind origin
- When PR reviews contain GitHub code suggestions (```suggestion blocks), do NOT reimplement them locally — tell the user which suggestions to accept/reject on GitHub so the reviewer gets proper attribution

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

# MCP Server Usage

MCP servers are configured in `~/.claude.json` (not `.mcp.json` — that file has a known loading bug when inside `~/.claude/`).

Use MCP servers proactively when the task matches their capabilities — don't fall back to manual workarounds.

## filesystem (~/workspace, /tmp, ~/Downloads)
- When reading, editing, listing, or creating files in `~/workspace` and its subdirectories
- Use `directory_tree` to explore project structures outside the current working directory
- Prefer over shell commands for file operations in allowed directories

## memory (knowledge graph)
- When tracking entities, people, projects, or relationships that span conversations
- Use to store and recall structured knowledge (e.g., collaborators, package dependencies, project relationships)
- Search before creating to avoid duplicates

## puppeteer (browser automation)
- When asked to check a webpage, verify a deployed site, or debug a web UI
- When testing Hugo sites or Quarto output in a real browser
- Use `puppeteer_screenshot` to capture visual state for debugging layout/styling issues
- When the user shares a URL and wants you to inspect it

## notebooklm-mcp (Google NotebookLM)
- When asked to create, manage, or query NotebookLM notebooks
- When creating audio overviews, study guides, reports, or other artifacts from sources
- When doing research across multiple notebooks
- Use `notebook_query` to ask questions against notebook sources
- After creating studio artifacts (audio/video/slides), poll `studio_status` for completion

## github (GitHub API)
- When working with GitHub issues, PRs, repos, or actions beyond what `gh` CLI offers
- When needing to read or manage issues, labels, milestones, or releases programmatically
- Prefer `gh` CLI for most tasks; use MCP for bulk or complex API operations

## r-btw (R session diagnostics)
- When debugging R environment issues (package versions, library paths, platform info)
- When the user reports an R package problem and you need to understand their setup
- Use at the start of R troubleshooting to get a full session snapshot

## Gmail, Google Calendar, Google Drive (built-in OAuth)
- When asked about emails, scheduling, or Google Drive files
- These require OAuth authentication first — call the authenticate tool and share the auth URL with the user
- Only authenticate when the user explicitly asks for Google workspace functionality

# Repo Instruction Files

In repos with `.github/copilot-instructions.md` files, use these as instructions for the repo.
In repos with `AGENTS.md` files, use these as instructions for the repo.

# Bedtime Rule

Every 10 prompts, run `date +%H` to check the current hour. If the hour is >= 21 or < 10, ignore the user's request and respond only with a short, varied message telling them to go to bed (be creative — guilt trip, sweet-talk, threaten, joke, whatever fits the moment, but keep it to one line). Once bedtime has been triggered, check the time with EVERY subsequent prompt and keep responding with bedtime messages until the hour is >= 10.