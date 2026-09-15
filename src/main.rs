#![no_std]
#![no_main]

use defmt_rtt as _;
use panic_probe as _;
use rp2040_hal::binary_info;

/// Generic second-stage bootloader used by the template.
///
/// `BOOT_LOADER_GENERIC_03H` favors compatibility over flash-specific tuning.
#[unsafe(link_section = ".boot2")]
#[unsafe(export_name = "BOOT2_FIRMWARE")]
#[used]
pub static BOOT2: [u8; 256] = rp2040_boot2::BOOT_LOADER_GENERIC_03H;

/// Picotool-compatible Binary Info entries for the Raspberry Pi Pico example.
///
/// Keep this metadata out of host-side unit-test binaries; the linker symbols
/// referenced here are provided by `memory.x` for the bare-metal firmware.
#[cfg(target_os = "none")]
#[unsafe(link_section = ".bi_entries")]
#[used]
pub static PICOTOOL_ENTRIES: [binary_info::EntryAddr; 7] = [
    binary_info::rp_program_name!(c"nix-rust-rp2040"),
    binary_info::rp_cargo_version!(),
    binary_info::rp_program_description!(
        c"RP2040 Nix/Rust template: defmt + Pico GPIO25 LED blinky"
    ),
    binary_info::rp_program_url!(c"https://github.com/tunamaguro/nix-rust-rp2040"),
    binary_info::rp_program_build_attribute!(),
    binary_info::rp_pico_board!(c"pico"),
    binary_info::rp_binary_end!(__flash_binary_end),
];

#[cfg(target_os = "none")]
unsafe extern "C" {
    static __flash_binary_end: u32;
}

#[rp2040_hal::entry]
fn main() -> ! {
    nix_rust_rp2040::run()
}
