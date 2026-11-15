//! Minimal usage example. Run with `cargo run --example basic`.

fn main() {
    match {{crate_name}}::checked_add(40, 2) {
        Some(sum) => println!("40 + 2 = {sum}"),
        None => println!("overflow"),
    }
}
