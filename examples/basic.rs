//! Minimal usage example. Run with `cargo run --example basic`.

#![allow(clippy::print_stdout, reason = "examples print their output")]

fn main() {
    match {{crate_name}}::checked_add(40, 2) {
        Some(sum) => println!("40 + 2 = {sum}"),
        None => println!("overflow"),
    }
}
