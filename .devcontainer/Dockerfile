# syntax=docker/dockerfile:1.10
# Image for local development (Dev Containers, Codespaces) and every CI job.
# Build it from the repository root.

FROM mcr.microsoft.com/devcontainers/base:2.2.5-trixie@sha256:71b6fe7c4e07ec747a94a72b2a17f2f8c286eaa7b1c59862888df764efb8b6c6

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    CARGO_TERM_COLOR=always

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Layers go from least to most often changed, so rebuilds reuse the cache.
# 1) rustup (pinned and checksum-verified), then stable and nightly.
COPY .devcontainer/install-tools.sh .devcontainer/tools.toml rust-toolchain.toml /tmp/build/
RUN /tmp/build/install-tools.sh /tmp/build rustup \
    && /tmp/build/install-tools.sh /tmp/build toolchains

# 2) Tools. The optional github_token secret avoids GitHub API rate limits;
# without it some tools may be compiled from source, which is slower.
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN \
    /tmp/build/install-tools.sh /tmp/build tools

# 3) MSRV toolchain (`just msrv` also installs it if missing).
COPY Cargo.toml /tmp/build/
RUN /tmp/build/install-tools.sh /tmp/build msrv \
    && rm -rf /tmp/build \
    && chown -R vscode:vscode "$RUSTUP_HOME" "$CARGO_HOME"
