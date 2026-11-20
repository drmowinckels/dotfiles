---
name: mcp-usage
description: Which MCP server to reach for and when — filesystem (~/workspace, /tmp, ~/Downloads), memory (knowledge graph), puppeteer (browser automation/screenshots), notebooklm-mcp (NotebookLM notebooks/studio), github (issues/PRs/bulk API ops), r-btw (R session diagnostics), Gmail/Calendar/Drive (Google Workspace, OAuth). Use when a task might be served by a configured MCP server instead of a manual/shell workaround.
---

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
