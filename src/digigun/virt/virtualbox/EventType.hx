package digigun.virt.virtualbox;

/**
	EventType defines all VirtualBox event types that can be monitored.
	Used for event subscription and filtering.
**/
@:enum
abstract EventType(String) {
	// VM Lifecycle Events
	var VM_STARTED = "OnVMStarted";
	var VM_STOPPED = "OnVMStopped";
	var VM_PAUSED = "OnVMPaused";
	var VM_RESUMED = "OnVMResumed";
	var VM_SAVED = "OnVMSaved";
	var VM_RESTORED = "OnVMRestored";

	// Machine Management Events
	var MACHINE_REGISTERED = "OnMachineRegistered";
	var MACHINE_UNREGISTERED = "OnMachineUnregistered";

	// Media Events
	var MEDIA_ATTACHED = "OnMediaAttached";
	var MEDIA_DETACHED = "OnMediaDetached";

	// Snapshot Events
	var SNAPSHOT_TAKEN = "OnSnapshotTaken";
	var SNAPSHOT_DELETED = "OnSnapshotDeleted";
	var SNAPSHOT_RESTORED = "OnSnapshotRestored";
	var SNAPSHOT_CHANGED = "OnSnapshotChanged";

	// Host Events
	var HOST_SHUTDOWN = "OnHostShutdown";
	var HOST_SLEEP = "OnHostSleep";
	var HOST_RESUME = "OnHostResume";

	// Network Events
	var NETWORK_ADAPTER_CHANGED = "OnNetworkAdapterChanged";
	var VNIC_CHANGED = "OnVNICChanged";

	// Other Events
	var CPU_HOTPLUG = "OnCPUHotplug";
	var MEMORY_HOTPLUG = "OnMemoryHotplug";
	var QUERY_SHUTDOWN = "OnQueryShutdown";
	var ERROR = "OnError";

	/**
		Get human-readable description for event type.
	**/
	public function description():String {
		return switch (this) {
			case "OnVMStarted": "Virtual machine started";
			case "OnVMStopped": "Virtual machine stopped";
			case "OnVMPaused": "Virtual machine paused";
			case "OnVMResumed": "Virtual machine resumed";
			case "OnVMSaved": "Virtual machine saved";
			case "OnVMRestored": "Virtual machine restored";
			case "OnMachineRegistered": "Machine registered with VirtualBox";
			case "OnMachineUnregistered": "Machine unregistered from VirtualBox";
			case "OnMediaAttached": "Storage media attached";
			case "OnMediaDetached": "Storage media detached";
			case "OnSnapshotTaken": "VM snapshot taken";
			case "OnSnapshotDeleted": "VM snapshot deleted";
			case "OnSnapshotRestored": "VM snapshot restored";
			case "OnSnapshotChanged": "VM snapshot changed";
			case "OnHostShutdown": "Host system shutting down";
			case "OnHostSleep": "Host system entering sleep";
			case "OnHostResume": "Host system resuming from sleep";
			case "OnNetworkAdapterChanged": "Network adapter configuration changed";
			case "OnVNICChanged": "Virtual network interface changed";
			case "OnCPUHotplug": "CPU hotplug event";
			case "OnMemoryHotplug": "Memory hotplug event";
			case "OnQueryShutdown": "Query for shutdown";
			case "OnError": "Error event";
			default: "Unknown event";
		};
	}

	/**
		Get event category for grouping.
	**/
	public function category():String {
		return switch (this) {
			case "OnVMStarted" | "OnVMStopped" | "OnVMPaused" | "OnVMResumed" | "OnVMSaved" | "OnVMRestored":
				"VM Lifecycle";
			case "OnMachineRegistered" | "OnMachineUnregistered":
				"Machine Management";
			case "OnMediaAttached" | "OnMediaDetached":
				"Media";
			case "OnSnapshotTaken" | "OnSnapshotDeleted" | "OnSnapshotRestored" | "OnSnapshotChanged":
				"Snapshots";
			case "OnHostShutdown" | "OnHostSleep" | "OnHostResume":
				"Host";
			case "OnNetworkAdapterChanged" | "OnVNICChanged":
				"Network";
			case "OnCPUHotplug" | "OnMemoryHotplug":
				"Hardware";
			default: "Other";
		};
	}

	/**
		Indicates if this is a critical event that should be logged.
	**/
	public function isCritical():Bool {
		return switch (this) {
			case "OnVMStopped" | "OnHostShutdown" | "OnError" | "OnQueryShutdown":
				true;
			default: false;
		};
	}

	@:to public function toString():String {
		return this;
	}
}
