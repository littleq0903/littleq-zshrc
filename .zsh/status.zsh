# =============================================================================
# status.zsh - Status functions for prompt (git, node, claude.md, battery, etc.)
# =============================================================================

# -----------------------------------------------------------------------------
# Git Status
# -----------------------------------------------------------------------------
__git_info() {
    # Fast check if we're in a git repo
    local git_dir
    git_dir=$(git rev-parse --git-dir 2>/dev/null) || return

    # Get branch name (fast method)
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    [[ "$branch" == "HEAD" ]] && branch=$(git rev-parse --short HEAD 2>/dev/null)

    # Get status indicators
    local status_flags=""
    local git_status
    git_status=$(git status --porcelain 2>/dev/null | head -20)

    if [[ -n "$git_status" ]]; then
        # Modified files
        [[ "$git_status" == *" M"* || "$git_status" == *"M "* ]] && status_flags+="*"
        # Staged files
        [[ "$git_status" == *"A "* || "$git_status" == *"M "* || "$git_status" == *"D "* ]] && status_flags+="+"
        # Untracked files
        [[ "$git_status" == *"??"* ]] && status_flags+="?"
    fi

    echo "${branch}${status_flags}"
}

# Git root-relative path
__git_path() {
    local git_root
    git_root=$(git rev-parse --show-toplevel 2>/dev/null) || return 1

    local repo_name="${git_root:t}"
    local rel_path
    rel_path=$(git rev-parse --show-prefix 2>/dev/null)
    rel_path="${rel_path%/}"

    if [[ -n "$rel_path" ]]; then
        echo "⌥${repo_name}/${rel_path}"
    else
        echo "⌥${repo_name}"
    fi
}

# -----------------------------------------------------------------------------
# Claude.md Detection
# -----------------------------------------------------------------------------
__claude_status() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/CLAUDE.md" || -f "$dir/claude.md" ]]; then
            echo "claude:✓"
            return
        fi
        dir="${dir:h}"
    done
}

# -----------------------------------------------------------------------------
# Node.js Status
# -----------------------------------------------------------------------------
__node_status() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/package.json" ]]; then
            if (( $+commands[node] )); then
                local node_ver
                node_ver=$(node -v 2>/dev/null)
                node_ver="${node_ver#v}"
                echo "node:${node_ver}"
            fi
            return
        fi
        dir="${dir:h}"
    done
}

# -----------------------------------------------------------------------------
# Python Virtualenv Status
# -----------------------------------------------------------------------------
__venv_status() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "env:${VIRTUAL_ENV:t}"
    fi
}

# -----------------------------------------------------------------------------
# Background Jobs Status
# -----------------------------------------------------------------------------
__jobs_status() {
    local job_count="${(%):-%j}"
    if [[ "$job_count" -gt 0 ]]; then
        echo "jobs:${job_count}"
    fi
}

# -----------------------------------------------------------------------------
# Battery Status - these are now handled in prompt.zsh for proper integration
# with the original zsh prompt style (PR_BATTERY_INFO, PR_CHARGING_STATUS, etc.)
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Compact Path (with git-relative support)
# -----------------------------------------------------------------------------
__compact_path() {
    # Try git-relative path first
    local git_path
    git_path=$(__git_path)
    if [[ -n "$git_path" ]]; then
        echo "$git_path"
        return
    fi

    # Fallback to home-relative path
    local path="${PWD/#$HOME/~}"

    # Truncate if too long (>50 chars)
    if [[ ${#path} -gt 50 ]]; then
        local parts=("${(@s:/:)path}")
        local len=${#parts[@]}
        if [[ $len -gt 4 ]]; then
            path="${parts[1]}/.../${parts[-2]}/${parts[-1]}"
        fi
    fi

    echo "$path"
}

# -----------------------------------------------------------------------------
# Collect All Status Items
# -----------------------------------------------------------------------------
__collect_status() {
    local statuses=()

    local git_st=$(__git_info)
    local claude_st=$(__claude_status)
    local node_st=$(__node_status)
    local venv_st=$(__venv_status)
    local jobs_st=$(__jobs_status)

    [[ -n "$git_st" ]] && statuses+=("%F{green}git:${git_st}%f")
    [[ -n "$claude_st" ]] && statuses+=("%F{cyan}${claude_st}%f")
    [[ -n "$node_st" ]] && statuses+=("%F{yellow}${node_st}%f")
    [[ -n "$venv_st" ]] && statuses+=("%F{magenta}${venv_st}%f")
    [[ -n "$jobs_st" ]] && statuses+=("%F{blue}${jobs_st}%f")

    if [[ ${#statuses[@]} -gt 0 ]]; then
        echo "${(j:|:)statuses}"
    fi
}

# Plain status (no colors, for length calculation)
__collect_status_plain() {
    local statuses=()

    local git_st=$(__git_info)
    local claude_st=$(__claude_status)
    local node_st=$(__node_status)
    local venv_st=$(__venv_status)
    local jobs_st=$(__jobs_status)

    [[ -n "$git_st" ]] && statuses+=("git:$git_st")
    [[ -n "$claude_st" ]] && statuses+=("$claude_st")
    [[ -n "$node_st" ]] && statuses+=("$node_st")
    [[ -n "$venv_st" ]] && statuses+=("$venv_st")
    [[ -n "$jobs_st" ]] && statuses+=("$jobs_st")

    if [[ ${#statuses[@]} -gt 0 ]]; then
        echo "${(j:|:)statuses}"
    fi
}
