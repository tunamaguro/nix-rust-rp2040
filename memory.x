/*
 * Default RP2040 memory layout.
 *
 * The RP2040 uses external QSPI flash, so FLASH length is board dependent.
 * 2 MiB is a conservative template default; adjust it for the target board.
 */
MEMORY {
    BOOT2 : ORIGIN = 0x10000000, LENGTH = 0x100
    FLASH : ORIGIN = 0x10000100, LENGTH = 2048K - 0x100
    RAM   : ORIGIN = 0x20000000, LENGTH = 256K
}

/* Force the boot2 object out of the library archive. */
EXTERN(BOOT2_FIRMWARE)

SECTIONS {
    .boot2 ORIGIN(BOOT2) :
    {
        KEEP(*(.boot2));
    } > BOOT2
} INSERT BEFORE .text;
