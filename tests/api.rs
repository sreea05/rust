//! Integration tests exercising the public API as an external user would.

use {{crate_name}}::checked_add;

#[test]
fn zero_is_identity() {
    assert_eq!(checked_add(7, 0), Some(7));
}

#[test]
fn max_plus_zero_does_not_overflow() {
    assert_eq!(checked_add(u64::MAX, 0), Some(u64::MAX));
}
