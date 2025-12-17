#!/bin/bash
# =============================================================================
# .bashrc - littleq's Bash Configuration
# =============================================================================
# Two-line prompt matching zshrc style
# =============================================================================

# Source profile if exists
[[ -f "$HOME/.profile" ]] && source "$HOME/.profile"

# -----------------------------------------------------------------------------
# OS Detection
# -----------------------------------------------------------------------------
case "$(uname -s)" in
    Darwin*)  MACHINE_OS="macosx" ;;
    Linux*)   MACHINE_OS="ubuntu" ;;
    CYGWIN*)  MACHINE_OS="cygwin" ;;
    MINGW*)   MACHINE_OS="mingw" ;;
    *)        MACHINE_OS="unknown" ;;
esac
export MACHINE_OS

# -----------------------------------------------------------------------------
# Colors (matching zsh PR_* style)
# -----------------------------------------------------------------------------
# For prompt (with \[ \] escapes)
PR_RED='\[\033[1;31m\]'
PR_GREEN='\[\033[1;32m\]'
PR_YELLOW='\[\033[1;33m\]'
PR_BLUE='\[\033[1;34m\]'
PR_MAGENTA='\[\033[1;35m\]'
PR_CYAN='\[\033[1;36m\]'
PR_WHITE='\[\033[1;37m\]'
PR_LIGHT_RED='\[\033[0;31m\]'
PR_LIGHT_GREEN='\[\033[0;32m\]'
PR_LIGHT_YELLOW='\[\033[0;33m\]'
PR_LIGHT_BLUE='\[\033[0;34m\]'
PR_LIGHT_CYAN='\[\033[0;36m\]'
PR_NO_COLOUR='\[\033[0m\]'

# For echo (without escapes)
EC_RED='\033[1;31m'
EC_GREEN='\033[1;32m'
EC_YELLOW='\033[1;33m'
EC_BLUE='\033[1;34m'
EC_CYAN='\033[1;36m'
EC_LIGHT_GREEN='\033[0;32m'
EC_RESET='\033[0m'

# Line drawing characters using terminfo ACS (same as zshrc)
# These are the actual characters to draw, wrapped in shift-in/shift-out
PR_ENACS="$(tput enacs 2>/dev/null)"  # Enable alternate charset
PR_SMACS="$(tput smacs 2>/dev/null)"  # Shift in (start alternate charset)
PR_RMACS="$(tput rmacs 2>/dev/null)"  # Shift out (end alternate charset)
# ACS characters: q=hline, l=ulcorner, m=llcorner, j=lrcorner, k=urcorner
PR_HBAR='q'
PR_ULCORNER='l'
PR_LLCORNER='m'
PR_URCORNER='k'
PR_LRCORNER='j'

# Color scheme
PR_PARENTHESE_COLOR="$PR_NO_COLOUR"
PR_CORNER_COLOR="$PR_GREEN"
PR_LINE_COLOR="$PR_LIGHT_GREEN"
PR_CWD_COLOR="$PR_BLUE"
PR_SEPERATOR="${PR_NO_COLOUR}|"

# -----------------------------------------------------------------------------
# History
# -----------------------------------------------------------------------------
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTFILE=~/.bash_history
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend
shopt -s checkwinsize  # Update COLUMNS and LINES after each command

# -----------------------------------------------------------------------------
# Locale
# -----------------------------------------------------------------------------
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export EDITOR=vim

# -----------------------------------------------------------------------------
# Command Timer
# -----------------------------------------------------------------------------
__cmd_start_time=0

__timer_start() {
    __cmd_start_time="${__cmd_start_time:-$SECONDS}"
}

__timer_stop() {
    local elapsed=$((SECONDS - __cmd_start_time))
    __cmd_start_time=$SECONDS

    if [[ $elapsed -eq 0 ]]; then
        __last_cmd_time=""
    elif [[ $elapsed -lt 60 ]]; then
        __last_cmd_time="${elapsed}s"
    elif [[ $elapsed -lt 3600 ]]; then
        __last_cmd_time="$((elapsed / 60))m$((elapsed % 60))s"
    else
        __last_cmd_time="$((elapsed / 3600))h$((elapsed % 3600 / 60))m"
    fi
}

