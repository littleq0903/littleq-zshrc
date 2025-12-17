# =============================================================================
# init.zsh - Environment setup and basic configuration
# =============================================================================

# Source profile if exists
[[ -f "$HOME/.profile" ]] && source "$HOME/.profile"

# -----------------------------------------------------------------------------
# OS Detection
# -----------------------------------------------------------------------------
case "$(uname -s)" in
    Darwin*)  export MACHINE_OS="macosx" ;;
    Linux*)   export MACHINE_OS="ubuntu" ;;
    CYGWIN*)  export MACHINE_OS="cygwin" ;;
    MINGW*)   export MACHINE_OS="mingw" ;;
    *)        export MACHINE_OS="unknown" ;;
esac

# -----------------------------------------------------------------------------
# Locale
# -----------------------------------------------------------------------------
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# -----------------------------------------------------------------------------
# Editor
# -----------------------------------------------------------------------------
export EDITOR=vim
export VISUAL=vim

# -----------------------------------------------------------------------------
# History Configuration
# -----------------------------------------------------------------------------
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE=~/.zhistory

# Append command to history file once executed
setopt INC_APPEND_HISTORY
# Share history between sessions
setopt SHARE_HISTORY
# Remove duplicates first when trimming history
setopt HIST_EXPIRE_DUPS_FIRST
# Don't record duplicates
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
# Don't record commands starting with space
setopt HIST_IGNORE_SPACE
# Remove superfluous blanks
setopt HIST_REDUCE_BLANKS
# Don't execute immediately upon history expansion
setopt HIST_VERIFY

# -----------------------------------------------------------------------------
# Directory Navigation
# -----------------------------------------------------------------------------
# Auto cd when typing directory name
setopt AUTO_CD
# Push directory to stack on cd
setopt AUTO_PUSHD
# Don't push duplicates
setopt PUSHD_IGNORE_DUPS
# Be quiet about pushd
setopt PUSHD_SILENT

# -----------------------------------------------------------------------------
# Globbing and Expansion
# -----------------------------------------------------------------------------
setopt EXTENDED_GLOB
setopt NO_CASE_GLOB

# -----------------------------------------------------------------------------
# Miscellaneous
# -----------------------------------------------------------------------------
# Disable core dumps
limit coredumpsize 0

# Allow comments in interactive shell
setopt INTERACTIVE_COMMENTS

# Don't beep
setopt NO_BEEP

# Report background job status immediately
setopt NOTIFY

# -----------------------------------------------------------------------------
# Key Bindings
# -----------------------------------------------------------------------------
# Use emacs key bindings (default)
bindkey -e

# DEL key for forward delete
bindkey "\e[3~" delete-char

# Word navigation with Ctrl+Arrow
bindkey ';5D' backward-word
bindkey ';5C' forward-word

# Word characters (for word navigation)
WORDCHARS=';*?_-[]~=&!#$%^(){}<>'
