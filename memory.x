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

/*
 * Picotool binary-info header. rp-binary-info expects this to live near the
 * vector table so Picotool can discover it in the first part of flash.
 */
SECTIONS {
    .boot_info : ALIGN(4)
    {
        KEEP(*(.boot_info));
    } > FLASH
} INSERT AFTER .vector_table;

/* Start normal code after the binary-info header. */
_stext = ADDR(.boot_info) + SIZEOF(.boot_info);

SECTIONS {
    .bi_entries : ALIGN(4)
    {
        __bi_entries_start = .;
        KEEP(*(.bi_entries));
        . = ALIGN(4);
        __bi_entries_end = .;
    } > FLASH
} INSERT AFTER .text;

/* Available to rp_binary_info::rp_binary_end! when metadata entries use it. */
SECTIONS {
    .flash_end :
    {
        __flash_binary_end = .;
    } > FLASH
} INSERT AFTER .uninit;
