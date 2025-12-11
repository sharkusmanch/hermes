#!/bin/bash
set -e

# ============================================================================
# Hermes Entrypoint Script
# ============================================================================

# Ensure brew is in PATH
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install brew packages if BREW_PACKAGES is set
if [[ -n "$BREW_PACKAGES" ]]; then
    echo "Installing brew packages: $BREW_PACKAGES"
    for pkg in $BREW_PACKAGES; do
        if ! brew list "$pkg" &>/dev/null; then
            echo "Installing $pkg..."
            brew install "$pkg"
        else
            echo "$pkg already installed"
        fi
    done
    echo "Brew packages installed successfully"
fi

# Install packages from Brewfile if mounted
if [[ -f "$HOME/.Brewfile" ]]; then
    echo "Installing packages from ~/.Brewfile..."
    brew bundle --global --no-lock
    echo "Brewfile packages installed successfully"
fi

# Source any custom init scripts
if [[ -d "$HOME/.init.d" ]]; then
    for script in "$HOME"/.init.d/*.sh; do
        if [[ -f "$script" ]]; then
            echo "Running init script: $script"
            source "$script"
        fi
    done
fi

# Execute the main command
exec "$@"
