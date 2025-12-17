# =============================================================================
# .virtualenv.zsh - Python Virtual Environment Management
# =============================================================================
# Uses Python's built-in venv module (no external dependencies)
#
# Available commands:
#   actenv [name]     - Activate virtual environment (local ./venv or named)
#   deactenv          - Deactivate current virtual environment
#   lsenv             - List all named virtual environments
#   mkenv [name]      - Create virtual environment (local ./venv or named)
#   rmenv [name]      - Remove virtual environment (moves to trash)
#   restoreenv <name> - Restore previously removed environment
#   cdenv             - Change to virtual environment directory
# =============================================================================

# Default directories
VENV_HOME="${VENV_HOME:-$HOME/opt/venv}"
VENV_TRASH="${VENV_TRASH:-$HOME/.local/share/venv-trash}"

# Colors
__venv_green='\033[1;32m'
__venv_red='\033[1;31m'
__venv_yellow='\033[1;33m'
__venv_reset='\033[0m'

# -----------------------------------------------------------------------------
# Activate virtual environment
# -----------------------------------------------------------------------------
actenv() {
    local env_path env_name

    if [[ $# -eq 0 ]]; then
        # Local environment: try ./venv, ./.venv, or ./env
        for dir in venv .venv env; do
            if [[ -f "./${dir}/bin/activate" ]]; then
                env_path="./${dir}"
                env_name="local (${dir})"
                break
            fi
        done
        if [[ -z "$env_path" ]]; then
            echo -e "${__venv_red}No local virtual environment found.${__venv_reset}" >&2
            echo "Looked for: ./venv, ./.venv, ./env" >&2
            return 1
        fi
    elif [[ $# -eq 1 ]]; then
        # Named environment
        env_path="${VENV_HOME}/$1"
        env_name="$1"
        if [[ ! -f "${env_path}/bin/activate" ]]; then
            echo -e "${__venv_red}Virtual environment '$1' not found.${__venv_reset}" >&2
            echo "Available environments:" >&2
            lsenv
            return 1
        fi
    else
        echo "Usage: actenv [environment_name]" >&2
        return 1
    fi

    source "${env_path}/bin/activate"

    if [[ $? -eq 0 ]]; then
        echo -e "${__venv_green}Activated: ${env_name}${__venv_reset}"
        echo -e "${__venv_green}Python: $(python --version 2>&1)${__venv_reset}"
    fi
}

# -----------------------------------------------------------------------------
# Deactivate virtual environment
# -----------------------------------------------------------------------------
deactenv() {
    if [[ -z "$VIRTUAL_ENV" ]]; then
        echo -e "${__venv_yellow}No active virtual environment.${__venv_reset}"
        return 0
    fi

    local env_name="${VIRTUAL_ENV:t}"
    deactivate
    echo -e "${__venv_green}Deactivated: ${env_name}${__venv_reset}"
}

# -----------------------------------------------------------------------------
# List virtual environments
# -----------------------------------------------------------------------------
lsenv() {
    if [[ ! -d "$VENV_HOME" ]]; then
        echo "No environments found in ${VENV_HOME}"
        return 0
    fi

    echo "Virtual environments in ${VENV_HOME}:"
    local envs=("${VENV_HOME}"/*(N/))
    if [[ ${#envs[@]} -eq 0 ]]; then
        echo "  (none)"
    else
        for env in "${envs[@]}"; do
            local name="${env:t}"
            local python_ver=""
            if [[ -f "${env}/bin/python" ]]; then
                python_ver=$(${env}/bin/python --version 2>&1 | cut -d' ' -f2)
            fi
            if [[ "$VIRTUAL_ENV" == "$env" ]]; then
                echo -e "  ${__venv_green}* ${name}${__venv_reset} (Python ${python_ver}) [active]"
            else
                echo "  - ${name} (Python ${python_ver})"
            fi
        done
    fi
}

# -----------------------------------------------------------------------------
# Create virtual environment
# -----------------------------------------------------------------------------
mkenv() {
    local env_path env_name python_cmd

    # Determine Python command
    if (( $+commands[python3] )); then
        python_cmd="python3"
    elif (( $+commands[python] )); then
        python_cmd="python"
    else
        echo -e "${__venv_red}Error: Python not found${__venv_reset}" >&2
        return 1
    fi

    if [[ $# -eq 0 ]]; then
        # Create local environment
        env_path="./venv"
        env_name="local (venv)"

        if [[ -d "$env_path" ]]; then
            echo -e "${__venv_yellow}Local venv already exists. Remove first with: rmenv${__venv_reset}"
            return 1
        fi
    elif [[ $# -eq 1 ]]; then
        # Create named environment
        mkdir -p "$VENV_HOME"
        env_path="${VENV_HOME}/$1"
        env_name="$1"

        if [[ -d "$env_path" ]]; then
            echo -e "${__venv_yellow}Environment '$1' already exists.${__venv_reset}"
            return 1
        fi
    else
        echo "Usage: mkenv [environment_name]" >&2
        return 1
    fi

    echo "Creating virtual environment: ${env_name}..."
    $python_cmd -m venv "$env_path"

    if [[ $? -eq 0 ]]; then
        echo -e "${__venv_green}Created: ${env_name}${__venv_reset}"
        echo -e "${__venv_green}Activate with: actenv${1:+ $1}${__venv_reset}"

        # Optionally upgrade pip
        if [[ -f "${env_path}/bin/pip" ]]; then
            echo "Upgrading pip..."
            "${env_path}/bin/pip" install --upgrade pip -q
        fi
    else
        echo -e "${__venv_red}Failed to create virtual environment.${__venv_reset}" >&2
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Remove virtual environment (moves to trash)
# -----------------------------------------------------------------------------
rmenv() {
    local env_path env_name

    if [[ $# -eq 0 ]]; then
        # Remove local environment
        for dir in venv .venv env; do
            if [[ -d "./${dir}" ]]; then
                env_path="./${dir}"
                env_name="local (${dir})"
                break
            fi
        done
        if [[ -z "$env_path" ]]; then
            echo -e "${__venv_red}No local virtual environment found.${__venv_reset}" >&2
            return 1
        fi

        # Deactivate if this is the active environment
        if [[ "$VIRTUAL_ENV" == "$(cd "$env_path" && pwd)" ]]; then
            deactivate
        fi

        rm -rf "$env_path"
        echo -e "${__venv_green}Removed: ${env_name}${__venv_reset}"
    elif [[ $# -eq 1 ]]; then
        # Remove named environment (move to trash for recovery)
        env_path="${VENV_HOME}/$1"
        env_name="$1"

        if [[ ! -d "$env_path" ]]; then
            echo -e "${__venv_red}Environment '$1' not found.${__venv_reset}" >&2
            return 1
        fi

        # Deactivate if this is the active environment
        if [[ "$VIRTUAL_ENV" == "$env_path" ]]; then
            deactivate
        fi

        # Move to trash instead of deleting
        mkdir -p "$VENV_TRASH"
        local timestamp=$(date +%Y%m%d-%H%M%S)
        local trash_path="${VENV_TRASH}/${1}.${timestamp}"

        mv "$env_path" "$trash_path"

        if [[ $? -eq 0 ]]; then
            echo -e "${__venv_green}Removed: ${env_name}${__venv_reset}"
            echo "Can be restored with: restoreenv $1"
        else
            echo -e "${__venv_red}Failed to remove environment.${__venv_reset}" >&2
            return 1
        fi
    else
        echo "Usage: rmenv [environment_name]" >&2
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Restore removed environment
# -----------------------------------------------------------------------------
restoreenv() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: restoreenv <environment_name>" >&2
        echo "Available in trash:" >&2
        if [[ -d "$VENV_TRASH" ]]; then
            ls -1 "$VENV_TRASH" 2>/dev/null | sed 's/\.[0-9]\{8\}-[0-9]\{6\}$//' | sort -u | sed 's/^/  /'
        fi
        return 1
    fi

    local name="$1"

    # Find the most recent backup
    local latest
    latest=$(ls -1t "${VENV_TRASH}/${name}."* 2>/dev/null | head -1)

    if [[ -z "$latest" ]]; then
        echo -e "${__venv_red}No backup found for '$name'${__venv_reset}" >&2
        return 1
    fi

    local dest="${VENV_HOME}/${name}"
    if [[ -d "$dest" ]]; then
        echo -e "${__venv_yellow}Environment '$name' already exists. Remove it first.${__venv_reset}"
        return 1
    fi

    mkdir -p "$VENV_HOME"
    mv "$latest" "$dest"

    if [[ $? -eq 0 ]]; then
        echo -e "${__venv_green}Restored: ${name}${__venv_reset}"
    else
        echo -e "${__venv_red}Failed to restore environment.${__venv_reset}" >&2
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Change to virtual environment directory
# -----------------------------------------------------------------------------
cdenv() {
    if [[ -z "$VIRTUAL_ENV" ]]; then
        echo -e "${__venv_red}Not in a virtual environment.${__venv_reset}" >&2
        return 1
    fi

    cd "$VIRTUAL_ENV"
    echo "Changed to: $VIRTUAL_ENV"
}

# -----------------------------------------------------------------------------
# Clean up old trash (older than 30 days)
# -----------------------------------------------------------------------------
cleanenv() {
    if [[ ! -d "$VENV_TRASH" ]]; then
        echo "Trash is empty."
        return 0
    fi

    echo "Cleaning environments older than 30 days..."
    find "$VENV_TRASH" -maxdepth 1 -type d -mtime +30 -exec rm -rf {} \; 2>/dev/null
    echo -e "${__venv_green}Done.${__venv_reset}"
}
