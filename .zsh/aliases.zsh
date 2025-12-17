# =============================================================================
# aliases.zsh - Aliases and named directories
# =============================================================================

# -----------------------------------------------------------------------------
# Safety Aliases
# -----------------------------------------------------------------------------
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# -----------------------------------------------------------------------------
# Directory Listing
# -----------------------------------------------------------------------------
if [[ "$MACHINE_OS" == "macosx" ]]; then
    # Prefer GNU ls if available (brew install coreutils)
    if (( $+commands[gls] )); then
        alias ls='gls --color=auto'
    else
        alias ls='ls -G'
    fi
    # GNU dircolors
    (( $+commands[gdircolors] )) && alias dircolors='gdircolors'
elif [[ "$MACHINE_OS" == "ubuntu" ]]; then
    alias ls='ls --color=auto'
fi

alias ll='ls -lh'
alias la='ls -A'
alias lla='ls -lAh'
alias l='ls -CF'
alias sl='ls'  # Typo correction

# -----------------------------------------------------------------------------
# Grep with Color
# -----------------------------------------------------------------------------
if [[ "$MACHINE_OS" == "macosx" ]] && (( $+commands[ggrep] )); then
    alias grep='ggrep --color=auto'
else
    alias grep='grep --color=auto'
fi
alias egrep='grep -E'
alias fgrep='grep -F'

# -----------------------------------------------------------------------------
# Vim Aliases
# -----------------------------------------------------------------------------
alias vi='vim'
alias vimsplit='vim -o'
alias vimvsplit='vim -O'
alias vimsp='vim -o'
alias vimvsp='vim -O'
alias vimtab='vim -p'

# -----------------------------------------------------------------------------
# Tmux
# -----------------------------------------------------------------------------
alias back='tmux -2 attach'
alias tls='tmux list-sessions'
alias tnew='tmux new-session -s'

# -----------------------------------------------------------------------------
# Git Shortcuts
# -----------------------------------------------------------------------------
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'

# -----------------------------------------------------------------------------
# Quick Navigation
# -----------------------------------------------------------------------------
alias q='exit'
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# -----------------------------------------------------------------------------
# Clipboard (platform-specific)
# -----------------------------------------------------------------------------
if [[ "$MACHINE_OS" == "ubuntu" ]]; then
    if (( $+commands[xclip] )); then
        alias pbcopy='xclip -selection clipboard -i'
        alias pbpaste='xclip -selection clipboard -o'
    elif (( $+commands[xsel] )); then
        alias pbcopy='xsel --clipboard --input'
        alias pbpaste='xsel --clipboard --output'
    fi
fi

# -----------------------------------------------------------------------------
# Syntax Highlighting with Pygments
# -----------------------------------------------------------------------------
if (( $+commands[pygmentize] )); then
    alias pcat='pygmentize -g'
fi

# -----------------------------------------------------------------------------
# Named Directories (cd ~name)
# -----------------------------------------------------------------------------
hash -d dl="$HOME/Downloads"
hash -d docs="$HOME/Documents"
hash -d desktop="$HOME/Desktop"
hash -d github="$HOME/github"

# Dropbox (if exists)
[[ -d "$HOME/Dropbox" ]] && hash -d dropbox="$HOME/Dropbox"

# -----------------------------------------------------------------------------
# Miscellaneous
# -----------------------------------------------------------------------------
alias path='echo $PATH | tr ":" "\n"'
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias week='date +%V'
alias myip='curl -s https://ipinfo.io/ip'

# Reload zsh configuration
alias reload='source ~/.zshrc'
