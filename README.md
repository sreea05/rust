# Rust library template

A [cargo-generate](https://cargo-generate.github.io/cargo-generate/) template
for Rust library crates, with tooling, CI and releases set up from the start.

**Everything about the generated project (features, commands, CI, releases,
and the checklist for a new repository) is in [CONTRIBUTING.md](CONTRIBUTING.md).**
That file is copied into every generated project. This README is not.

## Create a new crate

```sh
cargo install cargo-generate
cargo generate --git https://github.com/sreea05/rust
```

Then work through the
[new repository checklist](CONTRIBUTING.md#new-repository-checklist).

You'll be asked for:

| Prompt | Default | Effect |
|---|---|---|
| Project name | — | Crate and repository name |
| Description | `A Rust library` | Cargo.toml, README, crate docs |
| GitHub owner | `sreea05` | Repository URLs, badges, CODEOWNERS, license |
| Uses `unsafe`? | no | No: unsafe code is forbidden. Yes: allowed per module with `// SAFETY:` comments, checked by Miri |
| Fuzzing? | no | `fuzz/` with a fuzz target, run in CI |
| Benchmarks? | yes | `benches/` with a criterion benchmark |
| Codecov? | no | Coverage uploads to Codecov, plus a badge |

Skip the prompts by passing answers, e.g. `-d uses_unsafe=true -d fuzzing=false`.

## Working on the template

Files are copied into generated projects with `{{placeholders}}` filled in,
so the template itself doesn't build. A few files are stored under other
names and renamed by `post-generate.rhai`, so they don't affect this
repository:

| In this repository | In generated projects |
|---|---|
| `README.project.md` | `README.md` |
| `LICENSE.project` | `LICENSE` |
| `.github-project/` | `.github/` |

The **Template** workflow (`.github/workflows/template.yml`) tests every
change: it generates a minimal and a full project and runs all their checks
in their devcontainer. To do the same locally:

```sh
cargo generate --path . --name demo-lib -d description=Demo -d github_owner=you \
  -d uses_unsafe=true -d fuzzing=true -d benchmarks=true -d codecov=true
cd demo-lib
docker build -f .devcontainer/Dockerfile -t demo-lib-dev .
docker run --rm -v "$PWD":/work -w /work demo-lib-dev bash -c 'just setup && just ci'
```
