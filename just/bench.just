# Present only in projects generated with benchmarks.

# Run benchmarks. Extra arguments go to cargo, e.g. `just bench -- --save-baseline main`.
bench *args:
    cargo bench --locked --all-features {{ args }}
