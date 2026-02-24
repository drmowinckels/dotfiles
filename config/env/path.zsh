# PATH Management
# Order matters: earlier entries take precedence

# Local bin directories first
export PATH="/usr/local/bin:/usr/local/sbin:$PATH"

# Homebrew-installed packages
export PATH="/usr/local/opt/sqlite/bin:$PATH"
export PATH="/usr/local/opt/libpq/bin:$PATH"
export PATH="/opt/homebrew/opt/libxml2/bin:$PATH"

# XQuartz (X11)
export PATH="/opt/X11/bin:$PATH"

# Make sure coreutils are loaded before system commands
# Disabled for now because we only use "ls" which is referenced in aliases
#export PATH="$(brew --prefix coreutils)/libexec/gnubin:$PATH"

