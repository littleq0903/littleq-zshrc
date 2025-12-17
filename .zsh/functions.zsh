# =============================================================================
# functions.zsh - Utility functions
# =============================================================================

# -----------------------------------------------------------------------------
# HTTP Server
# -----------------------------------------------------------------------------
httpserver() {
    local port="${1:-8000}"

    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        echo "Usage: httpserver [port]" >&2
        echo "  port: Port number (default: 8000)" >&2
        return 1
    fi

    echo "Starting HTTP server on http://localhost:${port}/"

    # Open browser after delay (macOS)
    if [[ "$MACHINE_OS" == "macosx" ]]; then
        (sleep 1 && open "http://localhost:${port}/") &
    fi

    # Use Python 3's http.server module
    python3 -m http.server "$port" "${@:2}"
}

# -----------------------------------------------------------------------------
# Man Page with Syntax Highlighting
# -----------------------------------------------------------------------------
man() {
    if ! (( $+commands[vim] )); then
        command man "$@"
        return
    fi
    command man "$@" | col -b | vim -R -c 'set ft=man nomod nolist' -
}

# -----------------------------------------------------------------------------
# Git Utilities
# -----------------------------------------------------------------------------
# Open files with git conflicts in vim tabs
git-conflict() {
    local files
    files=$(git diff --name-only --diff-filter=U 2>/dev/null)

    if [[ -z "$files" ]]; then
        echo "No merge conflicts found" >&2
        return 1
    fi

    vim -p ${(f)files}
}

# Get current git branch name
git_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Generate .gitignore from gitignore.io
gen_gitignore() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: gen_gitignore <type1> [type2] [type3] ..." >&2
        echo "Example: gen_gitignore python macos vscode" >&2
        echo "See https://www.toptal.com/developers/gitignore for available types" >&2
        return 1
    fi

    local types="${(j:,:)@}"
    curl -sL "https://www.toptal.com/developers/gitignore/api/${types}"
}

# -----------------------------------------------------------------------------
# File Utilities
# -----------------------------------------------------------------------------
# Swap names of two files
swap_name() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: swap_name file1 file2" >&2
        return 1
    fi

    local file1="$1"
    local file2="$2"

    if [[ ! -e "$file1" ]]; then
        echo "Error: '$file1' does not exist" >&2
        return 1
    fi

    if [[ ! -e "$file2" ]]; then
        echo "Error: '$file2' does not exist" >&2
        return 1
    fi

    local temp
    temp=$(mktemp -u "${file1}.XXXXXX") || return 1

    mv "$file1" "$temp" && \
    mv "$file2" "$file1" && \
    mv "$temp" "$file2" && \
    echo "Swapped: $file1 <-> $file2"
}

# -----------------------------------------------------------------------------
# Encoding Conversion
# -----------------------------------------------------------------------------
# Convert file encoding to UTF-8
to_utf8() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: to_utf8 <file>" >&2
        return 1
    fi

    if ! (( $+commands[enca] )); then
        echo "Error: 'enca' is not installed" >&2
        return 1
    fi

    enca -L zh_TW -x UTF-8 "$1"
}

# Simplified Chinese to Traditional Chinese
sc2tc() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: sc2tc <input_file> <output_file>" >&2
        return 1
    fi

    if [[ ! -f "$1" ]]; then
        echo "Error: Input file '$1' not found" >&2
        return 1
    fi

    iconv -f UTF-8 -t GB2312 "$1" | \
    iconv -f GB2312 -t BIG-5 | \
    iconv -f BIG-5 -t UTF-8 > "$2"

    echo "Converted: $1 -> $2"
}

# Traditional Chinese to Simplified Chinese
tc2sc() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: tc2sc <input_file> <output_file>" >&2
        return 1
    fi

    if [[ ! -f "$1" ]]; then
        echo "Error: Input file '$1' not found" >&2
        return 1
    fi

    iconv -f UTF-8 -t BIG-5 "$1" | \
    iconv -f BIG-5 -t GB2312 | \
    iconv -f GB2312 -t UTF-8 > "$2"

    echo "Converted: $1 -> $2"
}

# -----------------------------------------------------------------------------
# Clipboard Utilities (macOS)
# -----------------------------------------------------------------------------
if [[ "$MACHINE_OS" == "macosx" ]]; then
    # Strip formatting from clipboard
    plaintext() {
        pbpaste -Prefer txt | pbcopy
        echo "Clipboard converted to plain text"
    }

    # Syntax highlight code in clipboard
    clip_code() {
        if ! (( $+commands[highlight] )); then
            echo "Error: 'highlight' is not installed" >&2
            echo "Install with: brew install highlight" >&2
            return 1
        fi

        local syntax="$1"
        local theme_type="${2:-dark}"
        local theme

        if [[ -z "$syntax" ]]; then
            echo "Usage: clip_code <syntax> [dark|light|theme_name]" >&2
            echo "Example: clip_code python dark" >&2
            return 1
        fi

        case "$theme_type" in
            light) theme="fine_blue" ;;
            dark)  theme="zenburn" ;;
            *)     theme="$theme_type" ;;
        esac

        plaintext
        pbpaste | highlight --syntax="$syntax" -O rtf \
            --font-size 36 --font "Droid Sans Mono" --style "$theme" | pbcopy

        echo "Clipboard code highlighted with syntax: $syntax, theme: $theme"
    }
fi

# -----------------------------------------------------------------------------
# Network Utilities
# -----------------------------------------------------------------------------
# Show listening ports
openports() {
    if [[ "$MACHINE_OS" == "macosx" ]]; then
        sudo lsof -iTCP -sTCP:LISTEN -P -n
    else
        sudo lsof -i -P | grep -i "listen"
    fi
}

# -----------------------------------------------------------------------------
# SSH Utilities
# -----------------------------------------------------------------------------
# Connect to PLSM cloud instance via jump host
connect_plsm_instance() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: connect_plsm_instance <private_ip>" >&2
        echo "  private_ip: The private IP of the instance in the PLSM private cloud" >&2
        return 1
    fi

    local private_ip="$1"
    local jump_host="littleq@140.119.164.155"
    local ssh_key="~/.ssh/id_littleq-plsm"

    ssh -t "$jump_host" "ssh -i $ssh_key ubuntu@$private_ip"
}

# -----------------------------------------------------------------------------
# Syntax Highlighting with Pygments
# -----------------------------------------------------------------------------
if (( $+commands[pygmentize] )); then
    pless() {
        if [[ ! -f "$1" ]]; then
            echo "Usage: pless <file>" >&2
            return 1
        fi
        pygmentize -g "$1" | less -R
    }
fi

# -----------------------------------------------------------------------------
# Quick Directory Navigation
# -----------------------------------------------------------------------------
# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Find and cd to directory
fcd() {
    local dir
    dir=$(find "${1:-.}" -type d 2>/dev/null | fzf +m) && cd "$dir"
}

# -----------------------------------------------------------------------------
# Archive Utilities
# -----------------------------------------------------------------------------
# Extract various archive formats
extract() {
    if [[ ! -f "$1" ]]; then
        echo "Error: '$1' is not a valid file" >&2
        return 1
    fi

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
        *)           echo "Cannot extract '$1': unknown format" >&2; return 1 ;;
    esac
}
