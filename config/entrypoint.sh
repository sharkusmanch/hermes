#!/bin/bash
set -e

# ============================================================================
# Hermes Entrypoint Script
# ============================================================================

THEMES_DIR="/home/toolbox/.config/themes"
PERSIST_DIR="/home/toolbox/persist"

# ============================================================================
# PERSISTENT STORAGE SETUP
# ============================================================================
# When a PVC is mounted at /home/toolbox/persist, automatically symlink
# common config directories to preserve state across restarts.

if [[ -d "$PERSIST_DIR" && "${HERMES_PERSIST_DISABLE:-}" != "true" ]]; then
    echo "Persistent storage detected at $PERSIST_DIR"

    # Directories to persist (relative to $HOME)
    PERSIST_DIRS=(".claude" ".kube" ".ssh" ".config/atuin" ".local" ".bash_history")

    for dir in "${PERSIST_DIRS[@]}"; do
        persist_path="$PERSIST_DIR/$dir"
        home_path="$HOME/$dir"

        # Create parent directories in persist if needed
        mkdir -p "$(dirname "$persist_path")"

        # Skip if already a symlink
        if [[ -L "$home_path" ]]; then
            continue
        fi

        # If persist path doesn't exist, create it (copy existing if present)
        if [[ ! -e "$persist_path" ]]; then
            if [[ -e "$home_path" ]]; then
                # Copy existing data to persist
                cp -a "$home_path" "$persist_path"
            elif [[ "$dir" == *"/"* ]]; then
                # Nested directory - create as directory
                mkdir -p "$persist_path"
            else
                # Top-level - create as directory
                mkdir -p "$persist_path"
            fi
        fi

        # Remove existing file/dir and create symlink
        if [[ -e "$home_path" || -L "$home_path" ]]; then
            rm -rf "$home_path"
        fi

        # Ensure parent exists
        mkdir -p "$(dirname "$home_path")"

        ln -sf "$persist_path" "$home_path"
        echo "  Linked $dir -> persist"
    done
fi

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
