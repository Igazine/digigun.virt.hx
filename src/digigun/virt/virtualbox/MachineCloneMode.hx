package digigun.virt.virtualbox;

/**
	Enumeration of machine cloning modes.
**/
@:enum abstract MachineCloneMode(String) {
	/**
		Full clone: Complete copy of all VM data and snapshots.
		Largest size, slowest to create, but fully independent VM.
	**/
	var Full = "Full";

	/**
		Linked clone: Clone with snapshots linked to parent VM.
		Smaller size, faster to create, but depends on parent VM snapshots.
	**/
	var Linked = "Linked";

	/**
		Shallow clone: Minimal clone with shared virtual disks.
		Smallest size, fastest to create, minimal independence from parent.
	**/
	var Shallow = "Shallow";

	/**
		Get human-readable description of clone mode.
	**/
	public function description():String {
		var modeStr = Std.string(this);
		return switch (modeStr) {
			case "Full": "Full clone - complete independent copy";
			case "Linked": "Linked clone - shares parent snapshots";
			case "Shallow": "Shallow clone - shares virtual disks";
			case _: "Unknown clone mode";
		};
	}
}
