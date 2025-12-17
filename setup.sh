#!/bin/bash
# setup.sh - Install littleq's shell configurations
# Supports both zsh and bash configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Backup directory with timestamp
BACKUP_DIR="$HOME/.shell-backup-$(date +%Y%m%d-%H%M%S)"

# ============================================================================
# Helper Functions
# ============================================================================

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

backup_file() {
    local file="$1"
    if [[ -e "$file" || -L "$file" ]]; then
        mkdir -p "$BACKUP_DIR"
        local basename=$(basename "$file")
        cp -P "$file" "$BACKUP_DIR/$basename" 2>/dev/null || true
        info "Backed up $file to $BACKUP_DIR/"
    fi
}

create_symlink() {
    local src="$1"
    local dest="$2"
    local name=$(basename "$dest")

    # Check if source exists
    if [[ ! -e "$src" ]]; then
        error "Source file not found: $src"
        return 1
    fi

    # Backup existing file
    backup_file "$dest"

    # Remove existing file/symlink
    if [[ -e "$dest" || -L "$dest" ]]; then
        rm -f "$dest"
    fi

    # Create symlink
    ln -s "$src" "$dest"
    success "Linked $name -> $src"
}

detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macosx" ;;
        Linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}

# ============================================================================
# Installation Functions
# ============================================================================

install_dependencies() {
    local os=$(detect_os)
    info "Detected OS: $os"

    if [[ "$os" == "linux" ]]; then
        if command -v apt &>/dev/null; then
            info "Installing zsh-syntax-highlighting via apt..."
            sudo apt install -y zsh-syntax-highlighting
            success "zsh-syntax-highlighting installed"
        elif command -v dnf &>/dev/null; then
            info "Installing zsh-syntax-highlighting via dnf..."
            sudo dnf install -y zsh-syntax-highlighting
            success "zsh-syntax-highlighting installed"
        elif command -v pacman &>/dev/null; then
            info "Installing zsh-syntax-highlighting via pacman..."
            sudo pacman -S --noconfirm zsh-syntax-highlighting
            success "zsh-syntax-highlighting installed"
        else
            warn "Could not detect package manager. Please install zsh-syntax-highlighting manually."
        fi
    elif [[ "$os" == "macosx" ]]; then
        if command -v brew &>/dev/null; then
            if ! brew list zsh-syntax-highlighting &>/dev/null; then
                info "Installing zsh-syntax-highlighting via Homebrew..."
                brew install zsh-syntax-highlighting
                success "zsh-syntax-highlighting installed"
            else
                success "zsh-syntax-highlighting already installed"
            fi
        else
            warn "Homebrew not found. Please install zsh-syntax-highlighting manually."
        fi
    fi
}

install_submodules() {
    info "Updating git submodules..."
    cd "$SCRIPT_DIR"
    git submodule update --init --recursive
    success "Git submodules updated"
}

install_zsh() {
    info "Installing zsh configuration..."

    # Create .zsh directory in home if it doesn't exist
    if [[ ! -d "$HOME/.zsh" ]]; then
        mkdir -p "$HOME/.zsh"
        success "Created ~/.zsh directory"
    fi

    # Link individual module files
    local modules=(init completion aliases functions integrations status prompt)
    for module in "${modules[@]}"; do
        local src="$SCRIPT_DIR/.zsh/${module}.zsh"
        local dest="$HOME/.zsh/${module}.zsh"
        if [[ -f "$src" ]]; then
            create_symlink "$src" "$dest"
        else
            warn "Module not found: $src"
        fi
    done

    # Link main files
    create_symlink "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
    create_symlink "$SCRIPT_DIR/.virtualenv.zsh" "$HOME/.virtualenv.zsh"

    success "zsh configuration installed"
}

install_bash() {
    info "Installing bash configuration..."

    create_symlink "$SCRIPT_DIR/.bashrc" "$HOME/.bashrc"

    # Also create .bash_profile to source .bashrc for login shells
    if [[ ! -f "$HOME/.bash_profile" ]] || ! grep -q "source.*\.bashrc" "$HOME/.bash_profile" 2>/dev/null; then
        backup_file "$HOME/.bash_profile"
        cat >> "$HOME/.bash_profile" << 'EOF'

# Source .bashrc for interactive shells
if [[ -f "$HOME/.bashrc" ]]; then
    source "$HOME/.bashrc"
fi
EOF
        success "Updated .bash_profile to source .bashrc"
    fi

    success "bash configuration installed"
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Install littleq's shell configurations"
    echo ""
    echo "Options:"
    echo "  --all         Install both zsh and bash configurations (default)"
    echo "  --zsh         Install only zsh configuration"
    echo "  --bash        Install only bash configuration"
    echo "  --deps        Install dependencies only"
    echo "  --no-deps     Skip dependency installation"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              # Install everything"
    echo "  $0 --zsh        # Install only zsh config"
    echo "  $0 --bash       # Install only bash config"
    echo "  $0 --all --no-deps  # Install configs without dependencies"
}

# ============================================================================
# Main
# ============================================================================

main() {
    local install_zsh_flag=false
    local install_bash_flag=false
    local install_deps_flag=true
    local deps_only=false

    # Parse arguments
    if [[ $# -eq 0 ]]; then
        install_zsh_flag=true
        install_bash_flag=true
    else
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --all)
                    install_zsh_flag=true
                    install_bash_flag=true
                    ;;
                --zsh)
                    install_zsh_flag=true
                    ;;
                --bash)
                    install_bash_flag=true
                    ;;
                --deps)
                    deps_only=true
                    ;;
                --no-deps)
                    install_deps_flag=false
                    ;;
                -h|--help)
                    show_usage
                    exit 0
                    ;;
                *)
                    error "Unknown option: $1"
                    show_usage
                    exit 1
                    ;;
            esac
            shift
        done
    fi

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   littleq's Shell Configuration Setup  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""

    # Install submodules
    install_submodules

    # Install dependencies
    if [[ "$install_deps_flag" == true ]]; then
        install_dependencies
    fi

    if [[ "$deps_only" == true ]]; then
        success "Dependencies installed. Exiting."
        exit 0
    fi

    # Install configurations
    if [[ "$install_zsh_flag" == true ]]; then
        install_zsh
    fi

    if [[ "$install_bash_flag" == true ]]; then
        install_bash
    fi

    echo ""
    if [[ -d "$BACKUP_DIR" ]]; then
        info "Backups saved to: $BACKUP_DIR"
    fi

    echo ""
    success "Installation complete!"
    echo ""
    echo "To apply changes:"
    if [[ "$install_zsh_flag" == true ]]; then
        echo "  - zsh:  source ~/.zshrc  (or restart terminal)"
    fi
    if [[ "$install_bash_flag" == true ]]; then
        echo "  - bash: source ~/.bashrc (or restart terminal)"
    fi
    echo ""
}

main "$@"
