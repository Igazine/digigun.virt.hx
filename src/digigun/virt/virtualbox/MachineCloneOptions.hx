package digigun.virt.virtualbox;

/**
	Immutable options for machine cloning operations.
**/
final class MachineCloneOptions {
	/**
		Target VM name for the clone.
	**/
	public final targetName:String;

	/**
		Clone mode (Full, Linked, Shallow).
	**/
	public final mode:MachineCloneMode;

	/**
		Whether to clone snapshots along with the machine.
	**/
	public final cloneSnapshots:Bool;

	/**
		Optional: Snapshot UUID to clone from (if cloning a specific snapshot state).
	**/
	public final fromSnapshotUuid:Null<String>;

	/**
		Create new clone options.
		
		@param targetName Name for the cloned VM (must be unique)
		@param mode Clone mode: Full, Linked, or Shallow
		@param cloneSnapshots Whether to include snapshots (default true)
		@param fromSnapshotUuid Optional UUID of snapshot to clone from (default null)
	**/
	public function new(targetName:String, mode:MachineCloneMode, cloneSnapshots:Bool = true, fromSnapshotUuid:Null<String> = null) {
		if (targetName.length == 0) {
			throw new haxe.Exception("Target name cannot be empty");
		}
		this.targetName = targetName;
		this.mode = mode;
		this.cloneSnapshots = cloneSnapshots;
		this.fromSnapshotUuid = fromSnapshotUuid;
	}

	/**
		Get human-readable description of clone options.
	**/
	public function description():String {
		var desc = 'Clone to "$targetName" using ${mode.description()}';
		if (cloneSnapshots) {
			desc += " (with snapshots)";
		}
		if (fromSnapshotUuid != null) {
			desc += ' from snapshot ${fromSnapshotUuid}';
		}
		return desc;
	}

	/**
		Check if options are valid for cloning.
	**/
	public function isValid():Bool {
		return targetName.length > 0 && mode != null;
	}
}
