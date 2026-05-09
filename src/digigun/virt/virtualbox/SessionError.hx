package digigun.virt.virtualbox;

/**
 * Thrown when session operations fail
 * 
 * Session errors occur when:
 * - Machine lock fails (already locked by another process)
 * - Session unlock fails
 * - VM control operations fail (pause, resume, powerDown, etc.)
 * - Session becomes inactive unexpectedly
 * - Boot timeout in waitUntilRunning()
 * 
 * Common causes and solutions:
 * 1. **Already locked** - Another VirtualBox process has the VM locked
 *    - Solution: Close other VirtualBox windows or wait for lock to release
 * 
 * 2. **VM not running** - Operation requires running VM
 *    - Solution: Launch VM first with launchVmProcess()
 * 
 * 3. **Boot timeout** - waitUntilRunning() exceeded time limit
 *    - Solution: Increase timeout or check if VM has sufficient resources
 * 
 * **Example:**
 * ```haxe
 * try {
 *   var session = vbox.lockMachine(machineId);
 *   session.pause();
 * } catch (e:SessionError) {
 *   trace('Session error: ${e.message}');
 * } finally {
 *   if (session != null) session.unlock();
 * }
 * ```
 */
class SessionError extends VBoxError {
    public function new(message:String, code:Int = -1, ?ctx:ErrorContext) {
        super(message, code, ctx);
    }
}
