# Present only in projects generated with fuzzing.
# `--target` is the compiler's host: cargo-fuzz otherwise defaults to the
# platform it was built for, which is musl for the prebuilt binary.

# Run each fuzz target for the given number of seconds.
fuzz seconds="60":
    host=$(rustc -vV | sed -n 's/^host: //p'); \
    for target in $(cargo +{{ nightly }} fuzz list); do \
        cargo +{{ nightly }} fuzz run --target "$host" "$target" -- -max_total_time={{ seconds }}; \
    done
