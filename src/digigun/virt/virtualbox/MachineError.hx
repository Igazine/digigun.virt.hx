package digigun.virt.virtualbox;

/**
 * Thrown when machine/VM operations fail
 * 
 * Machine errors occur when:
 * - Machine not found by name or UUID (findMachine)
 * - VM launch fails (launchVmProcess)
 * - Machine state invalid for operation
 * - Machine inaccessible or corrupted
 * 
 * Typical resolution:
 * - Check machine exists: `vbox.listMachines()` to see available VMs
 * - Verify machine name/UUID spelling
 * - Check machine is accessible (not corrupted config)
 * 
 * **Example:**
 * ```haxe
 * try {
 *   var machine = vbox.findMachine("wrong-name");
 * } catch (e:MachineError) {
 *   trace('Machine error: ${e.message}');
 *   trace('Operation: ${e.operationName}');
 * }
 * ```
 */
class MachineError extends VBoxError {
    public function new(message:String, code:Int = -1, ?ctx:ErrorContext) {
        super(message, code, ctx);
    }
}
