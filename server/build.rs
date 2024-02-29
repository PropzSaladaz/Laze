extern crate cc;

fn main() {
    cc::Build::new()
        .file("src/virtual-mouse.c")
        .compile("virtual-mouse")
}