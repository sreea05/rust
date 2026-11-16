# Present only in projects generated with `unsafe` code allowed.

# Run the tests under Miri to detect undefined behaviour.
miri:
    cargo +{{ nightly }} miri test --all-features
