#!/usr/bin/env bash
# Installs the pinned toolchains and tools into the devcontainer image.
# Usage: install-tools.sh <dir> <rustup|toolchains|tools|msrv|all>
# <dir> contains tools.toml, rust-toolchain.toml and (for msrv) Cargo.toml.
set -euo pipefail

src=${1:?usage: install-tools.sh <dir>}
tools="$src/tools.toml"

# value <section> <key>: print a value from tools.toml.
value() {
    awk -v section="[$1]" -v key="$2" '
        /^\[/ { in_section = ($0 == section); next }
        in_section && index($0, key " = ") == 1 {
            v = substr($0, length(key) + 4); gsub(/^"|"$/, "", v); print v; exit
        }' "$tools"
}

# crate_specs: print each [crates] entry as `name@version`.
crate_specs() {
    awk '
        /^\[/ { in_section = ($0 == "[crates]"); next }
        in_section && /^[a-z]/ { gsub(/"/, "", $3); print $1 "@" $3 }' "$tools"
}

arch=$(uname -m) # x86_64 or aarch64
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

install_rustup() {
    local version base
    version=$(value bootstrap rustup)
    base="https://static.rust-lang.org/rustup/archive/$version/$arch-unknown-linux-gnu"
    curl -fsSL -o "$tmp/rustup-init" "$base/rustup-init"
    curl -fsSL -o "$tmp/rustup-init.sha256" "$base/rustup-init.sha256"
    echo "$(cut -d ' ' -f 1 "$tmp/rustup-init.sha256")  $tmp/rustup-init" | sha256sum --check --strict
    chmod +x "$tmp/rustup-init"
    "$tmp/rustup-init" -y --no-modify-path --profile minimal --default-toolchain none
}

install_toolchains() {
    # Stable from rust-toolchain.toml; also the default outside the repo.
    (cd "$src" && rustup toolchain install)
    local stable
    stable=$(sed -n 's/^channel = "\(.*\)"$/\1/p' "$src/rust-toolchain.toml")
    rustup default "$stable"

    # Nightly, for docs.rs-style docs, Miri and fuzzing.
    local nightly components
    nightly=$(value rust nightly)
    components=$(value rust nightly-components)
    rustup toolchain install "$nightly" --profile minimal --component "${components// /,}"
}

install_msrv() {
    local msrv
    msrv=$(sed -n 's/^rust-version = "\(.*\)"$/\1/p' "$src/Cargo.toml")
    rustup toolchain install "$msrv" --profile minimal
}

install_lefthook() {
    local version base
    version=$(value bootstrap lefthook)
    base="https://github.com/evilmartians/lefthook/releases/download/v$version"
    curl -fsSL -o "$tmp/lefthook_${version}_Linux_${arch}" "$base/lefthook_${version}_Linux_${arch}"
    curl -fsSL -o "$tmp/checksums.txt" "$base/lefthook_checksums.txt"
    (cd "$tmp" && grep " lefthook_${version}_Linux_${arch}\$" checksums.txt | sha256sum --check --strict)
    install -m 0755 "$tmp/lefthook_${version}_Linux_${arch}" /usr/local/bin/lefthook
}

install_taplo() {
    local version
    version=$(value bootstrap taplo)
    curl -fsSL "https://github.com/tamasfe/taplo/releases/download/$version/taplo-linux-$arch.gz" |
        gunzip >"$tmp/taplo"
    install -m 0755 "$tmp/taplo" /usr/local/bin/taplo
}

install_crates() {
    local version
    version=$(value bootstrap cargo-binstall)
    curl -fsSL "https://github.com/cargo-bins/cargo-binstall/releases/download/v$version/cargo-binstall-$arch-unknown-linux-musl.tgz" |
        tar -xz -C "$CARGO_HOME/bin"
    # Compiles from source when no prebuilt binary can be fetched
    # (e.g. GitHub API rate limit without a token).
    # shellcheck disable=SC2046 # one argument per crate is intended
    cargo binstall --no-confirm --locked --disable-telemetry $(crate_specs)
}

case "${2:-all}" in
    rustup) install_rustup ;;
    toolchains) install_toolchains ;;
    tools) install_lefthook && install_taplo && install_crates ;;
    msrv) install_msrv ;;
    all) install_rustup && install_toolchains && install_lefthook && install_taplo && install_crates && install_msrv ;;
    *) echo "unknown step: $2" >&2 && exit 1 ;;
esac
