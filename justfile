# Every check is a recipe here, and CI runs these same recipes.
# Run `just` to list them. The comment line directly above a recipe is its
# description in that list; put longer explanations above it, separated by
# a blank line.

set shell := ["bash", "-euo", "pipefail", "-c"]

nightly := `sed -n 's/^nightly = "\(.*\)"$/\1/p' .devcontainer/tools.toml`
msrv := `sed -n 's/^rust-version = "\(.*\)"$/\1/p' Cargo.toml`

[private]
default:
    @just --list --unsorted

# One-time setup: create Cargo.lock if missing and install git hooks.
setup:
    cargo fetch
    lefthook install

# Run every check CI runs on a pull request.
ci: lint test msrv hack doc deny cov semver

# --- Formatting and linting -------------------------------------------------

# Format Rust and TOML files in place.
fmt:
    cargo fmt --all
    taplo fmt

# All lint checks: formatting, clippy, TOML, spelling, workflow audit.
lint: fmt-check clippy toml-check typos zizmor

# Check Rust formatting without changing files.
fmt-check:
    cargo fmt --all --check

# Run clippy on all targets and features; warnings are errors.
clippy:
    cargo clippy --locked --all-targets --all-features -- -D warnings

# Check TOML formatting without changing files.
toml-check:
    taplo fmt --check

# Spell-check the repository.
typos:
    typos

# Audit GitHub Actions workflows for security problems.
zizmor:
    zizmor --offline .github/workflows

# --- Tests ------------------------------------------------------------------

# Run unit, integration and doc tests.
test:
    cargo nextest run --locked --all-features --no-tests=warn
    cargo test --locked --all-features --doc

# Check the library builds on the minimum supported Rust version.
msrv:
    rustup toolchain install {{ msrv }} --profile minimal --no-self-update
    cargo +{{ msrv }} check --locked --all-features --lib

# Check every combination of feature flags.
hack:
    cargo hack check --locked --feature-powerset --all-targets

# Measure test coverage; writes target/lcov.info and prints a summary.
cov:
    cargo llvm-cov nextest --locked --all-features --no-tests=warn --lcov --output-path target/lcov.info
    cargo llvm-cov report --summary-only | tee target/coverage-summary.txt

# Update Cargo.lock to the newest compatible dependencies, then test.
test-latest:
    cargo update
    just test

# Run tests on another toolchain, e.g. `just test-toolchain beta`.
test-toolchain toolchain:
    rustup toolchain install {{ toolchain }} --profile minimal --no-self-update
    cargo +{{ toolchain }} test --locked --all-features

# --- Docs, dependencies, API ------------------------------------------------

# Build docs the way docs.rs does; warnings are errors.
doc:
    RUSTDOCFLAGS="--cfg docsrs -D warnings" cargo +{{ nightly }} doc --locked --no-deps --all-features

# Build docs and open them in a browser.
doc-open:
    RUSTDOCFLAGS="--cfg docsrs" cargo +{{ nightly }} doc --locked --no-deps --all-features --open

# Check dependency licenses, advisories, bans and sources.
deny:
    cargo deny --locked check

# PRs don't bump the version, so semver-checks would assume a major release
# and allow any break; `--release-type minor` makes it flag them.

# Fail if the public API breaks compared with a git ref.
semver baseline="origin/main":
    if git rev-parse --verify --quiet "{{ baseline }}^{commit}" >/dev/null; then \
        cargo semver-checks --baseline-rev "{{ baseline }}" --release-type minor; \
    else \
        echo "semver: baseline '{{ baseline }}' not found, skipping"; \
    fi

# --- Optional extras --------------------------------------------------------
# Recipes for the options chosen when the project was generated. Each file
# exists only if its option was chosen; `import?` skips missing files.

import? 'just/miri.just'
import? 'just/fuzz.just'
import? 'just/bench.just'
