#![cfg_attr(target_os = "none", no_std)]

use embedded_hal::{delay::DelayNs, digital::OutputPin};
use rp2040_hal as hal;

use hal::pac;

/// External high-speed crystal on the Raspberry Pi Pico is 12 MHz.
const XTAL_FREQ_HZ: u32 = 12_000_000;

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

#[cfg(test)]
mod tests {
    #[test]
    fn add() {
        assert_eq!(1 + 1, 2);
    }
}
