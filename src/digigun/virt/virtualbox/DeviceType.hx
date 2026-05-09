package digigun.virt.virtualbox;

/**
 * VirtualBox storage device types and boot device positions
 * 
 * Used for configuring boot order and storage controllers.
 * Boot positions 0-3 determine the order the VM attempts to boot from devices.
 * 
 * **Example:**
 * ```haxe
 * // Set boot order: HDD first, then CDROM
 * session.setBootOrder(DeviceType.HDD, 1);       // position 1 (primary)
 * session.setBootOrder(DeviceType.CDROM, 2);     // position 2 (secondary)
 * ```
 */
enum abstract DeviceType(Int) from Int to Int {
    /**
     * No device (disables boot position)
     */
    final None = 0;

    /**
     * Floppy drive (rarely used, legacy)
     */
    final Floppy = 1;

    /**
     * CD-ROM / DVD drive
     */
    final CDROM = 2;

    /**
     * Hard disk drive (HDD or SSD)
     */
    final HDD = 3;

    /**
     * Network boot (PXE)
     */
    final Network = 4;
}
