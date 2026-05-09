package digigun.virt.virtualbox;

/// Complete metadata about a VirtualBox machine snapshot
typedef SnapshotInfo = {
    var id:String;                /// UUID/identifier of the snapshot
    var name:String;              /// Snapshot display name
    var description:String;       /// User-provided description (may be empty)
    var timestamp:Int;            /// Creation time (Unix timestamp in seconds)
    var isCurrentSnapshot:Bool;   /// True if this is the currently-active snapshot
    var parentId:String;          /// Parent snapshot ID, or empty if root
}

/**
 * Represents a VirtualBox machine snapshot
 * 
 * A snapshot captures the complete state of a machine at a point in time,
 * including disk state, memory (if saved), and configuration. Snapshots enable:
 * - Testing/experimentation with rollback capability
 * - Creating branching execution paths (nested snapshots)
 * - Quick state restoration without re-provisioning
 * 
 * **Obtaining Snapshot objects:**
 * ```haxe
 * var snapshots = session.listSnapshots();        // All snapshots for machine
 * var snapshot = session.findSnapshot("snapshot-id");  // Find by ID or name
 * ```
 * 
 * **Snapshot Lifecycle:**
 * - Create snapshot when VM is running or powered off
 * - Restore snapshot to return VM to captured state
 * - Delete snapshot to free disk space (child snapshots typically preserved)
 * - Current snapshot indicated by `isCurrentSnapshot` flag
 * 
 * All fields are read-only. To modify snapshots, use Session API:
 * - session.createSnapshot(name, description?)
 * - session.restoreSnapshot(snapshotId)
 * - session.deleteSnapshot(snapshotId)
 */
class Snapshot {
    /// Unique snapshot identifier (UUID)
    public final id:String;
    
    /// Snapshot display name (user-provided)
    public final name:String;
    
    /// Optional description (empty string if not set)
    public final description:String;
    
    /// Snapshot creation time (Unix timestamp seconds)
    public final timestamp:Int;
    
    /// True if this is the currently active snapshot
    public final isCurrentSnapshot:Bool;
    
    /// ID of parent snapshot, or empty if this is root
    public final parentId:String;

    public function new(info:SnapshotInfo) {
        this.id = info.id;
        this.name = info.name;
        this.description = info.description;
        this.timestamp = info.timestamp;
        this.isCurrentSnapshot = info.isCurrentSnapshot;
        this.parentId = info.parentId;
    }
}
