# Rust library template

A [cargo-generate](https://cargo-generate.github.io/cargo-generate/) template
for Rust library crates, with tooling, CI and releases set up from the start.

- **This README:** creating a new crate and setting up its repository.
- **[CONTRIBUTING.md](CONTRIBUTING.md):** how a generated project works:
  commands, CI, releases, rules and tools. Every generated project gets a
  copy with its own names filled in; the copy here shows the raw template.

## What you get

- **Crate setup:** edition 2024, a minimum supported Rust version of about
  six months back, strict lints, docs built the way docs.rs builds them.
- **Checks:** formatting, lints, spelling, tests, coverage, oldest supported
  Rust version, feature combinations, dependency licenses and advisories,
  breaking-API detection, workflow security.
- **One command per check:** `just lint`, `just test` and so on; `just ci`
  runs them all, exactly as CI does.
- **Devcontainer:** every toolchain and tool at pinned versions, used both
  locally and by CI.
- **Automation:** CI on every push and PR, a weekly run against new Rust and
  dependency releases, Renovate update PRs, and releases to crates.io by
  merging a release PR.
- **Optional extras:** Miri for `unsafe` code, fuzzing, benchmarks, Codecov.

Details: [CONTRIBUTING.md](CONTRIBUTING.md).

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
| GitHub owner | `sreea05` | Repository URLs, badges, CODEOWNERS, license |
| Uses `unsafe`? | no | No: unsafe code is forbidden. Yes: allowed per module with `// SAFETY:` comments, checked by Miri |
| Fuzzing? | no | `fuzz/` with a fuzz target, run in CI |
| Benchmarks? | yes | `benches/` with a criterion benchmark |
| Codecov? | no | Coverage uploads to Codecov, plus a badge |

Skip the prompts by passing answers, e.g. `-d uses_unsafe=true -d fuzzing=false`.

Then work through the checklist below.

## New repository checklist

### Once, before your first crate

- [ ] **Create the release bot** (optional, recommended). GitHub doesn't run
  CI on pull requests opened by a workflow's built-in token, so release PRs
  would show no checks. A GitHub App (a bot account you own) avoids that,
  and one app serves all your repositories:
  1. GitHub → your profile → *Settings* → *Developer settings* →
     *GitHub Apps* → *New GitHub App*.
  2. Name it (e.g. `sreea05-release-bot`), set any homepage URL, and untick
     *Webhook → Active*.
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
- [ ] **Create the GitHub repository** with the project's name (empty, no
  README or license), then commit everything, **including `Cargo.lock`**,
  and push to `main`. CI fails without `Cargo.lock`.
- [ ] **Make the devcontainer package public** (public repositories only).
  The first CI run creates it: repository → *Packages* → *devcontainer* →
  *Package settings* → *Change visibility*. This lets PRs from forks use it.
- [ ] **Enable private vulnerability reporting:** repository → *Settings* →
  *Advanced Security* (*Code security* on some accounts) → *Private
  vulnerability reporting* → *Enable*. The project's `SECURITY.md` points
  reporters there.
- [ ] **Install Renovate** for the repository: <https://github.com/apps/renovate>
  → *Configure* → add the repository.
- [ ] **Connect the release bot:** install your GitHub App on the repository
  (app settings → *Install App*), then in the repository → *Settings* →
  *Secrets and variables* → *Actions* add:
  - the **variable** `RELEASE_APP_CLIENT_ID` with the Client ID;
  - the **secret** `RELEASE_APP_PRIVATE_KEY` with the whole `.pem` file.
- [ ] **Protect `main`:** repository → *Settings* → *Rules* → new branch
  ruleset requiring pull requests and the status checks `lint`, `test`,
  `msrv`, `hack`, `doc`, `deny`, `coverage`, plus `miri` and `fuzz` if
  enabled. Don't require `semver`
  ([why](CONTRIBUTING.md#commit-messages)).
- [ ] **Connect Codecov** (if enabled): sign in at <https://codecov.io> with
  GitHub, add the repository, and save its upload token as the repository
  secret `CODECOV_TOKEN`. Until then the upload step is skipped.

### Before the first release

- [ ] **Don't merge the first release PR yet.** release-plz opens one for
  `0.1.0` after your first push, but publishing from CI only works for
  crates that already exist on crates.io, so merging it now fails. Do the
  next two steps first; release-plz refreshes the PR on the next push to
  `main`.
- [ ] **Publish the first version by hand.** crates.io only allows
  token-free publishing for crates that already exist:
  `cargo login` (token from <https://crates.io/settings/tokens>), then
  `cargo publish`.
- [ ] **Enable trusted publishing:** on crates.io, the crate → *Settings* →
  *Trusted Publishing* → *Add*: your GitHub owner and repository name,
  workflow `release-plz.yml`, environment empty. From then on, releases
  happen by merging release PRs ([how](CONTRIBUTING.md#releases)).

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

Install [Renovate](https://github.com/apps/renovate) on this repository too,
so the pinned versions here (actions, tools, base image, toolchain) stay
current and new projects start up to date. Renovate can't parse the
templated `Cargo.toml`, so dependencies there are updated in each project
instead.

The **Template** workflow (`.github/workflows/template.yml`) tests every
change: it generates a minimal and a full project and runs all their checks
in their devcontainer. To do the same locally (`--path .` copies your
working copy as it is, including uncommitted and untracked files):

```sh
cargo generate --path . --name demo-lib -d description=Demo -d github_owner=you \
  -d uses_unsafe=true -d fuzzing=true -d benchmarks=true -d codecov=true
cd demo-lib
docker build -f .devcontainer/Dockerfile -t demo-lib-dev .
docker run --rm -v "$PWD":/work -w /work demo-lib-dev bash -c 'just setup && just ci'
```
