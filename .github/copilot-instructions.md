# Dotfiles Repository

macOS dotfiles with modular installation, Homebrew package management, and shell configuration.

## Structure

```
install/          # Installation scripts (modular, idempotent)
  lib/utils.sh    # Shared logging/utility functions
  apps/           # Manual app installers (not managed by Homebrew)
config/           # Configuration files (symlinked to ~)
  Brewfile        # Homebrew packages and casks
  env/            # Shell environment (zshrc, aliases, exports, functions, path)
  git/            # Git config and global ignore
  ssh/            # SSH config
  claude/         # Claude Code config (symlinked to ~/.claude)
  r/              # R package installation
```

## Key Scripts

- `install.sh` — Full setup for a new Mac (runs all modules in order)
- `update.sh` — Updates everything (git pull, brew, oh-my-zsh, symlinks, plugins)
- `backup.sh` — Backup script
- `test.sh` — Validates setup
- `.macos` — macOS system defaults

## Conventions

- Scripts use `#!/bin/bash` and `set -e`
- Use `log_info`, `log_warn`, `log_error` from `install/lib/utils.sh`
- Install scripts must be idempotent (safe to re-run)
- Brewfile manages all Homebrew packages — use `args: { no_quarantine: true }` for casks that fail Gatekeeper
- Apps not available via Homebrew go in `install/apps/` as standalone scripts
- Shell config is split by concern: `aliases.zsh`, `exports.zsh`, `functions.zsh`, `path.zsh`
- Symlinks are managed in `install/symlinks.sh` — add new ones there

## TODO

- Integrate `install/apps/stretchly.sh` into `install.sh` and `update.sh` once Stretchly is removed from Homebrew. Remove the `stretchly` cask entry from `config/Brewfile` at that point.
