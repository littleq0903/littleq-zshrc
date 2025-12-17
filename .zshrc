# =============================================================================
# .zshrc - littleq's Zsh Configuration
# =============================================================================
# Modular configuration loaded from .zsh/ directory
# Repository: https://github.com/littleq0903/littleq-zshrc
# =============================================================================

# Get the directory where zshrc is located (handles symlinks)
ZSHRC_DIR="${${(%):-%x}:A:h}"

# -----------------------------------------------------------------------------
# Load Configuration Modules
# -----------------------------------------------------------------------------
# Order matters: init -> completion -> aliases -> functions -> integrations -> status -> prompt

local _zsh_modules=(
    init         # Environment, history, basic settings
    completion   # Completion configuration
    aliases      # Aliases and named directories
    functions    # Utility functions
    integrations # External tools (nvm, rbenv, gcloud, etc.)
    status       # Status functions for prompt
    prompt       # Prompt configuration
)

for _mod in "${_zsh_modules[@]}"; do
    local _mod_file="$ZSHRC_DIR/.zsh/${_mod}.zsh"
    if [[ -f "$_mod_file" ]]; then
        source "$_mod_file"
    else
        echo "Warning: Module not found: $_mod_file" >&2
    fi
done
unset _zsh_modules _mod _mod_file

# -----------------------------------------------------------------------------
# Local Overrides
# -----------------------------------------------------------------------------
# Source local configuration if exists (machine-specific settings)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
