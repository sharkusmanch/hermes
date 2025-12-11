# Hermes

A web-based terminal toolbox with Kubernetes tools, shell utilities, and runtime extensibility via Homebrew.

## Features

- **Web Terminal** - Access via browser using ttyd + tmux
- **Kubernetes Tools** - kubectl, helm, k9s, flux, stern, kubectx/kubens
- **Developer Utilities** - git, vim, jq, yq, ripgrep, fzf, rclone
- **AI Assistant** - Claude Code CLI pre-installed
- **Shell History Sync** - Atuin for cross-session history
- **Runtime Extensibility** - Install additional tools via Homebrew at startup

## What's Included

| Tool | Purpose |
|------|---------|
| ttyd | Web terminal server |
| tmux | Terminal multiplexer |
| kubectl | Kubernetes CLI |
| helm | Kubernetes package manager |
| k9s | Kubernetes TUI |
| flux | GitOps toolkit |
| stern | Multi-pod log tailing |
| kubectx/kubens | Context/namespace switching |
| rclone | Cloud storage operations |
| yq | YAML processor |
| atuin | Shell history sync |
| claude | Claude Code CLI |
| brew | Homebrew for runtime package installation |

## Usage

```bash
docker pull ghcr.io/sharkusmanch/hermes:latest

# Run with web terminal
docker run -p 7681:7681 ghcr.io/sharkusmanch/hermes:latest

# Run with additional brew packages
docker run -p 7681:7681 -e HERMES_BREW_PACKAGES="gh lazygit" ghcr.io/sharkusmanch/hermes:latest

# Run with custom title
docker run -p 7681:7681 -e HERMES_WINDOW_TITLE="prod-cluster" ghcr.io/sharkusmanch/hermes:latest
```

Access at http://localhost:7681

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `HERMES_BREW_PACKAGES` | (empty) | Space-separated list of Homebrew packages to install at startup |
| `HERMES_WINDOW_TITLE` | `HERMES` | Browser window/tab title |
| `HERMES_PORT` | `7681` | ttyd listen port |
| `HERMES_THEME` | (empty) | Color theme: `dracula`, `gruvbox-dark`, `nord`, `tokyo-night`, `solarized-dark`, `catppuccin-mocha` |
| `HERMES_FONT_FAMILY` | (empty) | Terminal font family (e.g., `JetBrains Mono`, `Fira Code`) |
| `HERMES_FONT_SIZE` | (empty) | Terminal font size in pixels (e.g., `16`) |
| `HERMES_PERSIST_DISABLE` | (empty) | Set to `true` to disable automatic persist symlinks |

## Persistent Storage (Kubernetes)

When running in Kubernetes with a PVC mounted at `/home/toolbox/persist`, the entrypoint automatically symlinks common config directories to preserve state across pod restarts:

- `~/.claude` - Claude Code credentials
- `~/.kube` - Kubernetes config
- `~/.ssh` - SSH keys
- `~/.config/atuin` - Shell history
- `~/.local` - Local packages
- `~/.bash_history` - Bash history

**Example Kubernetes deployment:**

```yaml
volumeMounts:
  - name: hermes-data
    mountPath: /home/toolbox/persist
volumes:
  - name: hermes-data
    persistentVolumeClaim:
      claimName: hermes-pvc
```

On first startup, existing config is copied to the PVC. Subsequent restarts will use the persisted data.

## Versioning

- `latest` - Most recent main branch build
- `sha-<hash>` - Specific commit builds
- `YYYY.MM.patch` - CalVer releases (e.g., `2024.12.0`)

## Configuration

### Atuin Shell History

On first run, configure Atuin to sync shell history:

```bash
atuin-setup http://your-atuin-server:8888
atuin register -u <username> -e <email>
atuin sync -f
```

### Claude Code

```bash
claude login
```

### Homebrew at Runtime

Mount a Brewfile for automatic package installation:

```bash
docker run -v ~/.Brewfile:/home/toolbox/.Brewfile ghcr.io/sharkusmanch/hermes:latest
```

Or use init scripts for custom setup:

```bash
docker run -v ./my-init.sh:/home/toolbox/.init.d/my-init.sh ghcr.io/sharkusmanch/hermes:latest
```

## Development

```bash
# Build locally
docker build -t hermes:dev .

# Run with shell
docker run -it hermes:dev bash
```

## Tool Versions

Managed by Renovate. See version pins in `Dockerfile`.
