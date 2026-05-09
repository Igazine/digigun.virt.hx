package digigun.virt.virtualbox;

/// Complete metadata about a registered VirtualBox machine
typedef MachineInfo = {
    var id:String;                /// UUID/identifier of the machine
    var name:String;              /// Display name (user-friendly)
    var state:MachineState;       /// Current state (PoweredOff, Running, Paused, etc.)
    var accessible:Bool;          /// True if VirtualBox can access the machine config
    var description:String;       /// User-provided description
    var settingsFilePath:String;  /// Path to the machine's VirtualBox XML config file
    var memorySize:Int;           /// Allocated RAM in MB
    var osTypeId:String;          /// OS type identifier (e.g., "Ubuntu_64")
    var osDescription:String;     /// Human-readable OS description
}

/**
 * Represents a registered VirtualBox virtual machine
 * 
 * Contains immutable metadata about a VM. Use this to:
 * - Check current state (PoweredOff, Running, Paused, etc.)
 * - Inspect machine properties (memory, OS, description)
 * - Pass to control methods (pause, resume, powerDown, etc.)
 * 
 * **Obtaining Machine objects:**
 * ```haxe
 * var machines = vbox.listMachines();        // All machines
 * var machine = vbox.findMachine("my-vm");   // Specific machine by name
 * var machine = session.getMachine();        // Current locked machine
 * ```
 * 
 * **State Lifecycle:**
 * - `PoweredOff` - Machine is off (initial state)
 * - `Starting` → `Running` - Machine booting or running
 * - `Paused` - Temporarily halted (can resume)
 * - `Stopping` → `PoweredOff` - Machine shutting down
 * 
 * All fields are read-only (immutable). To modify machine settings,
 * use future Phase 2 APIs (machine creation/modification).
 */
class Machine {
    /// Unique machine identifier (UUID)
    public final id:String;
    
    /// Machine display name (what you see in VirtualBox UI)
    public final name:String;
    
    /// Current execution state
    public final state:MachineState;
    
    /// True if machine config is accessible and valid
    public final accessible:Bool;
    
    /// User-provided machine description
    public final description:String;
    
    /// Full path to the machine's settings XML file
    public final settingsFilePath:String;
    
    /// Allocated main memory in megabytes
    public final memorySize:Int;
    
    /// VirtualBox OS type identifier
    public final osTypeId:String;
    
    /// Human-readable OS description
    public final osDescription:String;

    public function new(info:MachineInfo) {
        this.id = info.id;
        this.name = info.name;
        this.state = info.state;
        this.accessible = info.accessible;
        this.description = info.description;
        this.settingsFilePath = info.settingsFilePath;
        this.memorySize = info.memorySize;
        this.osTypeId = info.osTypeId;
        this.osDescription = info.osDescription;
    }
}
