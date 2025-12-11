#!/bin/bash
set -e

# ============================================================================
# Hermes Entrypoint Script
# ============================================================================

PERSIST_DIR="/home/toolbox/persist"
IMAGE_HOME="/home/toolbox"

# ============================================================================
# PERSISTENT STORAGE SETUP
# ============================================================================
# When a PVC is mounted at /home/toolbox/persist, use it as HOME.
# Essential config files are copied from the image on first run.

if [[ -d "$PERSIST_DIR" && "${HERMES_PERSIST_DISABLE:-}" != "true" ]]; then
    echo "Persistent storage detected at $PERSIST_DIR"

    # Bootstrap essential files on first run
    if [[ ! -f "$PERSIST_DIR/.bashrc" ]]; then
        echo "First run - copying essential config files..."
        cp -a "$IMAGE_HOME/.bashrc" "$PERSIST_DIR/"
        cp -a "$IMAGE_HOME/.tmux.conf" "$PERSIST_DIR/"
        cp -a "$IMAGE_HOME/.config" "$PERSIST_DIR/"
        echo "Config files copied to persist"
    fi

    # Use persist as HOME
    export HOME="$PERSIST_DIR"
    cd "$HOME"
    echo "HOME set to $HOME"
fi

# Theme directory (may be in persist or image home)
THEMES_DIR="$HOME/.config/themes"

# ============================================================================
# HOMEBREW PACKAGES
# ============================================================================

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

# ============================================================================
# CUSTOM INIT SCRIPTS
# ============================================================================

if [[ -d "$HOME/.init.d" ]]; then
    for script in "$HOME"/.init.d/*.sh; do
        if [[ -f "$script" ]]; then
            echo "Running init script: $script"
            source "$script"
        fi
    done
fi

# ============================================================================
# TTYD CONFIGURATION
# ============================================================================

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
