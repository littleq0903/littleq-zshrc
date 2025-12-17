# =============================================================================
# integrations.zsh - External tool integrations and PATH configuration
# =============================================================================

# -----------------------------------------------------------------------------
# PATH Configuration (consolidated)
# -----------------------------------------------------------------------------
typeset -U path  # Remove duplicates from PATH

# Local binaries
[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)

# Homebrew (macOS)
if [[ "$MACHINE_OS" == "macosx" ]]; then
    # Apple Silicon
    [[ -d "/opt/homebrew/bin" ]] && path=("/opt/homebrew/bin" $path)
    # Intel
    [[ -d "/usr/local/bin" ]] && path=("/usr/local/bin" $path)

    # GNU grep (brew install grep)
    [[ -d "/opt/homebrew/opt/grep/libexec/gnubin" ]] && \
        path=("/opt/homebrew/opt/grep/libexec/gnubin" $path)
fi

# -----------------------------------------------------------------------------
# NVM (Node Version Manager)
# -----------------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    # Lazy load nvm for faster shell startup
    nvm() {
        unfunction nvm
        source "$NVM_DIR/nvm.sh"
        [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
        nvm "$@"
    }

    # Also lazy load node, npm, npx
    for cmd in node npm npx; do
        eval "${cmd}() { unfunction ${cmd}; nvm use default >/dev/null; ${cmd} \"\$@\" }"
    done
fi

# -----------------------------------------------------------------------------
# rbenv (Ruby Version Manager)
# -----------------------------------------------------------------------------
if (( $+commands[rbenv] )); then
    eval "$(rbenv init - zsh)"
elif [[ -d "$HOME/.rbenv/bin" ]]; then
    path=("$HOME/.rbenv/bin" $path)
    eval "$(rbenv init - zsh)"
fi

# -----------------------------------------------------------------------------
# pyenv (Python Version Manager)
# -----------------------------------------------------------------------------
if (( $+commands[pyenv] )); then
    eval "$(pyenv init -)"
elif [[ -d "$HOME/.pyenv/bin" ]]; then
    export PYENV_ROOT="$HOME/.pyenv"
    path=("$PYENV_ROOT/bin" $path)
    eval "$(pyenv init -)"
fi

# -----------------------------------------------------------------------------
# Google Cloud SDK
# -----------------------------------------------------------------------------
# Check common installation locations
local gcloud_paths=(
    "$HOME/google-cloud-sdk"
    "/usr/local/google-cloud-sdk"
    "/opt/google-cloud-sdk"
    "$HOME/Downloads/google-cloud-sdk"  # Legacy location
)

for gcloud_dir in "${gcloud_paths[@]}"; do
    if [[ -d "$gcloud_dir" ]]; then
        [[ -s "$gcloud_dir/path.zsh.inc" ]] && source "$gcloud_dir/path.zsh.inc"
        [[ -s "$gcloud_dir/completion.zsh.inc" ]] && source "$gcloud_dir/completion.zsh.inc"
        break
    fi
done

# -----------------------------------------------------------------------------
# iTerm2 Shell Integration
# -----------------------------------------------------------------------------
if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
    [[ -e "$HOME/.iterm2_shell_integration.zsh" ]] && \
        source "$HOME/.iterm2_shell_integration.zsh"
fi

# -----------------------------------------------------------------------------
# FZF (Fuzzy Finder)
# -----------------------------------------------------------------------------
if (( $+commands[fzf] )); then
    # Use fd for fzf if available (faster than find)
    if (( $+commands[fd] )); then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi

    # Load fzf key bindings and completion
    [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
fi

# -----------------------------------------------------------------------------
# Zsh Syntax Highlighting
# -----------------------------------------------------------------------------
local syntax_hl_paths=(
    "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    "/usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
)

for hl_path in "${syntax_hl_paths[@]}"; do
    if [[ -f "$hl_path" ]]; then
        source "$hl_path"
        break
    fi
done

# -----------------------------------------------------------------------------
# Zsh Autosuggestions
# -----------------------------------------------------------------------------
local autosuggest_paths=(
    "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    "/usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
)

for as_path in "${autosuggest_paths[@]}"; do
    if [[ -f "$as_path" ]]; then
        source "$as_path"
        ZSH_AUTOSUGGEST_STRATEGY=(history completion)
        break
    fi
done

# -----------------------------------------------------------------------------
# Virtualenv Integration
# -----------------------------------------------------------------------------
local ZSHRC_DIR="${0:A:h:h}"
[[ -f "$ZSHRC_DIR/.virtualenv.zsh" ]] && source "$ZSHRC_DIR/.virtualenv.zsh"

# -----------------------------------------------------------------------------
# LM Studio CLI
# -----------------------------------------------------------------------------
[[ -d "$HOME/.lmstudio/bin" ]] && path+=("$HOME/.lmstudio/bin")

# -----------------------------------------------------------------------------
# Other Tool Paths
# -----------------------------------------------------------------------------
[[ -d "$HOME/.antigravity/antigravity/bin" ]] && \
    path=("$HOME/.antigravity/antigravity/bin" $path)

[[ -d "$HOME/.codeium/windsurf/bin" ]] && \
    path=("$HOME/.codeium/windsurf/bin" $path)

# Export the final PATH
export PATH
