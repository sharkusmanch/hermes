# syntax=docker/dockerfile:1
FROM debian:trixie-slim

LABEL org.opencontainers.image.source="https://github.com/sharkusmanch/hermes"
LABEL org.opencontainers.image.description="Web-based terminal toolbox with Kubernetes tools and runtime extensibility"

# ============================================================================
# VERSION PINS - Renovate will auto-update these
# ============================================================================

# renovate: datasource=github-releases depName=nodejs/node
ARG NODE_VERSION="25.2.1"

# renovate: datasource=github-releases depName=tsl0922/ttyd
ARG TTYD_VERSION="1.7.7"

# renovate: datasource=github-releases depName=kubernetes/kubernetes
ARG KUBECTL_VERSION="1.34.3"

# renovate: datasource=github-releases depName=helm/helm
ARG HELM_VERSION="4.0.2"

# renovate: datasource=github-releases depName=derailed/k9s
ARG K9S_VERSION="0.50.16"

# renovate: datasource=github-releases depName=rclone/rclone
ARG RCLONE_VERSION="1.72.1"

# renovate: datasource=github-releases depName=fluxcd/flux2
ARG FLUX_VERSION="2.7.5"

# renovate: datasource=github-releases depName=stern/stern
ARG STERN_VERSION="1.33.1"

# renovate: datasource=github-releases depName=ahmetb/kubectx
ARG KUBECTX_VERSION="0.9.5"

# renovate: datasource=github-releases depName=mikefarah/yq
ARG YQ_VERSION="4.49.2"

# renovate: datasource=github-releases depName=atuinsh/atuin
ARG ATUIN_VERSION="18.10.0"

# renovate: datasource=npm depName=@anthropic-ai/claude-code
ARG CLAUDE_CODE_VERSION="2.0.65"

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
    xz-utils \
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
    # Homebrew/system dependencies
    procps \
    file \
    # Locale support (for Unicode/UTF-8)
    locales \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen

# UTF-8 locale (can be overridden at runtime)
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ============================================================================
# NODE.JS INSTALLATION
# ============================================================================

RUN curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
    | tar -xJf - -C /usr/local --strip-components=1 \
    && node --version && npm --version

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

# Create toolbox user
RUN useradd -m -s /bin/bash -u 1000 toolbox

# Setup bash configuration
COPY --chown=toolbox:toolbox config/bashrc /home/toolbox/.bashrc
COPY --chown=toolbox:toolbox config/tmux.conf /home/toolbox/.tmux.conf

# Create config directories and copy themes
RUN mkdir -p /home/toolbox/.config/atuin /home/toolbox/.config/themes \
    && chown -R toolbox:toolbox /home/toolbox/.config
COPY --chown=toolbox:toolbox config/themes/ /home/toolbox/.config/themes/

# Create Homebrew directory with proper ownership (must be done as root)
RUN mkdir -p /home/linuxbrew/.linuxbrew \
    && chown -R toolbox:toolbox /home/linuxbrew

# Switch to non-root user
USER toolbox
WORKDIR /home/toolbox

# ============================================================================
# HOMEBREW (as non-root user)
# ============================================================================

# Install Homebrew (pinned to specific commit for supply chain security)
# To update: curl -s "https://api.github.com/repos/Homebrew/install/commits/HEAD" | jq -r '.sha'
ARG HOMEBREW_INSTALL_COMMIT="b45f3d7ffb7aa2992976c154b7f645c86f483d91"
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/${HOMEBREW_INSTALL_COMMIT}/install.sh)"

# Add brew to PATH for subsequent commands
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

# Disable analytics
RUN brew analytics off

# ============================================================================
# RUNTIME
# ============================================================================

# Copy entrypoint script
COPY --chown=toolbox:toolbox config/entrypoint.sh /home/toolbox/entrypoint.sh
RUN chmod +x /home/toolbox/entrypoint.sh

EXPOSE 7681

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:7681/ || exit 1

# ============================================================================
# HERMES CONFIGURATION (all env vars prefixed with HERMES_)
# ============================================================================
# HERMES_BREW_PACKAGES: space-separated list of brew packages to install at startup
# HERMES_WINDOW_TITLE: browser window/tab title (default: HERMES)
# HERMES_PORT: ttyd port (default: 7681)
# HERMES_THEME: color theme (dracula, gruvbox-dark, nord, tokyo-night, solarized-dark, catppuccin-mocha)
# HERMES_FONT_FAMILY: terminal font family
# HERMES_FONT_SIZE: terminal font size in pixels
# HERMES_USERNAME: username shown in prompt (default: hermes)
# HERMES_BASIC_AUTH_USER: basic auth username (optional, requires HERMES_BASIC_AUTH_PASS)
# HERMES_BASIC_AUTH_PASS: basic auth password (optional, requires HERMES_BASIC_AUTH_USER)
#
# Example: docker run -e HERMES_THEME="dracula" -e HERMES_USERNAME="marcus" hermes
# Example with auth: docker run -e HERMES_BASIC_AUTH_USER="admin" -e HERMES_BASIC_AUTH_PASS="secret" hermes

ENV HERMES_BREW_PACKAGES=""
ENV HERMES_WINDOW_TITLE="HERMES"
ENV HERMES_PORT="7681"
ENV HERMES_THEME=""
ENV HERMES_FONT_FAMILY=""
ENV HERMES_FONT_SIZE=""
ENV HERMES_USERNAME=""
ENV HERMES_BASIC_AUTH_USER=""
ENV HERMES_BASIC_AUTH_PASS=""

ENTRYPOINT ["/home/toolbox/entrypoint.sh"]
CMD ["ttyd", "-p", "7681", "-W", "-t", "titleFixed=HERMES", "tmux", "new-session", "-A", "-s", "main"]
