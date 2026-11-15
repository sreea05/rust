//! Criterion benchmarks. Run with `just bench`.
#![allow(missing_docs, reason = "criterion macros generate undocumented items")]

use std::hint::black_box;

use criterion::{Criterion, criterion_group, criterion_main};
use {{crate_name}}::checked_add;

fn bench_checked_add(c: &mut Criterion) {
    c.bench_function("checked_add", |b| {
        b.iter(|| checked_add(black_box(40), black_box(2)));
    });
}

criterion_group!(benches, bench_checked_add);
criterion_main!(benches);
