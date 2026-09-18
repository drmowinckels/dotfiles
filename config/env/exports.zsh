# Environment Variables

# Load sensitive variables from .env if it exists
if [ -f "$HOME/.dotfiles/.env" ]; then
    source "$HOME/.dotfiles/.env"
fi


# GitHub PAT for R tools (using GITHUB_PAT, not GITHUB_TOKEN, to avoid blocking gh auth login)
export GITHUB_PAT=$(gh auth token 2>/dev/null || echo "")

# OpenCode configuration
export OPENCODE_CONFIG_DIR="$HOME/.dotfiles/opencode"

# R Studio
export RSTUDIO_WHICH_R=/usr/local/bin/R

# Keg-only Homebrew formulae for configure scripts that use pkg-config
# (compiler flags for the same formulae live in config/r/Makevars)
if [[ -n "$HOMEBREW_PREFIX" && -r "$DOTFILES/config/r/keg-only-formulae" ]]; then
    for formula in ${(f)"$(sed -e 's/#.*//' "$DOTFILES/config/r/keg-only-formulae")"}; do
        [[ -z "$formula" ]] && continue
        pc_dir="$HOMEBREW_PREFIX/opt/$formula/lib/pkgconfig"
        [[ -d "$pc_dir" ]] && export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:+$PKG_CONFIG_PATH:}$pc_dir"
    done
    unset formula pc_dir
fi

# Fix for fork safety
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

# XQuartz
export DYLD_FALLBACK_LIBRARY_PATH="/opt/X11/lib:$DYLD_FALLBACK_LIBRARY_PATH"

# FSL
for fsl_path in /usr/local/fsl /opt/fsl ~/fsl; do
    if [[ -d "$fsl_path" && -f "$fsl_path/etc/fslconf/fsl.sh" ]]; then
        export FSLDIR="$fsl_path"
        . ${FSLDIR}/etc/fslconf/fsl.sh
        export PATH="${FSLDIR}/bin:${PATH}"
        break
    fi
done

# FreeSurfer
if [[ -d /Applications/freesurfer ]]; then
    export FREESURFER_HOME=$(ls -d /Applications/freesurfer/*/ 2>/dev/null | sort -V | tail -1 | sed 's:/$::')
elif [[ -d /usr/local/freesurfer ]]; then
    export FREESURFER_HOME=$(ls -d /usr/local/freesurfer/*/ 2>/dev/null | sort -V | tail -1 | sed 's:/$::')
fi

if [[ -n "$FREESURFER_HOME" && -d "$FREESURFER_HOME" ]]; then
    source $FREESURFER_HOME/SetUpFreeSurfer.sh
    export PATH="$PATH:${FREESURFER_HOME}/bin"
fi

if [[ -d /Applications/wb_view.app ]]; then
    export PATH=/Applications/wb_view.app/Contents/usr/bin:$PATH
fi
