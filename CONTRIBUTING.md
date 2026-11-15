# Contributing to {{project-name}}

Thanks for helping! This guide covers the development setup, the checks
every change must pass, and how releases work.

## Development environment

The easiest setup is the **devcontainer**, which has the same toolchains
and tools as CI.

- **VS Code:** install the Dev Containers extension, open the repository,
  and choose *Reopen in Container*.
- **GitHub Codespaces:** create a codespace from the repository page.

`just setup` runs automatically when the container is created. It creates
`Cargo.lock` if it's missing and installs the git hooks.

Without the container: install Rust with [rustup](https://rustup.rs) (it
picks up `rust-toolchain.toml` automatically), install the tools listed in
`.devcontainer/tools.toml`, then run `just setup`.

## Everyday commands

Every check is a [`just`](https://just.systems) recipe, and CI runs these same
recipes, so passing locally means passing in CI. Run `just` to list them all.

| Command | What it does |
|---|---|
| `just ci` | Everything CI runs on a pull request |
| `just fmt` | Format Rust and TOML files |
| `just lint` | rustfmt check, clippy, taplo, typos, workflow audit |
| `just test` | Unit, integration and doc tests |
| `just msrv` | Build on the minimum supported Rust version |
| `just hack` | Check every feature-flag combination |
| `just doc` / `just doc-open` | Build the docs exactly as docs.rs does |
| `just deny` | Dependency licenses, advisories and sources |
| `just cov` | Test coverage report |
| `just semver` | Check for breaking API changes against `origin/main` |
| `just bench` | Run benchmarks (if the crate has them) |
| `just miri` | Run tests under Miri (for crates with `unsafe`) |
| `just fuzz [seconds]` | Run the fuzz targets (if the crate has them) |

The pre-commit hook only runs fast checks (formatting and spelling); run
`just ci` before opening a pull request.

## Commit messages and pull requests

Commits and PR titles follow [Conventional Commits](https://www.conventionalcommits.org/).
The changelog and version numbers are generated from them, so the type matters:

- `feat:` new functionality (minor version bump)
- `fix:` bug fix (patch version bump)
- `feat!:` / `fix!:`, or a `BREAKING CHANGE:` footer: breaking change
- `docs:`, `test:`, `refactor:`, `perf:`, `ci:`, `build:`, `chore:` and so on for everything else

Keep each commit to one logical change. The `semver` CI job fails when a PR
breaks the public API; that's a prompt to mark the change as breaking, not
necessarily to undo it.

## Releases

Releases are automated with [release-plz](https://release-plz.dev):

1. Every push to `main` opens or updates a **"chore: release"** pull request
   that bumps the version and updates `CHANGELOG.md`.
2. Merging that PR tags the commit, creates a GitHub release and publishes
   the crate to crates.io.

## One-time maintainer setup

These steps are needed once per repository, after creating it from the template.

1. **Push to GitHub.** The first CI run builds the devcontainer image and
   stores it in the repository's packages. For a public repository, make
   that package public (repository → *Packages* → *devcontainer* →
   *Package settings* → *Change visibility*) so PRs from forks can use it.


2. **First publish by hand.** crates.io trusted publishing only works for
   crates that already exist, so publish the first version from your machine:

   ```sh
   cargo login            # token from https://crates.io/settings/tokens
   cargo publish
   ```

3. **Enable trusted publishing.** On crates.io open the crate → *Settings* →
   *Trusted Publishing* → *Add*, and enter: owner `{{github_owner}}`,
   repository `{{project-name}}`, workflow `release-plz.yml`, environment empty.
   From then on CI publishes without any stored token.

4. **Install Renovate** for the repository from
   <https://github.com/apps/renovate> to get weekly dependency update PRs.

5. **Branch protection** (repository → *Settings* → *Rules*): require the CI
   checks `lint`, `test`, `msrv`, `hack`, `doc`, `deny` and `coverage`.
   Don't require `semver` (see above).

6. **Optional: release bot.** GitHub doesn't run CI on pull requests opened
   with the workflow's built-in token, so release PRs show no checks. To fix
   that, let a GitHub App (a bot account you own) open them instead:

   1. GitHub → your profile → *Settings* → *Developer settings* →
      *GitHub Apps* → *New GitHub App*.
   2. Name it (e.g. `{{github_owner}}-release-bot`), set the homepage to the
      repository URL, and untick *Webhook → Active*.
   3. Under *Repository permissions* set **Contents** and **Pull requests**
      to *Read and write*. Choose *Only on this account*, then *Create*.
   4. Note the **Client ID**, then *Generate a private key* (downloads a `.pem` file).
   5. *Install App* → choose this repository (you can add more later and reuse
      the same app for every crate).
   6. In the repository → *Settings* → *Secrets and variables* → *Actions*:
      - add the **variable** `RELEASE_APP_CLIENT_ID` with the Client ID;
      - add the **secret** `RELEASE_APP_PRIVATE_KEY` with the whole `.pem` file contents.

   The release workflow uses the app automatically once both are set.
{%- if codecov %}

7. **Codecov.** Sign in at <https://codecov.io> with GitHub, add the
   repository, and save its upload token as the repository secret
   `CODECOV_TOKEN`. Until then the upload step is skipped.
{%- endif %}
