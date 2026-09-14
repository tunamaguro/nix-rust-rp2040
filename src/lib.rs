#![cfg_attr(target_os = "none", no_std)]

use embedded_hal::{delay::DelayNs, digital::OutputPin};
use rp2040_hal as hal;

use hal::{binary_info, pac};

/// External high-speed crystal on the Raspberry Pi Pico is 12 MHz.
const XTAL_FREQ_HZ: u32 = 12_000_000;

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

/// Firmware application body for a Raspberry Pi Pico.
///
/// GPIO25 drives the on-board LED. Each one-second cycle emits `hello world`
/// through defmt, keeps the LED on for 500 ms, then off for 500 ms.
pub fn run() -> ! {
    let mut pac = pac::Peripherals::take().unwrap();
    let mut watchdog = hal::Watchdog::new(pac.WATCHDOG);

    let clocks = hal::clocks::init_clocks_and_plls(
        XTAL_FREQ_HZ,
        pac.XOSC,
        pac.CLOCKS,
        pac.PLL_SYS,
        pac.PLL_USB,
        &mut pac.RESETS,
        &mut watchdog,
    )
    .unwrap();

    let mut timer = hal::Timer::new(pac.TIMER, &mut pac.RESETS, &clocks);
    let sio = hal::Sio::new(pac.SIO);
    let pins = hal::gpio::Pins::new(
        pac.IO_BANK0,
        pac.PADS_BANK0,
        sio.gpio_bank0,
        &mut pac.RESETS,
    );
    let mut led = pins.gpio25.into_push_pull_output();

    loop {
        defmt::info!("hello world");
        led.set_high().unwrap();
        timer.delay_ms(500);
        led.set_low().unwrap();
        timer.delay_ms(500);
    }
}
