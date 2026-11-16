# Rust library template

A template for starting a Rust library crate with everything around the
code already in place: checks, CI, branch protection, dependency updates and
releases to crates.io. Create a project from it with
[cargo-generate](https://cargo-generate.github.io/cargo-generate/), answer a
few questions, and get a crate that passes all its checks from the first
commit.

**The core idea:** every tool is pinned inside one container image, every
check is one `just` command, and CI runs the same commands in the same
image. What passes on your machine passes in CI.

- **This README:** what the template provides and how to create a crate.
- **[CONTRIBUTING.md](CONTRIBUTING.md):** how a generated project works,
  in detail, including how to set up its repository. Every project gets its own copy, describing only the options
  you chose. Read here, it still shows the template's placeholders, such as
  `{{project-name}}`, and `{% if %}` tags around the parts that depend on an
  option.

## What you get

- **Checks**, each one `just` command: [formatting](CONTRIBUTING.md#formatting),
  [lints](CONTRIBUTING.md#lints), [spelling](CONTRIBUTING.md#spelling),
  [tests](CONTRIBUTING.md#tests) (including README examples),
  [coverage](CONTRIBUTING.md#coverage),
  [oldest supported Rust version](CONTRIBUTING.md#minimum-supported-rust-version-msrv),
  [feature combinations](CONTRIBUTING.md#feature-combinations),
  [docs as docs.rs builds them](CONTRIBUTING.md#documentation),
  [dependency audit](CONTRIBUTING.md#dependency-audit),
  [breaking-API detection](CONTRIBUTING.md#api-compatibility-semver) and
  [workflow security](CONTRIBUTING.md#workflow-audit). `just ci` runs them all.
- **A [devcontainer](CONTRIBUTING.md#the-devcontainer)** with every toolchain
  and tool at pinned versions, for VS Code and GitHub Codespaces, reused by CI.
- **[CI](CONTRIBUTING.md#ci-workflows)** on every pull request and merge,
  plus a weekly run against new Rust versions and dependency releases.
- **A [protected `main`](CONTRIBUTING.md#the-protected-main-branch):** pull
  requests only, squash or rebase merges, CI must pass.
- **[Releases](CONTRIBUTING.md#releases)** started by pushing a `release/*`
  branch: version from commit messages, changelog written for you, published
  to crates.io without stored tokens.
- **[Dependency updates](CONTRIBUTING.md#dependency-updates)** proposed weekly
  by Renovate.
- **[Security](CONTRIBUTING.md#security-measures):** everything pinned,
  least-privilege workflows, verified downloads.
- **Optional extras**, chosen when generating: Miri, fuzzing and
  benchmarks.

## Create a new crate

### Prerequisites

| You need | For |
|---|---|
| [Rust](https://rustup.rs) | Running cargo-generate |
| [cargo-generate](https://cargo-generate.github.io/cargo-generate/) 0.26+ | Creating the project: `cargo install cargo-generate` |
| [Docker](https://docs.docker.com/get-docker/) and [VS Code](https://code.visualstudio.com) with [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) | Working in the devcontainer (or use GitHub Codespaces instead) |
| A GitHub account | The repository, CI and the release bot |
| A [crates.io](https://crates.io) account (sign in with GitHub) | Publishing |

### 1. Generate the project

```sh
cargo generate --git https://github.com/sreea05/rust
```

| Prompt | Default | Effect |
|---|---|---|
| Project name | — | Crate and repository name |
| Description | `A Rust library` | Used in `Cargo.toml`, the README and the crate docs |
| GitHub owner | `sreea05` | Repository URLs, badges, CODEOWNERS, license |
| Contact email | — | Where `CODE_OF_CONDUCT.md` asks people to send reports |
| Uses `unsafe`? | no | No: `unsafe` is forbidden. Yes: allowed per module with mandatory safety comments, plus [Miri](CONTRIBUTING.md#miri) in CI |
| Fuzzing? | no | Adds `fuzz/` and a CI fuzz run ([details](CONTRIBUTING.md#fuzzing)) |
| Benchmarks? | yes | Adds `benches/` with criterion ([details](CONTRIBUTING.md#benchmarks)) |

To skip the prompts, pass the answers:
`cargo generate --git https://github.com/sreea05/rust --name my-crate -d description="Does a thing" -d github_owner=you -d contact_email=you@example.com -d uses_unsafe=false -d fuzzing=false -d benchmarks=true`.
Every prompt needs an answer, or cargo-generate still asks for it.

### 2. Open it in the devcontainer

Open the folder in VS Code and choose **Reopen in Container**. The first build
takes several minutes. Then run `just ci`; everything should pass. More in
[Getting started](CONTRIBUTING.md#getting-started).

### 3. Replace the example code

The project contains an example function, `checked_add`, so every tool has
something to work on. Replace it with your own code in `src/lib.rs`,
`tests/api.rs`, `examples/basic.rs` and the usage example in `README.md`
(it's tested, so it must compile). If you enabled them, also rename
`benches/checked_add.rs` and `fuzz/fuzz_targets/checked_add.rs` and update
their names in `Cargo.toml` and `fuzz/Cargo.toml`. Run `just ci` again.

### 4. Set up the repository

Follow [Repository setup](CONTRIBUTING.md#repository-setup) in the
project's `CONTRIBUTING.md`: create the release bot (once per account),
create and protect the repository, connect the release bot and Renovate,
and publish the first version by hand. Every project gets this checklist
in its own `CONTRIBUTING.md`, filled in with its names, so it's still there
when you or another maintainer need it later.

## Troubleshooting

Problems in a generated project are covered in its
[Troubleshooting](CONTRIBUTING.md#troubleshooting) section. When creating one:

**`cargo generate` refuses the template, or the project contains
`README.project.md`, `LICENSE.project` or `.github-project/`.**
cargo-generate is older than 0.26. Update it
(`cargo install cargo-generate --force`) and generate again.

## Working on the template

### Layout

Most files here are the template: they're copied into new projects with
`{{placeholders}}` and `{% if %}` blocks filled in, so this repository
doesn't build on its own. A few files have a template-only version and a
project version:

| Here | In generated projects | Why |
|---|---|---|
| `README.md` | not copied | This README |
| `README.project.md` | `README.md` | The crate's README |
| `LICENSE` | not copied | The template's license |
| `LICENSE.project` | `LICENSE` | Filled in with the year and owner |
| `.github/` | not copied | Tests and protects the template |
| `.github-project/` | `.github/` | Kept apart so GitHub doesn't run project workflows here |

`post-generate.rhai` does the renames. `cargo-generate.toml` defines the
prompts, which files each "no" answer removes, and which files are copied
without placeholder substitution (the workflows, `justfile`, `just/` and
`release-plz.toml` use `{{ }}` for their own syntax). Because the `justfile`
can't use `{% if %}`, the commands for each optional extra live in their
own file in `just/`, which is removed with the option.

The devcontainer, the `just` commands and the git hook are for generated
projects; they don't work in this repository, whose files still contain
placeholders. To work on the template you need only an editor,
cargo-generate 0.26+ and Docker (see [Testing](#testing)). The
`CONTRIBUTING.md` here is the projects' guide, not a guide to the template:
this section is.

### Proposing a change

Changes reach `main` the same way as in a project: create a branch, open a
pull request whose title follows
[Conventional Commits](https://www.conventionalcommits.org/) (`feat:`,
`fix:`, `docs:`, `ci:`, `build:` ...), and squash or rebase merge it once the
**Template** workflow passes. Keep each commit to one logical change. The
template has no versions or releases: projects are generated from `main`.

### Protecting `main`

`.github/rulesets/main.json` applies the projects' rules to this repository:
pull requests only, squash or rebase merges, and the **Template** workflow's
checks (`workflow audit`, `minimal`, `full`) must pass. Import it once:
*Settings* → *Rules* → *Rulesets* → *New ruleset* → *Import a ruleset*.
Also untick *Allow merge commits* under *Settings* → *General* → *Pull
Requests*. If you rename a job in `template.yml`, update the check names in
the ruleset too.

### Making changes

- **Add a tool:** add it to `.devcontainer/tools.toml` with a
  `# renovate:` comment, use it in a `justfile` command, and add it to the
  Tools table in `CONTRIBUTING.md`.
- **Add a prompt:** add `[placeholders.<name>]` to `cargo-generate.toml`;
  use `{% if <name> %}` in files or a `[conditional.'!<name>']` section to
  remove whole files; put any commands it adds in `just/<name>.just`
  (imported by the `justfile` with `import?`, so it can be removed);
  update the prompt table above; cover it in
  `.github/workflows/template.yml` if it needs testing.
- **Keep versions current:** install [Renovate](https://github.com/apps/renovate)
  on this repository. It updates the actions (including those in
  `.github-project/`), tools, base image and toolchain. It can't parse the
  templated `Cargo.toml`; crate dependencies are updated in each project.
  The cargo-generate version in `template.yml` is left alone on purpose:
  it's the oldest version the template supports (`cargo_generate_version`
  in `cargo-generate.toml`), so raise both together.

### Testing

The **Template** workflow (`.github/workflows/template.yml`) runs on every
change: it audits all workflows, generates a minimal project (no extras)
and a full one (all extras), builds each one's devcontainer, and runs
`just setup` and `just ci` (plus Miri, fuzzing and benchmarks for the full
one). To do the same locally:

```sh
cargo generate --path . --name demo-lib -d description=Demo -d github_owner=you \
  -d contact_email=you@example.com -d uses_unsafe=true -d fuzzing=true -d benchmarks=true
cd demo-lib
docker build -f .devcontainer/Dockerfile -t demo-lib-dev .
docker run --rm -v "$PWD":/work -w /work demo-lib-dev bash -c 'just setup && just ci'
```

`--path .` copies your working copy as it is, including uncommitted and
untracked files.

### Existing projects

A generated project is a copy, not a link: changes to the template never
reach crates generated earlier. Renovate keeps each project's pinned
versions current, but anything else (a new check, a workflow fix, a
documentation change) must be applied by hand. To see what changed,
generate a fresh project with the same name and answers, compare it with
the existing one (e.g. `diff -r --exclude=.git new-project existing-project`),
and copy over the parts you want.
