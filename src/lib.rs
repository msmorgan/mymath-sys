#![no_std]

use core::ffi::c_int;

#[link(name = "mymath")]
extern {
    pub fn add(a: c_int, b: c_int) -> c_int;
}
