package digigun.virt.virtualbox;

/**
 * Thrown when VirtualBox connection operations fail
 * 
 * Connection errors occur when:
 * - VirtualBox is not installed or not accessible
 * - IVirtualBox interface initialization fails
 * - Version query fails
 * 
 * This is typically the first error you'd see if VirtualBox setup is wrong.
 * 
 * **Example:**
 * ```haxe
 * try {
 *   var vbox = VirtualBox.open();
 * } catch (e:ConnectionError) {
 *   trace("Cannot connect to VirtualBox: " + e.message);
 * }
 * ```
 */
class ConnectionError extends VBoxError {
    public function new(message:String, code:Int = -1, ?ctx:ErrorContext) {
        super(message, code, ctx);
    }
}
