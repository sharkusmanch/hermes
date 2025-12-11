# Hermes

A web-based terminal toolbox for k3s, accessible from iOS via Tailscale.

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

## Usage

```bash
docker pull ghcr.io/sharkusmanch/hermes:latest

# Run locally
docker run -it -p 7681:7681 ghcr.io/sharkusmanch/hermes:latest
```

Access at http://localhost:7681

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

## Development

```bash
# Build locally
docker build -t hermes:dev .

# Run with shell
docker run -it hermes:dev bash
```

## Tool Versions

Managed by Renovate. See version pins in `Dockerfile`.
