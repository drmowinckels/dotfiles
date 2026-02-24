# OpenCode + Claude Code Integration

This configuration integrates OpenCode with Claude Code so both tools share settings, skills, and MCP servers.

## How It Works

### Shared Skills

OpenCode automatically searches Claude Code skill directories:
- `~/.claude/skills/<name>/SKILL.md` (global)
- `.claude/skills/<name>/SKILL.md` (project)

No duplication needed. Skills work in both tools if they have valid YAML frontmatter:

```yaml
---
name: skill-name          # lowercase, alphanumeric, hyphens only
description: "..."        # required
license: CC-BY-4.0        # optional
compatibility: opencode   # optional but recommended
---
```

### Shared Instructions

The global `opencode.json` references Claude Code's instruction file:

```json
"instructions": [
  "{file:~/.claude/CLAUDE.md}"
]
```

Edit `~/.claude/CLAUDE.md` and both tools pick up the changes.

For project-specific instructions, add a project-level `opencode.json`:

```json
{
  "instructions": [
    "{file:.github/copilot-instructions.md}"
  ]
}
```

OpenCode merges project config with global config automatically.

### Shared MCP Servers

Both configs define the same MCP servers:
- **Claude Code**: `~/.claude/settings.json` → `mcpServers`
- **OpenCode**: `~/.config/opencode/opencode.json` → `mcpServers`

Keep these in sync manually, or create a script to generate both from a single source.

### File Exclusions

Both tools use the same ignore patterns (R project files, node_modules, etc).

## File Locations

| Purpose | Claude Code | OpenCode |
|---------|-------------|----------|
| Global config | `~/.claude/settings.json` | `~/.config/opencode/opencode.json` |
| Instructions | `~/.claude/CLAUDE.md` | via `instructions` config |
| Skills | `~/.claude/skills/` | same (auto-discovered) |
| Project config | `.claude/settings.json` | `opencode.json` or `.opencode/` |

## Workflow Tips

**Use Claude Code for:**
- Complex multi-file refactors (better context management)
- When you want Anthropic's native tooling

**Use OpenCode for:**
- Switching models mid-task (Gemini for large context, etc.)
- Local/private model usage
- GitHub Actions integration (`/opencode` in comments)

## Adding New Skills

1. Create `~/.claude/skills/<skill-name>/SKILL.md`
2. Add valid YAML frontmatter with `name` matching directory
3. Both tools will discover it automatically

## Keeping MCP Servers in Sync

When adding a new MCP server, update both:
- `~/.claude/settings.json`
- `~/.dotfiles/config/opencode/opencode.json`
