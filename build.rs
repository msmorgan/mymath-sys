use std::env;
use std::path::PathBuf;

fn main() {
    build_mymath();
}

fn build_mymath() {
    let root_dir = PathBuf::from(env::var_os("CARGO_MANIFEST_DIR").unwrap());

    let dst = cmake::Config::new(root_dir.join("src/mymath"))
        .generator("Ninja")
        .define("PICO_TOOLCHAIN_PATH", "C:/Program Files (x86)/Arm GNU Toolchain arm-none-eabi/13.2 Rel1")
        .define("CMAKE_TOOLCHAIN_FILE", root_dir.join("cmake/toolchain.cmake"))
        .build_target("mymath")
        .build();

    println!("cargo::rustc-link-search={}/build", dst.display());
    println!("cargo::rustc-link-lib=static=mymath");
}