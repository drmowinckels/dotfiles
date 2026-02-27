# Command Shortcuts
alias ll='ls -ahlF'
alias la='ls -la'
alias lh='ll -lhrt'
alias lsd='ls -d */'
alias shrug='echo "¯\_(ツ)_/¯" | pbcopy'
alias c='clear'
alias fnd='ps ax | grep'
alias cat='ccat'

# ast-grep with R support
alias sg='ast-grep run -c ~/.config/ast-grep/sgconfig.yml'

# Dotfiles
alias dot='cd $DOTFILES'
alias dotup='$DOTFILES/update.sh'
alias library='cd $HOME/Library'
alias ws='cd $HOME/workspace'

# Hugo
alias hugos='hugo server -D -F --renderToMemory'

# R and IDEs
alias r='radian'
alias rstudio='/Applications/RStudio.app/Contents/MacOS/RStudio'
alias positron="/Applications/Positron.app/Contents/Resources/app/bin/code"

# Python
alias python='python3'
alias pip='pip3'
alias py='python'

# SSHFS Mounts
alias lcbc='sshfs athanasm@login1.uio.no:/net/hypatia/uio/fs01/lh-sv-psi/LCBC ~/lcbc -o auto_cache,reconnect,defer_permissions,noappledouble,negative_vncache,volname=LCBC'
alias linux='sshfs athanasm@login1.uio.no:/uio/kant/sv-psi-u1/athanasm ~/uio -o auto_cache,reconnect,defer_permissions,noappledouble,negative_vncache,volname=UIO'

# SSH Connections
alias uio='ssh -Y athanasm@login.uio.no'
alias tom='ssh ubuntu@tom.lcbc.uiocloud.no'
alias study='ssh debian@study.lcbc.uiocloud.no'
alias jerry='ssh ubuntu@jerry.lcbc.uiocloud.no'
alias p23='sftp p23-athanasm@tsd-fx01.tsd.usit.no:p23'
alias p274='sftp p274-athanasm@tsd-fx01.tsd.usit.no:p274'
