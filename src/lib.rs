#![no_std]

/// Generic second-stage bootloader used by the template.
///
/// `BOOT_LOADER_GENERIC_03H` favors compatibility over board-specific flash
/// tuning. Projects targeting a known flash device should replace this with the
/// matching `rp2040-boot2` image.
#[unsafe(link_section = ".boot2")]
#[unsafe(export_name = "BOOT2_FIRMWARE")]
#[used]
pub static BOOT2: [u8; 256] = rp2040_boot2::BOOT_LOADER_GENERIC_03H;

/// Firmware application body.
///
/// Keep the binary entry point in `main.rs` minimal and put application logic
/// here (or in modules below this crate) so it stays testable and reusable.
pub fn run() -> ! {
    defmt::info!("nix-rust-rp2040 started");

    loop {
        cortex_m::asm::wfi();
    }
}