trap '__timer_start' DEBUG

# -----------------------------------------------------------------------------
# Status Functions
# -----------------------------------------------------------------------------

# Git status
__git_info() {
    local git_dir
    git_dir=$(git rev-parse --git-dir 2>/dev/null) || return

    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    [[ "$branch" == "HEAD" ]] && branch=$(git rev-parse --short HEAD 2>/dev/null)

    local flags=""
    local git_status
    git_status=$(git status --porcelain 2>/dev/null | head -20)

    if [[ -n "$git_status" ]]; then
        [[ "$git_status" == *" M"* || "$git_status" == *"M "* ]] && flags+="*"
        [[ "$git_status" == *"A "* || "$git_status" == *"D "* ]] && flags+="+"
        [[ "$git_status" == *"??"* ]] && flags+="?"
    fi

    echo "git:${branch}${flags}"
}

# Claude.md detection
__claude_status() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/CLAUDE.md" || -f "$dir/claude.md" ]]; then
            echo "claude:✓"
            return
        fi
        dir=$(dirname "$dir")
    done
}

# Node version
__node_status() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/package.json" ]]; then
            if command -v node &>/dev/null; then
                local ver
                ver=$(node -v 2>/dev/null)
                echo "node:${ver#v}"
            fi
            return
        fi
        dir=$(dirname "$dir")
    done
}

# Python virtualenv
__venv_status() {
    [[ -n "$VIRTUAL_ENV" ]] && echo "env:$(basename "$VIRTUAL_ENV")"
}

# Background jobs
__jobs_status() {
    local count
    count=$(jobs -p 2>/dev/null | wc -l | tr -d ' ')
    [[ "$count" -gt 0 ]] && echo "jobs:${count}"
}

# Battery info
__battery_info() {
    local pct="" status="" color=""

    if [[ "$MACHINE_OS" == "macosx" ]]; then
        local batt
        batt=$(pmset -g batt 2>/dev/null)
        if [[ -n "$batt" ]]; then
            if [[ "$batt" =~ ([0-9]+)% ]]; then
                pct="${BASH_REMATCH[1]}"
            fi
            if [[ "$batt" == *"charged"* ]]; then
                status="charged"
            elif [[ "$batt" == *"charging"* || "$batt" == *"finishing charge"* ]]; then
                status="charging"
            elif [[ "$batt" == *"discharging"* ]]; then
                status="discharging"
            fi
        fi
    elif [[ "$MACHINE_OS" == "ubuntu" ]]; then
        local bat_paths=("/sys/class/power_supply/BAT0" "/sys/class/power_supply/BAT1")
        for bat_path in "${bat_paths[@]}"; do
            if [[ -f "$bat_path/capacity" ]]; then
                pct=$(< "$bat_path/capacity")
                if [[ -f "$bat_path/status" ]]; then
                    local st
                    st=$(< "$bat_path/status")
                    case "$st" in
                        Full|Charged)    status="charged" ;;
                        Charging)        status="charging" ;;
                        Discharging)     status="discharging" ;;
                    esac
                fi
                break
            fi
        done

        # WSL support
        if [[ -n "$WSL_DISTRO_NAME" ]] && command -v powershell.exe &>/dev/null; then
            pct=$(powershell.exe -Command "(Get-WmiObject Win32_Battery).EstimatedChargeRemaining" 2>/dev/null | tr -d '\r\n')
            status="battery"
        fi
    fi

    if [[ -n "$pct" ]]; then
        # Color based on level
        if [[ "$pct" -le 20 ]]; then
            color="$EC_RED"
        elif [[ "$pct" -le 40 ]]; then
            color="$EC_YELLOW"
        elif [[ "$pct" -le 70 ]]; then
            color="$EC_BLUE"
        else
            color="$EC_GREEN"
        fi

        __battery_pct="$pct"
        __battery_status="$status"
        __battery_color="$color"
    else
        __battery_pct=""
        __battery_status=""
        __battery_color=""
    fi
}

