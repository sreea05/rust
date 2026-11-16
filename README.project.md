# {{project-name}}

[![CI](https://github.com/{{github_owner}}/{{project-name}}/actions/workflows/ci.yml/badge.svg)](https://github.com/{{github_owner}}/{{project-name}}/actions/workflows/ci.yml)
[![crates.io](https://img.shields.io/crates/v/{{project-name}}.svg)](https://crates.io/crates/{{project-name}})
[![docs.rs](https://img.shields.io/docsrs/{{project-name}})](https://docs.rs/{{project-name}})
[![MSRV](https://img.shields.io/crates/msrv/{{project-name}})](Cargo.toml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

{{description}}

## Installation

```sh
cargo add {{project-name}}
```

## Usage

```rust
use {{crate_name}}::checked_add;

assert_eq!(checked_add(2, 3), Some(5));
assert_eq!(checked_add(u64::MAX, 1), None);
```

See the [API documentation](https://docs.rs/{{project-name}}) for details.

## Minimum supported Rust version

The MSRV is set by `rust-version` in [Cargo.toml](Cargo.toml) and checked in CI.
It supports roughly the last six months of stable Rust releases. Raising it
is not a breaking change: it happens in a minor release (a patch release
before 1.0) and is noted in the [changelog](CHANGELOG.md).

## Development

How the project is built, tested and released: [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Licensed under the [MIT license](LICENSE).
