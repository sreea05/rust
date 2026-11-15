# {{project-name}} development guide

Everything about how this project is built, checked and released is in
this file.

1. [New repository checklist](#new-repository-checklist)
2. [Getting started](#getting-started)
3. [Commands](#commands)
4. [What runs automatically](#what-runs-automatically)
5. [Project rules](#project-rules)
6. [Tools](#tools)
7. [Configuration files](#configuration-files)

## New repository checklist

Do these after generating a project from the template.

### Once, before your first crate

- [ ] **Create the release bot** (optional, recommended). GitHub doesn't run
  CI on pull requests opened by a workflow's built-in token, so release PRs
  would show no checks. A GitHub App (a bot account you own) avoids that,
  and one app serves all your repositories:
  1. GitHub → your profile → *Settings* → *Developer settings* →
     *GitHub Apps* → *New GitHub App*.
  2. Name it (e.g. `{{github_owner}}-release-bot`), set any homepage URL,
     and untick *Webhook → Active*.
  3. Under *Repository permissions* set **Contents** and **Pull requests**
     to *Read and write*. Choose *Only on this account*, then *Create*.
  4. Note the **Client ID** and click *Generate a private key* (downloads a
     `.pem` file). Keep both; every repository needs them.

### For each new repository

- [ ] **Open the project in the devcontainer** (or run `just setup`). This
  creates `Cargo.lock` and installs the git hooks.
- [ ] **Fill in `keywords` and `categories`** in `Cargo.toml` so the crate
  can be found on crates.io (up to 5 of each; categories must come from
  <https://crates.io/category_slugs>).
- [ ] **Create the GitHub repository** `{{github_owner}}/{{project-name}}`
  (empty, no README or license), then commit everything, **including
  `Cargo.lock`**, and push to `main`. CI fails without `Cargo.lock`.
- [ ] **Make the devcontainer package public** (public repositories only).
  The first CI run creates it: repository → *Packages* → *devcontainer* →
  *Package settings* → *Change visibility*. This lets PRs from forks use it.
- [ ] **Enable private vulnerability reporting:** repository → *Settings* →
  *Advanced Security* (*Code security* on some accounts) → *Private
  vulnerability reporting* → *Enable*.
  `SECURITY.md` points reporters there.
- [ ] **Install Renovate** for the repository: <https://github.com/apps/renovate>
  → *Configure* → add the repository.
- [ ] **Connect the release bot:** install your GitHub App on the repository
  (app settings → *Install App*), then in the repository → *Settings* →
  *Secrets and variables* → *Actions* add:
  - the **variable** `RELEASE_APP_CLIENT_ID` with the Client ID;
  - the **secret** `RELEASE_APP_PRIVATE_KEY` with the whole `.pem` file.
- [ ] **Protect `main`:** repository → *Settings* → *Rules* → new branch
  ruleset requiring pull requests and the status checks `lint`, `test`,
  `msrv`, `hack`, `doc`, `deny`, `coverage`{% if uses_unsafe %}, `miri`{% endif %}{% if fuzzing %}, `fuzz`{% endif %}.
  Don't require `semver` (see [Commit messages](#commit-messages)).
{%- if codecov %}
- [ ] **Connect Codecov:** sign in at <https://codecov.io> with GitHub, add
  the repository, and save its upload token as the repository secret
  `CODECOV_TOKEN`. Until then the upload step is skipped.
{%- endif %}

### Before the first release

- [ ] **Publish the first version by hand.** crates.io only allows
  token-free publishing for crates that already exist:
  `cargo login` (token from <https://crates.io/settings/tokens>), then
  `cargo publish`.
- [ ] **Enable trusted publishing:** on crates.io, the crate → *Settings* →
  *Trusted Publishing* → *Add*: owner `{{github_owner}}`, repository
  `{{project-name}}`, workflow `release-plz.yml`, environment empty.
  From then on, releases happen by merging release PRs (see [Releases](#releases)).

## Getting started

Open the repository in the **devcontainer**: it has every toolchain and tool
CI uses, at the same versions.

- **VS Code:** install the Dev Containers extension, open the folder, and
  choose *Reopen in Container*.
- **GitHub Codespaces:** create a codespace from the repository page.

Without the container: install Rust with [rustup](https://rustup.rs) (it reads
`rust-toolchain.toml`), install the [tools](#tools) at the versions in
`.devcontainer/tools.toml`, then run `just setup`.

## Commands

Every check is a [`just`](https://just.systems) command, and CI runs the same
commands, so passing locally means passing in CI. Run `just` to list them.

| Command | What it does |
|---|---|
| `just ci` | Every check CI runs on a pull request; run before pushing |
| `just fmt` | Format Rust and TOML files |
| `just lint` | Formatting, lints, spelling and workflow security checks |
| `just test` | Unit, integration and doc tests |
| `just msrv` | Build on the oldest supported Rust version |
| `just hack` | Check every combination of feature flags |
| `just doc` / `just doc-open` | Build the docs the way docs.rs does |
| `just deny` | Check dependency licenses, security advisories and sources |
| `just cov` | Measure test coverage |
| `just semver` | Check for breaking API changes against `origin/main` |
| `just test-latest` | Test with the newest compatible dependency versions |
| `just test-toolchain <name>` | Test on another toolchain, e.g. `beta` |
{%- if benchmarks %}
| `just bench` | Run the benchmarks in `benches/` |
{%- endif %}
{%- if uses_unsafe %}
| `just miri` | Run the tests under Miri to find undefined behaviour |
{%- endif %}
{%- if fuzzing %}
| `just fuzz [seconds]` | Run each fuzz target in `fuzz/` (default 60 s each) |
{%- endif %}

## What runs automatically

### Git hook

Before each commit, [lefthook](https://lefthook.dev) checks formatting and
spelling of the staged files. Slower checks are left to `just ci` and CI.

### CI

Every job runs one `just` command inside the devcontainer image, so any
failure can be reproduced locally with the same command.

| Workflow | When | What it does |
|---|---|---|
| CI | Every push to `main` and every PR | `lint`, `test`, `msrv`, `hack`, `doc`, `deny`, `coverage`; on PRs also `semver` |
{%- if uses_unsafe %}
| Miri | Every push to `main` and every PR | Tests under Miri |
{%- endif %}
{%- if fuzzing %}
| Fuzz | Every push to `main` and every PR | Each fuzz target for 60 s; crash inputs are uploaded as an artifact |
{%- endif %}
| Scheduled | Mondays | Rebuilds the image from scratch, tests on beta and nightly and with the newest dependencies, re-checks advisories |
| Release | Every push to `main` | See [Releases](#releases) |

The devcontainer image is built once and stored in the repository's GitHub
packages, tagged with a hash of the files it's built from; it's only rebuilt
when they change. The coverage summary appears on each CI run's summary page{% if codecov %}
and is uploaded to Codecov{% endif %}.

GitHub pauses scheduled workflows after 60 days without activity in the
repository; re-enable them from the *Actions* tab.

### Releases

[release-plz](https://release-plz.dev) handles releases:

1. Every push to `main` opens or updates a **release PR** that bumps the
   version (based on the [commit messages](#commit-messages) and an API
   check) and updates `CHANGELOG.md`.
2. Merging it tags the commit, creates a GitHub release, and publishes to
   crates.io using trusted publishing, so no crates.io token is stored.

### Dependency updates

[Renovate](https://docs.renovatebot.com) opens update PRs on Monday mornings
for Cargo dependencies, `Cargo.lock`, GitHub Actions, the devcontainer base
image, the tool versions in `.devcontainer/tools.toml`, and the stable
toolchain. New releases wait 14 days before being proposed (except Rust
itself), which avoids picking up broken or malicious releases.

## Project rules

### Commit messages

Commit messages and PR titles follow
[Conventional Commits](https://www.conventionalcommits.org/); release-plz turns
them into the version bump and changelog:

- `feat:` new functionality → minor version bump
- `fix:` bug fix → patch version bump
- `feat!:` / `fix!:` or a `BREAKING CHANGE:` footer → breaking release
- `docs:`, `test:`, `refactor:`, `perf:`, `ci:`, `build:`, `chore:` → no release on their own

Keep each commit to one logical change. When the `semver` check fails, the PR
changes the public API in a breaking way: mark the commit as breaking
(`feat!:`) rather than necessarily undoing it. The check catches removed or
renamed items but not changed parameter types.

### Code

- **Lints** are set in `Cargo.toml` under `[lints]`: clippy's pedantic
  group, documentation required for every public item, and no stray
  `dbg!`, `todo!` or `println!`. CI treats every warning as an error.
{%- if uses_unsafe %}
- **`unsafe`** is denied by default. A module that needs it opts in with
  `#[allow(unsafe_code)]`; every `unsafe` block needs a `// SAFETY:` comment
  and every `unsafe fn` a `# Safety` doc section. Miri checks it in CI.
{%- else %}
- **`unsafe`** code is forbidden.
{%- endif %}
- **Formatting** uses rustfmt and taplo with the repository's configs;
  editors pick them up automatically.

### Supported Rust versions

- **Development** uses the stable version pinned in `rust-toolchain.toml`.
- **Minimum supported version (MSRV)** is `rust-version` in `Cargo.toml`:
  roughly the last six months of releases (stable minus 4). Raise it in a
  minor release and note it in the changelog.
- **docs.rs** builds with nightly, which `just doc` mirrors.

## Tools

Everything below is preinstalled in the devcontainer. Versions are pinned in
`.devcontainer/tools.toml` and `rust-toolchain.toml`.

| Tool | Purpose | Used by |
|---|---|---|
| [just](https://just.systems) | Runs the project's commands | every command |
| rustfmt | Formats Rust code | `just fmt`, `just lint` |
| clippy | Rust linter | `just lint` |
| [taplo](https://taplo.tamasfe.dev) | Formats TOML files | `just fmt`, `just lint` |
| [typos](https://github.com/crate-ci/typos) | Spell-checker for code and docs | `just lint`, git hook |
| [zizmor](https://docs.zizmor.sh) | Security audit of the GitHub Actions workflows | `just lint` |
| [cargo-nextest](https://nexte.st) | Faster test runner with clearer output | `just test`, `just cov` |
| [cargo-llvm-cov](https://github.com/taiki-e/cargo-llvm-cov) | Measures test coverage | `just cov` |
| [cargo-hack](https://github.com/taiki-e/cargo-hack) | Checks every feature-flag combination | `just hack` |
| [cargo-deny](https://embarkstudios.github.io/cargo-deny/) | Checks dependency licenses, security advisories and sources | `just deny` |
| [cargo-semver-checks](https://github.com/obi1kenobi/cargo-semver-checks) | Detects breaking public-API changes | `just semver`, releases |
| [lefthook](https://lefthook.dev) | Runs fast checks as a git hook | `just setup` |
| [cargo-binstall](https://github.com/cargo-bins/cargo-binstall) | Installs the tools above as prebuilt binaries | devcontainer build |
| MSRV toolchain | Builds with the oldest supported Rust version | `just msrv` |
| Nightly toolchain | Builds docs the way docs.rs does{% if uses_unsafe %}; runs Miri{% endif %}{% if fuzzing %}; runs fuzzing{% endif %} | `just doc`{% if uses_unsafe %}, `just miri`{% endif %}{% if fuzzing %}, `just fuzz`{% endif %} |
{%- if uses_unsafe %}
| [Miri](https://github.com/rust-lang/miri) | Detects undefined behaviour in unsafe code | `just miri` |
{%- endif %}
{%- if fuzzing %}
| [cargo-fuzz](https://rust-fuzz.github.io/book/cargo-fuzz.html) | Runs the fuzz targets with libFuzzer | `just fuzz` |
{%- endif %}
{%- if benchmarks %}
| [criterion](https://bheisler.github.io/criterion.rs/book/) | Benchmark library (a dev-dependency, not a tool) | `just bench` |
{%- endif %}

## Configuration files

| File | Configures |
|---|---|
| `Cargo.toml` | Package metadata, MSRV, lints, docs.rs build |
| `rust-toolchain.toml` | Pinned stable toolchain |
| `justfile` | All commands |
| `.devcontainer/` | Dev and CI image: `Dockerfile`, tool versions (`tools.toml`), install script |
| `.github/workflows/` | CI, release and scheduled workflows |
| `.github/` (other files) | Issue and PR templates, `CODEOWNERS` |
| `rustfmt.toml`, `taplo.toml`, `.editorconfig` | Formatting |
| `clippy.toml` | Clippy settings (lint levels are in `Cargo.toml`) |
| `typos.toml` | Spell-checker exceptions |
| `deny.toml` | Allowed licenses, advisory and source rules |
| `.config/nextest.toml` | Test runner settings |
| `lefthook.yml` | Git hook |
| `release-plz.toml` | Release settings |
| `renovate.json` | Dependency update rules |
{%- if codecov %}
| `codecov.yml` | Codecov thresholds and PR comments |
{%- endif %}
| `.vscode/` | Editor settings and recommended extensions |
