# Dotfiles Repository

This is a macOS dotfiles repository managed with symlinks, Homebrew, and shell scripts.

## Repository Structure

- `config/` — all application configs (claude, git, ssh, vscode, opencode, env)
- `install/` — setup scripts (brew, symlinks, macos defaults)
- `test/` — test suite validating the setup
- `freesurfer_license.txt` — FreeSurfer license (symlinked to $FREESURFER_HOME)

## Rules

### Adding Config Files

New config files go under `config/`, never in the repo root.
When adding a new config file or directory:

1. Add the symlink in `install/symlinks.sh`
2. Add or update tests in `test/tests/`
3. Update `.gitignore` if the tool generates backup, cache, or state files

### External Tool Configuration

When configuring unfamiliar tools, always read the tool's official documentation first.
Never guess at config schemas — fetch the docs, then write the config.

### No Hardcoded Paths or Versions

Use dynamic detection over hardcoded values.
Paths and versions change across machines and over time.

```sh
# Good: Dynamic
FREESURFER_HOME="${FREESURFER_HOME:-/usr/local/freesurfer}"

# Bad: Hardcoded
FREESURFER_HOME="/Applications/freesurfer/7.4.1"
```

### Git Hygiene

Aggressively `.gitignore` backup files, cache directories, IDE state, lock files, and logs.
Before committing, verify no generated files are staged.

### Shell Scripts

- POSIX-compatible `sh` for install scripts (not bash)
- Use the utility functions from `install/lib/utils.sh`
- Lazy loading for expensive operations (e.g., nvm, conda)
