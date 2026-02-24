# Dotfiles

This repository contains my macOS configuration files (dotfiles) to help me quickly set up and maintain my Mac development environment. It automates the installation of applications, tools, and settings needed for neuroscience research and development work.

## Features

- **Automated setup**: One command to install everything
- **Modular installation**: Install components separately if needed
- **Idempotent scripts**: Safe to run multiple times
- **Secure secrets management**: Environment variables kept out of version control
- **Backup system**: Automated backup of git repositories and settings

## What's Included

### Development Tools
- Homebrew packages (see `Brewfile`)
- Oh My Zsh with plugins
- Git configuration
- VSCode/Positron settings and extensions

### Research Tools
- R and RStudio configuration
- FreeSurfer setup
- FSL configuration
- Python environment

### Productivity Apps
- Browser, communication tools
- Password managers
- Document management
- And more (see `Brewfile`)

## Fresh macOS Setup

### Before Reinstalling

Make sure you:

1. Commit and push all git repository changes
2. Save important non-iCloud documents
3. Export data from local databases
4. Run `./backup.sh` to backup repositories and settings
5. Update Mackup: `mackup backup`

### Clean Installation

1. Update macOS to the latest version
2. Install Xcode from the App Store and accept license
3. Install Command Line Tools: `xcode-select --install`
4. Copy SSH keys to `~/.ssh` with permissions `600`
5. Clone this repo: `git clone <your-repo-url> ~/.dotfiles`
6. Run the installer: `cd ~/.dotfiles && ./install.sh`
7. Copy `.env.example` to `.env` and add your secrets
8. Restore Mackup settings: `mackup restore`
9. Optionally run `./.macos` to set macOS defaults
10. Restart your computer

## Installation Scripts

The installation is modularized into separate components:

- `install/homebrew.sh` - Install Homebrew and packages
- `install/symlinks.sh` - Create configuration symlinks
- `install/mackup.sh` - Setup Mackup for settings sync
- `install/shell.sh` - Install Oh My Zsh and plugins
- `install/workspace.sh` - Clone workspace repositories
- `install/apps.sh` - Setup Positron, R, and other apps
- `install/claude.sh` - Install Claude Code CLI

Run them individually if you only need specific components:

```bash
./install/homebrew.sh
./install/symlinks.sh
# etc...
```

## File Structure

```
.dotfiles/
├── config/
│   ├── env/              # Shell environment (zshrc, aliases, exports, path)
│   ├── git/              # Git configuration
│   ├── ssh/              # SSH configuration
│   ├── vscode/           # VSCode/Positron settings and extensions
│   ├── claude/           # Claude Code settings, skills, and commands
│   ├── opencode/         # OpenCode configuration
│   ├── r/                # R package installation
│   ├── Brewfile          # Homebrew packages
│   └── .mackup.cfg       # Mackup settings sync
├── install/              # Modular installation scripts
├── test/                 # Test suite for setup validation
├── install.sh            # Main installation script
├── backup.sh             # Backup script
├── update.sh             # Update script
├── test.sh               # Run tests
└── .macos                # macOS defaults
```

## Maintenance

### Update Everything

Run the update script to pull changes and update packages:

```bash
./update.sh
```

### Backup Repositories

The backup script will:
- Run Mackup backup
- Find all git repos modified in the last 6 months
- Commit changes and push to remote
- Save VSCode extensions list

```bash
./backup.sh
```

### Test Configuration

Validate your dotfiles setup:

```bash
./test.sh
```

## Customization

### Adding Packages

Edit `Brewfile` to add new Homebrew packages:

```ruby
brew 'package-name'        # CLI tool
cask 'app-name'           # GUI application
```

Then run: `brew bundle --file=Brewfile`

### macOS Defaults

Customize macOS settings in `.macos`, then run:

```bash
./.macos
```

## Domain-Specific Setup

This configuration includes tools specific to neuroscience research:

- **FreeSurfer**: Brain imaging analysis
- **FSL**: FMRIB Software Library
- **LCBC Server Access**: SSH/SSHFS configurations for UiO servers
- **R Packages**: Statistical computing packages

If you're forking this repo and don't need these, you can safely remove or comment out related sections in:
- `install/symlinks.sh` (FreeSurfer license)
- `env/exports.zsh` (FSL, FreeSurfer exports)
- `env/aliases.zsh` (Server connections)
- `env/path.zsh` (FSL, FreeSurfer paths)

## Troubleshooting

**Installation fails on symlinks**: The scripts are idempotent and will backup existing files. Check for `.backup` files.

**FreeSurfer/FSL errors**: Make sure these are installed before running the dotfiles installer, or comment out related sections.

**Git authentication fails**: Ensure SSH keys are properly set up in `~/.ssh` with correct permissions.

**Mackup restore issues**: Check that Dropbox is synced before running `mackup restore`.

## Credits

Originally inspired by [Dries Vints' dotfiles](https://github.com/driesvints/dotfiles) and the [GitHub does dotfiles](https://dotfiles.github.io/) project.

Additional inspiration from:
- [Mathias Bynens' dotfiles](https://github.com/mathiasbynens/dotfiles)
- [Zach Holman's dotfiles](https://github.com/holman/dotfiles)

## License

See [license.md](license.md)
