MEMORY {
    BOOT2 : ORIGIN = 0x10000000, LENGTH = 0x100
    /*
     * The Raspberry Pi Pico has 2048 KiB of external flash.
     */
    FLASH : ORIGIN = 0x10000100, LENGTH = 2048K - 0x100
    /*
     * RAM consists of SRAM0-SRAM3 with a striped mapping. This is the normal
     * general-purpose RAM region and distributes accesses across the banks.
     */
    RAM : ORIGIN = 0x20000000, LENGTH = 256K
    /*
     * SRAM4 and SRAM5 use direct mappings and can be reserved for workloads
     * which benefit from predictable, dedicated SRAM banks.
     */
    SRAM4 : ORIGIN = 0x20040000, LENGTH = 4K
    SRAM5 : ORIGIN = 0x20041000, LENGTH = 4K

    /*
     * SRAM0-SRAM3 can also be addressed directly, but those ranges alias the
     * striped RAM mapping above and must not be used at the same time.
     *
     * SRAM0 : ORIGIN = 0x21000000, LENGTH = 64K
     * SRAM1 : ORIGIN = 0x21010000, LENGTH = 64K
     * SRAM2 : ORIGIN = 0x21020000, LENGTH = 64K
     * SRAM3 : ORIGIN = 0x21030000, LENGTH = 64K
     */
}

EXTERN(BOOT2_FIRMWARE)

SECTIONS {
    /*
     * Second-stage boot loader. The RP2040 Boot ROM expects this executable
     * block at the start of external flash so it can configure QSPI/XIP.
     */
    .boot2 ORIGIN(BOOT2) :
    {
        KEEP(*(.boot2));
    } > BOOT2
} INSERT BEFORE .text;

SECTIONS {
    /*
     * Picotool Binary Info header. Keep it immediately after the vector table
     * so that it remains within the first 512 bytes of flash.
     */
    .boot_info : ALIGN(4)
    {
        KEEP(*(.boot_info));

        /*
         * cortex-m-rt uses _stext as the explicit start address of .text.
         * Pad the Binary Info header so .text starts at an 8-byte boundary,
         * which satisfies the strongest alignment required by our Rust code.
         */
        . = ALIGN(8);
    } > FLASH
} INSERT AFTER .vector_table;

/* Move .text to start after the picotool Binary Info header. */
_stext = ADDR(.boot_info) + SIZEOF(.boot_info);

SECTIONS {
    /*
     * Picotool Binary Info entries referenced by the header above.
     */
    .bi_entries : ALIGN(4)
    {
        __bi_entries_start = .;
        KEEP(*(.bi_entries));
        . = ALIGN(4);
        __bi_entries_end = .;
    } > FLASH
} INSERT AFTER .text;

SECTIONS {
    /* Used by rp_binary_info::rp_binary_end!(). */
    .flash_end :
    {
        __flash_binary_end = .;
    } > FLASH
} INSERT AFTER .uninit;
