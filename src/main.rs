#![no_std]
#![no_main]

use defmt_rtt as _;
use panic_probe as _;

#[rp2040_hal::entry]
fn main() -> ! {
    nix_rust_rp2040::run()
}