# Compact path (git-relative if in repo)
__compact_path() {
    local git_root
    git_root=$(git rev-parse --show-toplevel 2>/dev/null)

    if [[ -n "$git_root" ]]; then
        local repo_name
        repo_name=$(basename "$git_root")
        local rel_path
        rel_path=$(git rev-parse --show-prefix 2>/dev/null)
        rel_path="${rel_path%/}"

        if [[ -n "$rel_path" ]]; then
            echo "~${repo_name}/${rel_path}"
        else
            echo "~${repo_name}"
        fi
    else
        local path="${PWD/#$HOME/~}"
        # Truncate if too long
        if [[ ${#path} -gt 50 ]]; then
            local IFS='/'
            read -ra parts <<< "$path"
            local len=${#parts[@]}
            if [[ $len -gt 4 ]]; then
                path="${parts[0]}/.../${parts[$((len-2))]}/${parts[$((len-1))]}"
            fi
        fi
        echo "$path"
    fi
}

# -----------------------------------------------------------------------------
# Build Prompt
# -----------------------------------------------------------------------------
__build_prompt() {
    local exit_code=$?
    __timer_stop
    __battery_info

    # Collect status items
    local status_line=""
    local git_st=$(__git_info)
    local claude_st=$(__claude_status)
    local node_st=$(__node_status)
    local venv_st=$(__venv_status)
    local jobs_st=$(__jobs_status)

    [[ -n "$git_st" ]] && status_line+="|$git_st"
    [[ -n "$claude_st" ]] && status_line+="|$claude_st"
    [[ -n "$node_st" ]] && status_line+="|$node_st"
    [[ -n "$venv_st" ]] && status_line+="|$venv_st"
    [[ -n "$jobs_st" ]] && status_line+="|$jobs_st"
    [[ -n "$__last_cmd_time" ]] && status_line+="|t:${__last_cmd_time}"

    # Get path and tty
    local cpath
    cpath=$(__compact_path)
    local tty_name
    tty_name=$(tty 2>/dev/null | sed 's|/dev/||')
    [[ -z "$tty_name" ]] && tty_name="pts"
    local short_host="${HOSTNAME%%.*}"

    # Terminal width - use COLUMNS which bash updates automatically
    local term_width="${COLUMNS:-$(tput cols 2>/dev/null)}"
    [[ -z "$term_width" ]] && term_width=80

    # Calculate sizes for fill bar
    # Format: ┌─(user@host>tty|status)─────────────(path)─┐
    # Left side: "┌─" + "(" + user + "@" + host + ">" + tty + status + ")"
    #          = 2 + 1 + user + 1 + host + 1 + tty + status + 1 = 6 + user + host + tty + status
    local left_size=$((6 + ${#USER} + ${#short_host} + ${#tty_name} + ${#status_line}))
    # Right side: "(" + path + ")" + "─┐"
    #           = 1 + path + 1 + 2 = 4 + path
    local right_size=$((4 + ${#cpath}))

    local total_occupied=$((left_size + right_size))
    local fill_size=$((term_width - total_occupied))
    [[ $fill_size -lt 0 ]] && fill_size=0

    # Debug: uncomment to see values
    echo "DEBUG: term=$term_width left=$left_size right=$right_size total=$total_occupied fill=$fill_size" >&2
    echo "DEBUG: user=${#USER}($USER) host=${#short_host}($short_host) tty=${#tty_name}($tty_name) status=${#status_line} path=${#cpath}($cpath)" >&2

    # Build fill bar with ─ characters
    local fill=""
    for ((i=0; i<fill_size; i++)); do fill+="${PR_HBAR}"; done

    # Exit code indicator
    local exit_part
    if [[ $exit_code -eq 0 ]]; then
        exit_part="${PR_LIGHT_GREEN}"
    else
        exit_part="${PR_RED}${exit_code}${PR_NO_COLOUR}|"
    fi

    # Prompt character
    local prompt_char="\$"
    [[ $EUID -eq 0 ]] && prompt_char="#"

    # =========================================================================
    # Build PS1 matching zsh style:
    # Line 1: ┌─(user@host>tty|status)─────────────────(path)─┐
    # Line 2: └─(exitcode|$$|$)─>
    # =========================================================================

    # Wrap ACS characters for prompt (with \[ \] for non-printing)
    local acs_on="\[${PR_SMACS}\]"
    local acs_off="\[${PR_RMACS}\]"

    PS1="\[${PR_ENACS}\]"
    # Line 1 start
    PS1+="${PR_LINE_COLOR}${acs_on}${PR_CORNER_COLOR}${PR_ULCORNER}${PR_LINE_COLOR}${PR_HBAR}${acs_off}${PR_NO_COLOUR}"
    PS1+="${PR_PARENTHESE_COLOR}("
    PS1+="${PR_BLUE}${USER}${PR_RED}@${short_host}>${PR_YELLOW}${tty_name}"

    # Add status items with colors
    [[ -n "$git_st" ]] && PS1+="${PR_NO_COLOUR}|${PR_LIGHT_GREEN}${git_st}"
    [[ -n "$claude_st" ]] && PS1+="${PR_NO_COLOUR}|${PR_CYAN}${claude_st}"
    [[ -n "$node_st" ]] && PS1+="${PR_NO_COLOUR}|${PR_YELLOW}${node_st}"
    [[ -n "$venv_st" ]] && PS1+="${PR_NO_COLOUR}|${PR_RED}${venv_st}"
    [[ -n "$jobs_st" ]] && PS1+="${PR_NO_COLOUR}|${PR_BLUE}${jobs_st}"
    [[ -n "$__last_cmd_time" ]] && PS1+="${PR_NO_COLOUR}|${PR_CYAN}t:${__last_cmd_time}"

    PS1+="${PR_PARENTHESE_COLOR})${PR_NO_COLOUR}"
    # Fill bar
    PS1+="${PR_LINE_COLOR}${acs_on}${fill}${acs_off}${PR_NO_COLOUR}"
    # Path section
    PS1+="${PR_PARENTHESE_COLOR}("
    PS1+="${PR_BLUE}${cpath}"
    PS1+="${PR_PARENTHESE_COLOR})"
    PS1+="${PR_LINE_COLOR}${acs_on}${PR_HBAR}${PR_CORNER_COLOR}${PR_URCORNER}${acs_off}${PR_NO_COLOUR}"

    # Line 2
    PS1+="\n"
    PS1+="${PR_LINE_COLOR}${acs_on}${PR_CORNER_COLOR}${PR_LLCORNER}${PR_LINE_COLOR}${PR_HBAR}${acs_off}${PR_NO_COLOUR}"
    PS1+="${PR_PARENTHESE_COLOR}("
    PS1+="${exit_part}${PR_YELLOW}\$\$"
    PS1+="${PR_GREEN}|${PR_NO_COLOUR}${prompt_char}"
    PS1+="${PR_PARENTHESE_COLOR})"
    PS1+="${PR_LINE_COLOR}${acs_on}${PR_HBAR}${acs_off}${PR_NO_COLOUR}> "

    # Set terminal title
    case "$TERM" in
        xterm*|rxvt*|screen*)
            echo -ne "\033]0;${USER}@${short_host}:${PWD/#$HOME/\~}\007"
            ;;
    esac
}

PROMPT_COMMAND='__build_prompt'

# Secondary prompt
PS2="\[${PR_SMACS}\]${PR_LINE_COLOR}${PR_HBAR}${PR_HBAR}\[${PR_RMACS}\]${PR_NO_COLOUR}(${PR_YELLOW}>\[${PR_RMACS}\]${PR_NO_COLOUR})\[${PR_SMACS}\]${PR_LINE_COLOR}${PR_HBAR}${PR_HBAR}\[${PR_RMACS}\]${PR_NO_COLOUR}> "

# -----------------------------------------------------------------------------
# Aliases
# -----------------------------------------------------------------------------
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias ll='ls -lh'
alias la='ls -A'
alias lla='ls -lAh'
alias l='ls -CF'
alias sl='ls'
alias grep='grep --color=auto'
alias q='exit'
alias back='tmux -2 attach'

# OS-specific
if [[ "$MACHINE_OS" == "macosx" ]]; then
    if command -v gls &>/dev/null; then
        alias ls='gls --color=auto'
    else
        alias ls='ls -G'
    fi
    command -v gdircolors &>/dev/null && alias dircolors='gdircolors'
else
    alias ls='ls --color=auto'
fi

# Vim aliases
alias vi='vim'
alias vimsplit='vim -o'
alias vimvsplit='vim -O'
alias vimtab='vim -p'

# Git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'

# Clipboard (Linux)
if [[ "$MACHINE_OS" == "ubuntu" ]]; then
    command -v xclip &>/dev/null && {
        alias pbcopy='xclip -selection clipboard -i'
        alias pbpaste='xclip -selection clipboard -o'
    }
fi

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------
# HTTP server
httpserver() {
    local port="${1:-8000}"
    echo "Starting HTTP server on http://localhost:${port}/"
    [[ "$MACHINE_OS" == "macosx" ]] && (sleep 1 && open "http://localhost:${port}/") &
    python3 -m http.server "$port" "${@:2}"
}

# Swap file names
swap_name() {
    [[ $# -ne 2 ]] && { echo "Usage: swap_name file1 file2" >&2; return 1; }
    [[ ! -e "$1" ]] && { echo "Error: '$1' not found" >&2; return 1; }
    [[ ! -e "$2" ]] && { echo "Error: '$2' not found" >&2; return 1; }
    local temp
    temp=$(mktemp -u "${1}.XXXXXX")
    mv "$1" "$temp" && mv "$2" "$1" && mv "$temp" "$2"
    echo "Swapped: $1 <-> $2"
}

# Show listening ports
openports() {
    if [[ "$MACHINE_OS" == "macosx" ]]; then
        sudo lsof -iTCP -sTCP:LISTEN -P -n
    else
        sudo lsof -i -P | grep -i "listen"
    fi
}

# Git conflict opener
git-conflict() {
    local files
    files=$(git diff --name-only --diff-filter=U 2>/dev/null)
    [[ -z "$files" ]] && { echo "No conflicts found" >&2; return 1; }
    vim -p $files
}

# Generate gitignore
gen_gitignore() {
    [[ $# -eq 0 ]] && { echo "Usage: gen_gitignore type1 [type2...]" >&2; return 1; }
    local types
    types=$(IFS=,; echo "$*")
    curl -sL "https://www.toptal.com/developers/gitignore/api/${types}"
}

# Create dir and cd
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract archives
extract() {
    [[ ! -f "$1" ]] && { echo "Error: '$1' not found" >&2; return 1; }
    case "$1" in
        *.tar.bz2)   tar xjf "$1"     ;;
        *.tar.gz)    tar xzf "$1"     ;;
        *.tar.xz)    tar xJf "$1"     ;;
        *.bz2)       bunzip2 "$1"     ;;
        *.rar)       unrar x "$1"     ;;
        *.gz)        gunzip "$1"      ;;
        *.tar)       tar xf "$1"      ;;
        *.tbz2)      tar xjf "$1"     ;;
        *.tgz)       tar xzf "$1"     ;;
        *.zip)       unzip "$1"       ;;
        *.Z)         uncompress "$1"  ;;
        *.7z)        7z x "$1"        ;;
        *)           echo "Unknown format: $1" >&2; return 1 ;;
    esac
}

# cd and ls
cd() {
    builtin cd "$@" && ls
}

# -----------------------------------------------------------------------------
# PATH
# -----------------------------------------------------------------------------
[[ -d "/opt/homebrew/bin" ]] && export PATH="/opt/homebrew/bin:$PATH"
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && \. "$NVM_DIR/bash_completion"

# rbenv
command -v rbenv &>/dev/null && eval "$(rbenv init - bash)"

# -----------------------------------------------------------------------------
# Disable core dumps
# -----------------------------------------------------------------------------
ulimit -c 0

# -----------------------------------------------------------------------------
# Bash completion
# -----------------------------------------------------------------------------
if [[ -f /etc/bash_completion ]]; then
    . /etc/bash_completion
elif [[ -f /usr/share/bash-completion/bash_completion ]]; then
    . /usr/share/bash-completion/bash_completion
elif [[ -f /opt/homebrew/etc/profile.d/bash_completion.sh ]]; then
    . /opt/homebrew/etc/profile.d/bash_completion.sh
fi

# -----------------------------------------------------------------------------
# Local overrides
# -----------------------------------------------------------------------------
[[ -f "$HOME/.bashrc.local" ]] && source "$HOME/.bashrc.local"
