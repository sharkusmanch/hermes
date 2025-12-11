#!/bin/bash
set -e

# ============================================================================
# Hermes Entrypoint Script
# ============================================================================

THEMES_DIR="/home/toolbox/.config/themes"

# Ensure brew is in PATH
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install brew packages if HERMES_BREW_PACKAGES is set
if [[ -n "$HERMES_BREW_PACKAGES" ]]; then
    echo "Installing brew packages: $HERMES_BREW_PACKAGES"
    for pkg in $HERMES_BREW_PACKAGES; do
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

# Build ttyd command with configurable options
if [[ "$1" == "ttyd" ]]; then
    TTYD_ARGS=("-p" "${HERMES_PORT:-7681}")
    TTYD_ARGS+=("-W")
    TTYD_ARGS+=("-t" "titleFixed=${HERMES_WINDOW_TITLE:-HERMES}")

    # Font configuration
    if [[ -n "$HERMES_FONT_FAMILY" ]]; then
        TTYD_ARGS+=("-t" "fontFamily=${HERMES_FONT_FAMILY}")
    fi
    if [[ -n "$HERMES_FONT_SIZE" ]]; then
        TTYD_ARGS+=("-t" "fontSize=${HERMES_FONT_SIZE}")
    fi

    # Theme configuration
    if [[ -n "$HERMES_THEME" ]]; then
        THEME_FILE="${THEMES_DIR}/${HERMES_THEME}.json"
        if [[ -f "$THEME_FILE" ]]; then
            # Read theme JSON and compact it (remove newlines)
            THEME_JSON=$(tr -d '\n' < "$THEME_FILE" | tr -s ' ')
            TTYD_ARGS+=("-t" "theme=${THEME_JSON}")
        else
            echo "Warning: Theme '$HERMES_THEME' not found at $THEME_FILE"
            echo "Available themes: $(ls -1 "$THEMES_DIR" 2>/dev/null | sed 's/.json$//' | tr '\n' ' ')"
        fi
    fi

    # Skip past "ttyd" and original options we're overriding
    shift
    while [[ "${1:-}" == -* ]]; do
        case "$1" in
            -p) shift 2 ;;
            -W) shift ;;
            -t) shift 2 ;;
            *) TTYD_ARGS+=("$1"); shift ;;
        esac
    done

    exec ttyd "${TTYD_ARGS[@]}" "$@"
fi

# Execute other commands as-is
exec "$@"
