# syntax=docker/dockerfile:1
FROM node:22.16.0-bookworm-slim

LABEL org.opencontainers.image.source="https://github.com/sharkusmanch/hermes"
LABEL org.opencontainers.image.description="iOS-accessible terminal toolbox for k3s"

# ============================================================================
# VERSION PINS - Renovate will auto-update these
# ============================================================================

# renovate: datasource=github-releases depName=tsl0922/ttyd
ARG TTYD_VERSION="1.7.7"

# renovate: datasource=github-releases depName=kubernetes/kubernetes
ARG KUBECTL_VERSION="1.32.3"

# renovate: datasource=github-releases depName=helm/helm
ARG HELM_VERSION="3.17.3"

# renovate: datasource=github-releases depName=derailed/k9s
ARG K9S_VERSION="0.50.4"

# renovate: datasource=github-releases depName=rclone/rclone
ARG RCLONE_VERSION="1.69.1"

# renovate: datasource=github-releases depName=fluxcd/flux2
ARG FLUX_VERSION="2.4.0"

# renovate: datasource=github-releases depName=stern/stern
ARG STERN_VERSION="1.32.0"

# renovate: datasource=github-releases depName=ahmetb/kubectx
ARG KUBECTX_VERSION="0.9.5"

# renovate: datasource=github-releases depName=mikefarah/yq
ARG YQ_VERSION="4.45.4"

# renovate: datasource=github-releases depName=atuinsh/atuin
ARG ATUIN_VERSION="18.4.0"

# renovate: datasource=npm depName=@anthropic-ai/claude-code
ARG CLAUDE_CODE_VERSION="1.0.16"

# ============================================================================
# SYSTEM PACKAGES
# ============================================================================

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    # Terminal
    tmux \
    # Shell utilities
    bash-completion \
    curl \
    wget \
    git \
    jq \
    ripgrep \
    fzf \
    htop \
    ncdu \
    tree \
    unzip \
    ca-certificates \
    # Editors
    vim \
    nano \
    # Networking
    dnsutils \
    iputils-ping \
    netcat-openbsd \
    openssh-client \
    # Python (for misc scripts)
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# ============================================================================
# TOOL INSTALLATIONS
# ============================================================================

# ttyd - web terminal
RUN curl -fsSL "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.x86_64" \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd

# kubectl
RUN curl -fsSL "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl

# helm
RUN curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" \
    | tar -xzf - --strip-components=1 -C /usr/local/bin linux-amd64/helm

# k9s
RUN curl -fsSL "https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_amd64.tar.gz" \
    | tar -xzf - -C /usr/local/bin k9s

# rclone
RUN curl -fsSL "https://downloads.rclone.org/v${RCLONE_VERSION}/rclone-v${RCLONE_VERSION}-linux-amd64.zip" \
    -o /tmp/rclone.zip \
    && unzip -j /tmp/rclone.zip "*/rclone" -d /usr/local/bin \
    && rm /tmp/rclone.zip \
    && chmod +x /usr/local/bin/rclone

# flux CLI
RUN curl -fsSL "https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_amd64.tar.gz" \
    | tar -xzf - -C /usr/local/bin flux

# stern - multi-pod log tailing
RUN curl -fsSL "https://github.com/stern/stern/releases/download/v${STERN_VERSION}/stern_${STERN_VERSION}_linux_amd64.tar.gz" \
    | tar -xzf - -C /usr/local/bin stern

# kubectx + kubens
RUN curl -fsSL "https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}/kubectx_v${KUBECTX_VERSION}_linux_x86_64.tar.gz" \
    | tar -xzf - -C /usr/local/bin kubectx \
    && curl -fsSL "https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}/kubens_v${KUBECTX_VERSION}_linux_x86_64.tar.gz" \
    | tar -xzf - -C /usr/local/bin kubens

# yq - YAML processor
RUN curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64" \
    -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# Atuin - shell history sync
RUN curl -fsSL "https://github.com/atuinsh/atuin/releases/download/v${ATUIN_VERSION}/atuin-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xzf - -C /usr/local/bin --strip-components=1 atuin-x86_64-unknown-linux-musl/atuin

# Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# ============================================================================
# USER SETUP
# ============================================================================

# Remove existing node user (UID 1000) and create toolbox user
RUN userdel -r node 2>/dev/null || true \
    && useradd -m -s /bin/bash -u 1000 toolbox

# Setup bash configuration
COPY --chown=toolbox:toolbox config/bashrc /home/toolbox/.bashrc
COPY --chown=toolbox:toolbox config/tmux.conf /home/toolbox/.tmux.conf

# Create config directories
RUN mkdir -p /home/toolbox/.config/atuin && chown -R toolbox:toolbox /home/toolbox/.config

# Switch to non-root user
USER toolbox
WORKDIR /home/toolbox

# ============================================================================
# RUNTIME
# ============================================================================

EXPOSE 7681

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:7681/ || exit 1

# -W: Wait for client before starting process
# -t: Set terminal title
CMD ["ttyd", "-p", "7681", "-W", "-t", "titleFixed=HERMES", "tmux", "new-session", "-A", "-s", "main"]
