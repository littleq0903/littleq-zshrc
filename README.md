# littleq-zshrc

Shell configuration for zsh and bash by Colin Su.

## Screenshots

![zshrc-screenshot-1](https://cloud.githubusercontent.com/assets/374786/5473450/7828d20e-8644-11e4-8a52-4606e4cadc15.png)

![zshrc-screenshot-2](https://cloud.githubusercontent.com/assets/374786/5473451/782ae26a-8644-11e4-9f90-2ea0d3ea1228.png)

![zshrc-screenshot-3](https://cloud.githubusercontent.com/assets/374786/5473449/78264e08-8644-11e4-9d55-ded54ffa4b11.png)

## Features

- Two-line prompt with dynamic fill bar
- Git branch and status indicators (modified, staged, untracked)
- Git-relative path display with powerline icon
- Python virtualenv detection
- Node.js version display (when package.json present)
- CLAUDE.md detection indicator
- Command execution time tracking
- Battery status with charging indicator (macOS/Linux)
- Background jobs counter
- Beautified auto-completion

## Setup

### Quick Install

```bash
git clone git@github.com:littleq0903/littleq-zshrc.git ~/github/littleq-zshrc
cd ~/github/littleq-zshrc
./setup.sh
```

### Options

```bash
./setup.sh           # Install both zsh and bash configs
./setup.sh --zsh     # Install only zsh configuration
./setup.sh --bash    # Install only bash configuration
./setup.sh --deps    # Install dependencies only (zsh-syntax-highlighting)
./setup.sh --no-deps # Skip dependency installation
```

The setup script:
- Creates symlinks to your home directory
- Backs up existing config files
- Installs zsh-syntax-highlighting (via Homebrew/apt/dnf/pacman)

### Manual Install (zsh only)

```bash
mkdir -p ~/github/
cd ~/github
git clone git@github.com:littleq0903/littleq-zshrc.git
cd ~
ln -s ~/github/littleq-zshrc/.zshrc .
ln -s ~/github/littleq-zshrc/.zsh .
```

## Local Overrides

For machine-specific settings, create:
- `~/.zshrc.local` (for zsh)
- `~/.bashrc.local` (for bash)

These files are sourced at the end of the configuration.

## Prompt Format

```
┌─(user@host>tty|git:branch*|node:20.0.0)────────( repo/path)─┐
└─(exit|$$|$)─>                                  (datetime|🔋85%)─┘
```

Status indicators:
- `git:branch*` - Current branch with `*`=modified, `+`=staged, `?`=untracked
- `claude:✓` - CLAUDE.md file detected in directory tree
- `node:X.X.X` - Node version when package.json is present
- `env:name` - Active Python virtualenv
- `jobs:N` - Background job count
- `⏱Xs` - Last command execution time
