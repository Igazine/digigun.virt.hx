package digigun.virt.virtualbox;

/**
 * VirtualBox VM launch frontend modes
 * 
 * Specifies the UI frontend to use when launching a virtual machine.
 * Each mode determines how the VM interacts with the host display.
 * 
 * **Available Modes:**
 * - `Headless` - No GUI; VM runs in background (recommended for servers)
 * - `GUI` - VirtualBox GUI window (typical interactive use)
 * - `SDL` - SDL frontend (older, rarely used)
 * - `VRDP` - Remote Desktop Protocol server (for remote access)
 * - `Separate` - Separate process (runs detached)
 * 
 * **Example:**
 * ```haxe
 * var progress = vbox.launchVmProcess(machineId, LaunchMode.Headless);
 * ```
 */
enum abstract LaunchMode(String) from String to String {
    final Headless = "headless";
    final GUI = "gui";
    final SDL = "sdl";
    final VRDP = "vrdp";
    final Separate = "separate";
}
