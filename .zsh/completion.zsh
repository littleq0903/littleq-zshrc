# =============================================================================
# completion.zsh - Zsh completion configuration
# =============================================================================

# -----------------------------------------------------------------------------
# Completion Paths (fpath)
# -----------------------------------------------------------------------------
# Add custom completion directories if they exist
local completion_dirs=(
    "$HOME/github/zsh-completions/src"
    "$HOME/github/gcloud-zsh-completion/src"
    "$HOME/github/maven-zsh-completion"
    "$HOME/Dropbox/portableLibraries/zsh/completion"
)

for dir in "${completion_dirs[@]}"; do
    [[ -d "$dir" ]] && fpath=("$dir" $fpath)
done

# -----------------------------------------------------------------------------
# Initialize Completion System
# -----------------------------------------------------------------------------
autoload -Uz compinit

# Only regenerate .zcompdump once a day for faster startup
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# Load bashcompinit for bash completion compatibility
autoload -Uz bashcompinit && bashcompinit

# -----------------------------------------------------------------------------
# Completion Behavior
# -----------------------------------------------------------------------------
setopt AUTO_LIST           # List choices on ambiguous completion
setopt AUTO_MENU           # Use menu completion after second tab
setopt COMPLETE_IN_WORD    # Complete from both ends of a word
setopt ALWAYS_TO_END       # Move cursor to end after completion
setopt NO_LIST_BEEP        # Don't beep on ambiguous completion

# -----------------------------------------------------------------------------
# Completion Caching
# -----------------------------------------------------------------------------
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# -----------------------------------------------------------------------------
# Matching and Sorting
# -----------------------------------------------------------------------------
# Case-insensitive, partial-word, and substring completion
zstyle ':completion:*' matcher-list \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' \
    'r:|[._-]=* r:|=*' \
    'l:|=* r:|=*'

# Sort files by modification time
zstyle ':completion:*' file-sort modification

# Complete . and .. special directories
zstyle ':completion:*' special-dirs true

# Don't complete parent directory when in current
zstyle ':completion:*:cd:*' ignore-parents parent pwd

# -----------------------------------------------------------------------------
# Completion Styling
# -----------------------------------------------------------------------------
# Use menu selection
zstyle ':completion:*:*:*:*:*' menu select

# Group matches and describe
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'

# Formatting messages
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:messages'     format '%F{purple}-- %d --%f'
zstyle ':completion:*:warnings'     format '%F{red}-- No matches found --%f'
zstyle ':completion:*:corrections'  format '%F{green}-- %d (errors: %e) --%f'

# Separate different types of matches
zstyle ':completion:*' group-name ''

# -----------------------------------------------------------------------------
# Directory Colors
# -----------------------------------------------------------------------------
if [[ "$MACHINE_OS" == "macosx" ]]; then
    if (( $+commands[gdircolors] )); then
        eval "$(gdircolors -b)"
    fi
elif [[ -f /etc/DIR_COLORS ]]; then
    eval "$(dircolors -b /etc/DIR_COLORS)"
elif (( $+commands[dircolors] )); then
    eval "$(dircolors -b)"
fi

# Apply LS_COLORS to completion
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# -----------------------------------------------------------------------------
# Process Completion
# -----------------------------------------------------------------------------
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always
zstyle ':completion:*:processes' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# -----------------------------------------------------------------------------
# SSH/SCP/Rsync Completion
# -----------------------------------------------------------------------------
zstyle ':completion:*:(ssh|scp|rsync):*' hosts \
    ${(f)"$(cat ~/.ssh/known_hosts 2>/dev/null | cut -d ' ' -f 1 | cut -d ',' -f 1 | sort -u)"}
zstyle ':completion:*:(ssh|scp|rsync):*' users $USER root

# -----------------------------------------------------------------------------
# Man Page Completion
# -----------------------------------------------------------------------------
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

# -----------------------------------------------------------------------------
# Command Aliases for Completion
# -----------------------------------------------------------------------------
compdef pkill=kill
compdef pkill=killall
(( $+commands[hub] )) && compdef hub=git
