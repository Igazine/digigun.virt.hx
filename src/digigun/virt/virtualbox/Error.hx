package digigun.virt.virtualbox;

import cpp.Pointer;

// Backward compatibility alias
typedef Error = VBoxError;

/**
 * Helper function to create errors with message and code.
 * Deprecated: Use ConnectionError, MachineError, or SessionError instead
 */
function createError(message:String, code:Int = -1):VBoxError {
    return VBoxError.fromMessage(message, code);
}
