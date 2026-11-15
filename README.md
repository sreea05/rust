# Rust library template

A [cargo-generate](https://cargo-generate.github.io/cargo-generate/) template
for Rust library crates, with the tooling and CI set up from day one.
This README is not copied into generated projects.

## Create a new crate

```sh
cargo install cargo-generate
cargo generate --git https://github.com/sreea05/rust
```

You'll be asked for:

| Prompt | Default | Effect |
|---|---|---|
| Project name | — | Crate and repository name |
| Description | `A Rust library` | Cargo.toml, README, crate docs |
| GitHub owner | `sreea05` | Repository URLs, badges, CODEOWNERS |
| Uses `unsafe`? | no | No: `forbid(unsafe_code)`. Yes: `deny(unsafe_code)`, required `// SAFETY:` comments, and a Miri workflow |
| Fuzzing? | no | `fuzz/` crate with a cargo-fuzz target and a CI fuzz workflow |
| Benchmarks? | yes | `benches/` with a criterion benchmark |
| Codecov? | no | Codecov badge, `codecov.yml`, and upload steps in the docs |

Answers can be given up front, e.g. `-d uses_unsafe=true -d fuzzing=false`.

Then follow **One-time maintainer setup** in the generated `CONTRIBUTING.md`.

## What's included

- **Crate:** edition 2024, MSRV 1.96 (about stable minus 4), strict lints,
  docs.rs metadata.
- **Checks:** formatting, linting, spelling, tests, coverage, MSRV, feature
  combinations, dependency audit, breaking-API detection, workflow security.
- **Developer workflow:** a `justfile` command for every check, pre-commit
  hooks, VS Code settings, and a devcontainer.
- **CI (Linux):** every job runs in the devcontainer image and calls one
  `just` command; plus a weekly run on beta, nightly and the newest dependencies.
- **Dependency updates:** Renovate.
- **Releases:** release-plz release PRs, changelog from Conventional Commits,
  crates.io trusted publishing, optional GitHub App release bot.

Each tool and what it's for is listed under **Tools** in
[CONTRIBUTING.md](CONTRIBUTING.md#tools).


## Working on the template itself

The files at the repository root are the template, so they contain Liquid
placeholders such as `{{project-name}}` and don't build directly; this
repository's own CI fails for the same reason. To test a change, generate a
project from your working copy and run the checks in its devcontainer:

```sh
cargo generate --path . --name demo-lib -d description=Demo -d github_owner=you \
  -d uses_unsafe=true -d fuzzing=true -d benchmarks=true -d codecov=true
cd demo-lib
docker build -f .devcontainer/Dockerfile -t demo-lib-dev .
docker run --rm -v "$PWD":/work -w /work demo-lib-dev bash -c 'just setup && just ci'
```
