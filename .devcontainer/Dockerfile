# syntax=docker/dockerfile:1.10
# Development image used both locally (VS Code Dev Containers / Codespaces)
# and by every CI job. Tool versions come from tools.toml.
# Build context is the repository root.

FROM mcr.microsoft.com/devcontainers/base:2.2.5-trixie@sha256:71b6fe7c4e07ec747a94a72b2a17f2f8c286eaa7b1c59862888df764efb8b6c6

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    CARGO_TERM_COLOR=always

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential pkg-config \
    && rm -rf /var/lib/apt/lists/*

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --no-modify-path --profile minimal --default-toolchain none

# Layers are ordered from least to most frequently changing so rebuilds
# stay cached. 1) stable (rust-toolchain.toml) and nightly (tools.toml).
COPY .devcontainer/install-tools.sh .devcontainer/tools.toml rust-toolchain.toml /tmp/build/
RUN /tmp/build/install-tools.sh /tmp/build toolchains

# 2) Tools from tools.toml. The optional github_token build secret avoids
# GitHub API rate limits; without it binstall may compile from source.
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN \
    /tmp/build/install-tools.sh /tmp/build tools

# 3) MSRV toolchain from Cargo.toml (`just msrv` also installs it on demand).
COPY Cargo.toml /tmp/build/
RUN /tmp/build/install-tools.sh /tmp/build msrv \
    && rm -rf /tmp/build \
    && chown -R vscode:vscode "$RUSTUP_HOME" "$CARGO_HOME"
