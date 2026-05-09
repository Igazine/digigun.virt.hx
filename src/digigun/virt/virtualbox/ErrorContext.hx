package digigun.virt.virtualbox;

/**
 * Provides context information for errors to help with debugging and logging.
 * This allows errors to carry additional context about what operation failed
 * and what parameters were involved.
 */
typedef ErrorContext = {
    /** The operation that failed (e.g., "launchVmProcess", "pause", "lock") */
    ?operation:String,
    
    /** Parameter information if relevant (e.g., VM name, machine ID) */
    ?param:String,
    
    /** Original/underlying error details */
    ?details:String
}

