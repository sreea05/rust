//! {{description}}
//!
//! # Example
//!
//! ```
//! use {{crate_name}}::checked_add;
//!
//! assert_eq!(checked_add(2, 3), Some(5));
//! assert_eq!(checked_add(u64::MAX, 1), None);
//! ```
#![cfg_attr(docsrs, feature(doc_cfg))]

/// Adds two numbers, returning `None` if the result would overflow.
///
/// # Examples
///
/// ```
/// assert_eq!({{crate_name}}::checked_add(40, 2), Some(42));
/// ```
#[must_use]
pub const fn checked_add(left: u64, right: u64) -> Option<u64> {
    left.checked_add(right)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn adds_small_numbers() {
        assert_eq!(checked_add(2, 2), Some(4));
    }

    #[test]
    fn reports_overflow() {
        assert_eq!(checked_add(u64::MAX, 1), None);
    }
}
