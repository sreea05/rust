//! Fuzz `checked_add` with arbitrary pairs of numbers.
//! Run with `just fuzz`. To reproduce a crash, see "Fuzzing" in CONTRIBUTING.md.
#![no_main]

use libfuzzer_sys::fuzz_target;
use {{crate_name}}::checked_add;

fuzz_target!(|input: (u64, u64)| {
    let (left, right) = input;
    match checked_add(left, right) {
        Some(sum) => assert_eq!(sum - right, left),
        None => assert!(left.checked_add(right).is_none()),
    }
});
