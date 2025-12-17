# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is littleq's personal shell configuration repository providing custom zsh and bash configurations with a feature-rich two-line prompt displaying git status, battery info, virtualenv, node version, command execution time, and other contextual information.

## Installation

```bash
./setup.sh           # Install both zsh and bash configs
./setup.sh --zsh     # Install only zsh
./setup.sh --bash    # Install only bash
./setup.sh --deps    # Install dependencies only (zsh-syntax-highlighting)
```

The setup script creates symlinks from `~/.zshrc` and `~/.bashrc` to this repo and links the modular `.zsh/` directory.

## Architecture

### Zsh Configuration (Modular)

The `.zshrc` loads modules from `.zsh/` in this order:
1. **init.zsh** - OS detection, locale, history, shell options, key bindings
2. **completion.zsh** - Completion system configuration
3. **aliases.zsh** - Command aliases and named directories
4. **functions.zsh** - Utility functions (httpserver, extract, mkcd, etc.)
5. **integrations.zsh** - External tool integrations (nvm, rbenv, gcloud, etc.)
6. **status.zsh** - Status functions for prompt (`__git_info`, `__node_status`, `__venv_status`, `__claude_status`, `__compact_path`)
7. **prompt.zsh** - Two-line prompt with fill bar, colors, and right prompt with battery

### Bash Configuration (Monolithic)

`.bashrc` is self-contained with equivalent functionality to the zsh setup.

### Key Status Functions

All defined in `.zsh/status.zsh` (zsh) or `.bashrc` (bash):
- `__git_info` - Branch name with status flags (*=modified, +=staged, ?=untracked)
- `__git_path` / `__compact_path` - Git-relative path with powerline icon (U+E0A0)
- `__claude_status` - Detects CLAUDE.md in directory hierarchy
- `__node_status` - Shows node version when package.json present
- `__venv_status` - Shows active Python virtualenv name

### Prompt Structure

```
┌─(user@host>tty|git:branch*|claude:✓|node:20.0.0)────────( repo/path)─┐
└─(exit|$$|$)─>                                    (datetime|🔋85%)─┘
```

## Local Overrides

Machine-specific settings go in `~/.zshrc.local` or `~/.bashrc.local` (sourced at end of config).
