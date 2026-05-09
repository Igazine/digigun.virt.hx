package digigun.virt.virtualbox;

/**
 * Base exception class for all VirtualBox API errors
 * 
 * All VirtualBox operations throw specialized subclasses of this:
 * - `ConnectionError` - VirtualBox connection issues
 * - `MachineError` - VM/machine not found or operation failed
 * - `SessionError` - Session lock/unlock or control operation failed
 * 
 * **Error Context:**
 * Every error includes operational context to aid debugging:
 * - `operationName` - What operation failed (e.g., "pause", "findMachine")
 * - `paramValue` - Input parameter that caused the error (e.g., "my-vm")
 * - `errorDetails` - Additional error context (e.g., "VM not running")
 * 
 * **Example:**
 * ```haxe
 * try {
 *   vbox.findMachine("non-existent");
 * } catch (e:MachineError) {
 *   trace('Error: ${e.message}');
 *   trace('Operation: ${e.operationName}');
 *   trace('Code: ${e.code}');
 * }
 * ```
 * 
 * **Catching Errors:**
 * Use specific error types to distinguish between different failure modes:
 * ```haxe
 * try {
 *   session.pause();
 * } catch (e:SessionError) {
 *   trace("Session error: " + e.message);
 * } catch (e:VBoxError) {
 *   trace("Other VBox error: " + e.message);
 * }
 * ```
 * 
 * **Backward Compatibility:**
 * The generic `Error` type is aliased to `VBoxError`, so old code still works.
 */
class VBoxError extends haxe.Exception {
    /// Numeric error code from VirtualBox/HRESULT
    public final code:Int;
    
    /// Name of the operation that failed (e.g., "findMachine", "pause")
    public final operationName:String;
    
    /// Input parameter that caused failure (e.g., machine name, VM ID)
    public final paramValue:String;
    
    /// Additional error context or details
    public final errorDetails:String;
    
    /**
     * Creates a new VirtualBox error with context
     * 
     * @param message Main error message
     * @param code Numeric error code (default -1)
     * @param ctx Optional ErrorContext with operation, param, details
     */
    public function new(message:String, code:Int = -1, ?ctx:ErrorContext) {
        var op = ctx?.operation ?? "unknown";
        var p = ctx?.param ?? "";
        var det = ctx?.details ?? "";
        
        // Build comprehensive error message
        var fullMessage = message;
        if (op != "unknown") {
            fullMessage = 'Failed during $op: ${message}';
            if (p != "") {
                fullMessage += ' (param: $p)';
            }
        }
        if (det != "") {
            fullMessage += ' - Details: $det';
        }
        
        super(fullMessage);
        this.code = code;
        this.operationName = op;
        this.paramValue = p;
        this.errorDetails = det;
    }
    
    /// Factory method for creating errors from messages
    public static function fromMessage(message:String, code:Int = -1, ?ctx:ErrorContext):VBoxError {
        return new VBoxError(message, code, ctx);
    }
}
