package digigun.virt.virtualbox;

/// Status of an asynchronous VirtualBox operation
typedef ProgressInfo = {
    var completed:Bool;      /// Whether the operation has finished (success or failure)
    var cancelable:Bool;     /// Whether the operation can be canceled
    var canceled:Bool;       /// Whether the operation was canceled by user
    var percent:Int;         /// Completion percentage (0-100)
    var operationCount:Int;  /// Total number of sub-operations
    var resultCode:Int;      /// Final result code (0 = success, non-zero = error)
    var description:String;  /// Human-readable description of current operation
}

/**
 * Represents progress of a VirtualBox operation
 * 
 * VirtualBox operations like launching VMs can take time. This class provides
 * feedback about operation completion, progress percentage, and final status.
 * 
 * **Operation Progress:**
 * Most operations block until completion and return a final Progress snapshot:
 * ```haxe
 * var progress = vbox.launchVmProcess(machineId, "headless", -1);
 * // Already finished (blocked internally)
 * if (progress.isSuccess()) {
 *   trace('VM launched successfully');
 * } else {
 *   trace('Launch failed: ${progress.resultCode}');
 * }
 * ```
 * 
 * **Result Codes:**
 * - `0` - Success (operation completed without errors)
 * - `Non-zero` - Error code (see HRESULT or VirtualBox error codes)
 * 
 * **Real-time Progress:**
 * For long-running operations, you could poll progress in a loop,
 * but the current API blocks internally so this is rarely needed.
 * 
 * All fields are read-only snapshots from the point of query.
 */
class Progress {
    /// Whether the operation has finished
    public final completed:Bool;
    
    /// Whether this operation can be canceled
    public final cancelable:Bool;
    
    /// Whether this operation was canceled by user
    public final canceled:Bool;
    
    /// Completion percentage (0-100)
    public final percent:Int;
    
    /// Total number of sub-operations (e.g., multiple VMs launching)
    public final operationCount:Int;
    
    /// Final result code (0 = success, non-zero = error)
    public final resultCode:Int;
    
    /// Current operation description
    public final description:String;

    public function new(info:ProgressInfo) {
        this.completed = info.completed;
        this.cancelable = info.cancelable;
        this.canceled = info.canceled;
        this.percent = info.percent;
        this.operationCount = info.operationCount;
        this.resultCode = info.resultCode;
        this.description = info.description;
    }

    /// Check if operation succeeded (completed without errors)
    public function isSuccess():Bool {
        return completed && resultCode == 0;
    }

    /// Check if operation failed (completed with error code)
    public function isFailed():Bool {
        return completed && resultCode != 0;
    }
}
