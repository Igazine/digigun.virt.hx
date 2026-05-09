package digigun.virt.virtualbox;

#if cpp
import digigun.virt.virtualbox.raw.Native;
import digigun.virt.virtualbox.raw.Types;
#end

/**
 * Represents an active VirtualBox session for a locked machine.
 * A session provides control operations on a running VM:
 * - pause() / resume() - Temporary execution control
 * - reset() - Hard reboot
 * - powerButton() / powerDown() - Shutdown operations
 * 
 * Sessions must be unlocked when done to release VirtualBox resources.
 */
class Session {
    private final owner:VirtualBox;
    private var active:Bool = true;

    public function new(owner:VirtualBox) {
        this.owner = owner;
    }

    /**
     * Get the current state of this session
     */
    public var state(get, never):SessionState;

    private function get_state():SessionState {
        return owner.getSessionState();
    }

    /**
     * Get machine information for the locked machine
     */
    public function getMachine():Machine {
        ensureActive();
        return owner.getSessionMachine();
    }

    /**
     * Pause the VM (requires running state)
     */
    public function pause():Void {
        ensureActive();
        owner.sessionPause();
    }

    /**
     * Resume the VM from paused state
     */
    public function resume():Void {
        ensureActive();
        owner.sessionResume();
    }

    /**
     * Hard reset the VM (reboot)
     */
    public function reset():Void {
        ensureActive();
        owner.sessionReset();
    }

    /**
     * Send power button request (graceful shutdown request to OS)
     */
    public function powerButton():Void {
        ensureActive();
        owner.sessionPowerButton();
    }

    /**
     * Force power down after timeout (or immediately if timeout is 0)
     * @param timeoutMs milliseconds to wait for graceful shutdown before forced power off (-1 = use VM default)
     */
    public function powerDown(?timeoutMs:Int = -1):Void {
        ensureActive();
        owner.sessionPowerDown(timeoutMs);
    }

    /**
     * Unlock this session and release the lock on the machine
     * Safe to call multiple times - subsequent calls do nothing
     */
    public function unlock():Void {
        if (!active) {
            return;
        }
        try {
            owner.unlockSession();
        } catch (e:VBoxError) {
            // Log but don't re-throw; best-effort cleanup
            #if debug
            trace('Warning: Error during unlock: ${e.message}');
            #end
        }
        active = false;
    }

    /**
     * Set machine memory size (RAM in MB)
     * 
     * Modifies the amount of RAM allocated to this machine.
     * Changes take effect after saveSettings() and require a reboot.
     * 
     * @param memoryMB Memory size in megabytes (4-2097152 MB)
     * @throws SessionError If session not locked with Write permission or value is invalid
     * 
     * **Example:**
     * ```haxe
     * var session = vbox.lockMachine("MyVM", LockType.Write);
     * session.setMemorySize(2048);  // 2 GB
     * session.saveSettings();
     * session.unlock();
     * ```
     */
    public function setMemorySize(memoryMB:Int):Void {
        ensureActive();
        #if cpp
        var code = owner.sessionSetMemorySize(memoryMB);
        if (code != 0) {
            throw new SessionError('Failed to set memory size to ${memoryMB}MB', code, 
                {operation: "setMemorySize", param: '${memoryMB}MB'});
        }
        #else
        throw new SessionError("setMemorySize not supported on non-cpp target", -1, 
            {operation: "setMemorySize", param: '${memoryMB}MB'});
        #end
    }

    /**
     * Set machine CPU count (vCPUs)
     * 
     * Modifies the number of virtual CPUs allocated to this machine.
     * Changes take effect after saveSettings() and require a reboot.
     * 
     * @param cpuCount Number of CPUs (1-512, typically 1-32)
     * @throws SessionError If session not locked with Write permission or value is invalid
     * 
     * **Example:**
     * ```haxe
     * var session = vbox.lockMachine("MyVM", LockType.Write);
     * session.setVCpuCount(4);      // 4 CPUs
     * session.saveSettings();
     * session.unlock();
     * ```
     */
    public function setVCpuCount(cpuCount:Int):Void {
        ensureActive();
        #if cpp
        var code = owner.sessionSetVCpuCount(cpuCount);
        if (code != 0) {
            throw new SessionError('Failed to set CPU count to ${cpuCount}', code, 
                {operation: "setVCpuCount", param: '${cpuCount} CPUs'});
        }
        #else
        throw new SessionError("setVCpuCount not supported on non-cpp target", -1, 
            {operation: "setVCpuCount", param: '${cpuCount} CPUs'});
        #end
    }

    /**
     * Set boot device order
     * 
     * Configures the boot device and its priority.
     * Boot positions 1-4 determine boot attempt order.
     * Set device to DeviceType.None to disable a position.
     * 
     * @param device DeviceType enum value (None, Floppy, CDROM, HDD, Network)
     * @param position Boot order position (1-4, where 1 is first)
     * @throws SessionError If session not locked with Write permission or position invalid
     * 
     * **Example:**
     * ```haxe
     * var session = vbox.lockMachine("MyVM", LockType.Write);
     * session.setBootOrder(DeviceType.HDD, 1);     // HDD first
     * session.setBootOrder(DeviceType.CDROM, 2);   // CDROM second
     * session.saveSettings();
     * session.unlock();
     * ```
     */
    public function setBootOrder(device:DeviceType, position:Int):Void {
        ensureActive();
        #if cpp
        var code = owner.sessionSetBootOrder(device, position);
        if (code != 0) {
            throw new SessionError('Failed to set boot order position ${position}', code, 
                {operation: "setBootOrder", param: 'device=${device}, position=${position}'});
        }
        #else
        throw new SessionError("setBootOrder not supported on non-cpp target", -1, 
            {operation: "setBootOrder", param: 'device=${device}, position=${position}'});
        #end
    }

    /**
     * Save machine settings to disk
     * 
     * Persists all configuration changes (memory, CPU, boot order, etc.) to storage.
     * Must be called after making modifications and before unlocking.
     * 
     * @throws SessionError If session not locked or save fails
     * 
     * **Example:**
     * ```haxe
     * var session = vbox.lockMachine("MyVM", LockType.Write);
     * session.setMemorySize(2048);
     * session.setVCpuCount(2);
     * session.saveSettings();   // Persist changes
     * session.unlock();
     * ```
     */
    public function saveSettings():Void {
        ensureActive();
        #if cpp
        var code = owner.sessionSaveSettings();
        if (code != 0) {
            throw new SessionError('Failed to save machine settings', code, 
                {operation: "saveSettings"});
        }
        #else
        throw new SessionError("saveSettings not supported on non-cpp target", -1, 
            {operation: "saveSettings"});
        #end
    }

    /**
     * Verify that this session is still active before executing operations
     * Throws SessionError if session has been unlocked
     */
    private function ensureActive():Void {
        if (!active) {
            throw new SessionError("VirtualBox session is not active - was already unlocked", -1, 
                {operation: "session_operation", details: "Attempted to use closed session"});
        }
    }

    /**
     * Polls until VM transitions to Running state (indicates successful boot/startup)
     * Replaces arbitrary Sys.sleep() waits with proper event-driven polling.
     * 
     * Useful after launchVmProcess() to wait for the guest OS to actually boot:
     * ```haxe
     * var progress = vbox.launchVmProcess(machineId, "headless", -1);
     * session.waitUntilRunning(); // No more Sys.sleep(8) needed!
     * session.pause(); // Now safe to interact with VM
     * ```
     * 
     * @param maxWaitMs Maximum time to wait for VM to reach Running state (default 30 seconds)
     * @param pollIntervalMs Polling interval between state checks (default 500ms)
     * @return Final machine info when Running state is detected
     * @throws SessionError If session becomes inactive or maxWaitMs exceeded
     */
    public function waitUntilRunning(maxWaitMs:Int = 30000, pollIntervalMs:Int = 500):Machine {
        ensureActive();
        var elapsed = 0;
        while (elapsed < maxWaitMs) {
            var info = getMachine();
            if (info.state == MachineState.Running) {
                return info;
            }
            if (elapsed + pollIntervalMs <= maxWaitMs) {
                Sys.sleep(pollIntervalMs / 1000.0);
                elapsed += pollIntervalMs;
            } else {
                elapsed = maxWaitMs; // Force exit on last iteration
            }
        }
        throw new SessionError('VM did not reach Running state within ${maxWaitMs}ms', -1, {
            operation: "waitUntilRunning",
            param: '${maxWaitMs}ms',
            details: "Boot timeout exceeded"
        });
    }

    /**
     * Create a snapshot of the current machine state
     * 
     * Snapshots capture the complete VM state at a point in time, enabling
     * rollback to that state later. Can be created on running or stopped VMs.
     * 
     * @param name Snapshot name (required, must not be empty)
     * @param description Optional snapshot description for documentation
     * @return Created snapshot information
     * @throws SessionError If snapshot creation fails
     * 
     * **Example:**
     * ```haxe
     * var session = vbox.lockMachine("MyVM", LockType.Write);
     * var snapshot = session.createSnapshot("Before Update", "Baseline before software installation");
     * // Try an operation...
     * // If something goes wrong, restore the snapshot
     * session.unlock();
     * ```
     */
    public function createSnapshot(name:String, ?description:String):Snapshot {
        ensureActive();
        #if cpp
        var desc = description != null ? description : "";
        var info:Dynamic = owner.sessionCreateSnapshot(name, desc);
        if (info.success == 0) {
            throw new SessionError('Failed to create snapshot "${name}"', info.errorCode, 
                {operation: "createSnapshot", param: 'name="${name}"'});
        }
        return new Snapshot({
            id: info.id,
            name: info.name,
            description: info.description,
            timestamp: Std.int(Date.now().getTime() / 1000),
            isCurrentSnapshot: true,
            parentId: ""
        });
        #else
        throw new SessionError("createSnapshot not supported on non-cpp target", -1, 
            {operation: "createSnapshot", param: 'name="${name}"'});
        #end
    }

    /**
     * List all snapshots of the current machine
     * 
     * Snapshots are ordered chronologically by creation.
     * 
     * @return Array of snapshot objects
     * @throws SessionError If snapshot listing fails
     * 
     * **Example:**
     * ```haxe
     * var session = vbox.lockMachine("MyVM", LockType.Shared);
     * var snapshots = session.listSnapshots();
     * for (snapshot in snapshots) {
     *     trace('${snapshot.name} (${snapshot.id})');
     * }
     * session.unlock();
     * ```
     */
    public function listSnapshots():Array<Snapshot> {
        ensureActive();
        #if cpp
        var list = owner.sessionListSnapshots();
        var snapshots = new Array<Snapshot>();
        
        if (list != null) {
            var entry:Dynamic = list;
            while (entry != null) {
                snapshots.push(new Snapshot({
                    id: entry.id,
                    name: entry.name,
                    description: entry.description,
                    timestamp: entry.timestamp,
                    isCurrentSnapshot: entry.isCurrentSnapshot != 0,
                    parentId: entry.parentId
                }));
                entry = entry.next;
            }
        }
        
        return snapshots;
        #else
        throw new SessionError("listSnapshots not supported on non-cpp target", -1, 
            {operation: "listSnapshots"});
        #end
    }

    /**
     * Find a snapshot by ID or name
     * 
     * @param snapshotIdOrName Snapshot UUID or display name
     * @return Snapshot information if found
     * @throws SessionError If snapshot not found or lookup fails
     * 
     * **Example:**
     * ```haxe
     * var session = vbox.lockMachine("MyVM", LockType.Shared);
     * var snapshot = session.findSnapshot("Baseline");
     * trace('Found: ${snapshot.name} - ${snapshot.description}');
     * session.unlock();
     * ```
     */
    public function findSnapshot(snapshotIdOrName:String):Snapshot {
        ensureActive();
        #if cpp
        var info:Dynamic = owner.sessionFindSnapshot(snapshotIdOrName);
        if (info.success == 0) {
            throw new SessionError('Snapshot not found: "${snapshotIdOrName}"', info.errorCode, 
                {operation: "findSnapshot", param: 'snapshotIdOrName="${snapshotIdOrName}"'});
        }
        return new Snapshot({
            id: info.id,
            name: info.name,
            description: info.description,
            timestamp: 0,
            isCurrentSnapshot: false,
            parentId: ""
        });
        #else
        throw new SessionError("findSnapshot not supported on non-cpp target", -1, 
            {operation: "findSnapshot", param: 'snapshotIdOrName="${snapshotIdOrName}"'});
        #end
    }

    /**
     * Restore VM to a previous snapshot state
     * 
     * The machine must be stopped before restoration. Restores all disk, memory,
     * and configuration to the snapshot point-in-time.
     * 
     * @param snapshotIdOrName Snapshot UUID or display name
     * @throws SessionError If restoration fails or machine is running
     * 
     * **Example:**
     * ```haxe
     * var session = vbox.lockMachine("MyVM", LockType.Write);
     * try {
     *     // Try risky operation...
     * } catch (e:Dynamic) {
     *     // Rollback to known-good state
     *     session.restoreSnapshot("Baseline");
     * }
     * session.unlock();
     * ```
     */
    public function restoreSnapshot(snapshotIdOrName:String):Void {
        ensureActive();
        #if cpp
        var code = owner.sessionRestoreSnapshot(snapshotIdOrName);
        if (code != 0) {
            throw new SessionError('Failed to restore snapshot "${snapshotIdOrName}"', code, 
                {operation: "restoreSnapshot", param: 'snapshotIdOrName="${snapshotIdOrName}"'});
        }
        #else
        throw new SessionError("restoreSnapshot not supported on non-cpp target", -1, 
            {operation: "restoreSnapshot", param: 'snapshotIdOrName="${snapshotIdOrName}"'});
        #end
    }

    /**
     * Delete a snapshot
     * 
     * Removes a snapshot and reclaims disk space. Child snapshots are typically
     * preserved and reparented.
     * 
     * @param snapshotIdOrName Snapshot UUID or display name
     * @throws SessionError If deletion fails
     * 
     * **Example:**
     * ```haxe
     * var session = vbox.lockMachine("MyVM", LockType.Write);
     * session.deleteSnapshot("OldTest");  // Clean up old snapshots
     * session.unlock();
     * ```
     */
    public function deleteSnapshot(snapshotIdOrName:String):Void {
        ensureActive();
        #if cpp
        var code = owner.sessionDeleteSnapshot(snapshotIdOrName);
        if (code != 0) {
            throw new SessionError('Failed to delete snapshot "${snapshotIdOrName}"', code, 
                {operation: "deleteSnapshot", param: 'snapshotIdOrName="${snapshotIdOrName}"'});
        }
        #else
        throw new SessionError("deleteSnapshot not supported on non-cpp target", -1, 
            {operation: "deleteSnapshot", param: 'snapshotIdOrName="${snapshotIdOrName}"'});
        #end
    }

    /**
     * Add a new storage controller to the machine
     * 
     * Creates and attaches a storage controller of the specified type.
     * Requires Write session lock.
     * 
     * @param name Display name for the controller
     * @param type Controller type (SATA, IDE, SCSI, USB, NVMe, Floppy)
     * @return StorageController information including ID and device count
     * @throws SessionError If controller creation fails
     * 
     * **Example:**
     * ```haxe
     * var session = vbox.lockMachine("MyVM", LockType.Write);
     * var sata = session.addStorageController("SATA Controller", StorageControllerType.SATA);
     * session.saveSettings();
     * session.unlock();
     * ```
     */
    public function addStorageController(name:String, type:StorageControllerType):StorageController {
        ensureActive();
        #if cpp
        var info = owner.sessionAddStorageController(name, cast type);
        if (info == null) {
            throw new SessionError('Failed to add storage controller "$name"', -1, 
                {operation: "addStorageController", param: 'name="$name", type="${type}"'});
        }
        // Convert Dynamic response to StorageController
        return new StorageController(
            cast(info.id, String),
            cast(info.name, String),
            cast(info.controllerType, String),
            cast(info.maxDevices, Int),
            cast(info.bootable, Bool)
        );
        #else
        throw new SessionError("addStorageController not supported on non-cpp target", -1, 
            {operation: "addStorageController", param: 'name="$name"'});
        #end
    }

    /**
     * Remove a storage controller from the machine
     * 
     * Detaches and removes a storage controller. All media must be detached first.
     * Requires Write session lock.
     * 
     * @param name Name of the controller to remove
     * @throws SessionError If removal fails
     * 
     * **Example:**
     * ```haxe
     * var session = vbox.lockMachine("MyVM", LockType.Write);
     * session.removeStorageController("Old SATA");
     * session.saveSettings();
     * session.unlock();
     * ```
     */
    public function removeStorageController(name:String):Void {
        ensureActive();
        #if cpp
        var code = owner.sessionRemoveStorageController(name);
        if (code != 0) {
            throw new SessionError('Failed to remove storage controller "$name"', code, 
                {operation: "removeStorageController", param: 'name="$name"'});
        }
        #else
        throw new SessionError("removeStorageController not supported on non-cpp target", -1, 
            {operation: "removeStorageController", param: 'name="$name"'});
        #end
    }

    /**
     * Open and register a virtual media file
     * 
     * Opens a media file (disk image, ISO, etc.) and registers it with VirtualBox.
     * Media can then be attached to storage controllers.
     * 
     * @param mediumPath Full file path to the media file
     * @return Medium information including ID, size, and format
     * @throws SessionError If opening fails
     * 
     * **Example:**
     * ```haxe
     * var medium = session.openMedium("/path/to/disk.vdi");
     * trace('Medium ${medium.name} is ${medium.getFormattedSize()}');
     * ```
     */
    public function openMedium(mediumPath:String):Medium {
        ensureActive();
        #if cpp
        var info = owner.openMedium(mediumPath);
        if (info == null) {
            throw new SessionError('Failed to open medium "$mediumPath"', -1, 
                {operation: "openMedium", param: 'path="$mediumPath"'});
        }
        return new Medium(
            cast(info.id, String),
            cast(info.name, String),
            cast(info.path, String),
            cast(info.size, Int),
            cast(info.type, String),
            cast(info.format, String)
        );
        #else
        throw new SessionError("openMedium not supported on non-cpp target", -1, 
            {operation: "openMedium", param: 'path="$mediumPath"'});
        #end
    }

    /**
     * Close and unregister a virtual media file
     * 
     * Unregisters a previously opened media file. Media must be detached from
     * all controllers before closing.
     * 
     * @param mediumId Medium UUID or name
     * @throws SessionError If closing fails
     */
    public function closeMedium(mediumId:String):Void {
        ensureActive();
        #if cpp
        var code = owner.closeMedium(mediumId);
        if (code != 0) {
            throw new SessionError('Failed to close medium "$mediumId"', code, 
                {operation: "closeMedium", param: 'mediumId="$mediumId"'});
        }
        #else
        throw new SessionError("closeMedium not supported on non-cpp target", -1, 
            {operation: "closeMedium", param: 'mediumId="$mediumId"'});
        #end
    }

    /**
     * Attach a media file to a storage controller
     * 
     * Connects a previously opened medium to a specific port and device
     * on a storage controller. Requires Write session lock.
     * 
     * @param mediumId Medium UUID or name
     * @param controllerName Name of the target storage controller
     * @param port Port number on the controller
     * @param device Device number at the port (usually 0 or 1)
     * @throws SessionError If attachment fails
     * 
     * **Example:**
     * ```haxe
     * var session = vbox.lockMachine("MyVM", LockType.Write);
     * var medium = session.openMedium("/path/to/disk.vdi");
     * session.attachMedium(medium.id, "SATA Controller", 0, 0);
     * session.saveSettings();
     * session.unlock();
     * ```
     */
    public function attachMedium(mediumId:String, controllerName:String, port:Int, device:Int):Void {
        ensureActive();
        #if cpp
        var code = owner.sessionAttachMedium(mediumId, controllerName, port, device);
        if (code != 0) {
            throw new SessionError('Failed to attach medium "$mediumId"', code, 
                {operation: "attachMedium", param: 'medium="$mediumId", controller="$controllerName"'});
        }
        #else
        throw new SessionError("attachMedium not supported on non-cpp target", -1, 
            {operation: "attachMedium", param: 'medium="$mediumId"'});
        #end
    }

    /**
     * Detach a media file from its storage controller
     * 
     * Disconnects a medium from the controller it's attached to.
     * Requires Write session lock.
     * 
     * @param mediumId Medium UUID or name
     * @throws SessionError If detachment fails
     * 
     * **Example:**
     * ```haxe
     * var session = vbox.lockMachine("MyVM", LockType.Write);
     * session.detachMedium(mediumId);
     * session.saveSettings();
     * session.unlock();
     * ```
     */
    public function detachMedium(mediumId:String):Void {
        ensureActive();
        #if cpp
        var code = owner.sessionDetachMedium(mediumId);
        if (code != 0) {
            throw new SessionError('Failed to detach medium "$mediumId"', code, 
                {operation: "detachMedium", param: 'mediumId="$mediumId"'});
        }
        #else
        throw new SessionError("detachMedium not supported on non-cpp target", -1, 
            {operation: "detachMedium", param: 'mediumId="$mediumId"'});
        #end
    }

    /**
     * Gracefully shutdown the VM with a timeout before forced power-off.
     * 
     * Sends ACPI signal to guest OS for clean shutdown. If timeout expires,
     * performs forced power-off to prevent indefinite hangs.
     * 
     * @param gracefulTimeoutMs milliseconds to wait for graceful shutdown (default 30000)
     * @throws SessionError if shutdown fails
     * 
     * Example:
     * ```haxe
     * session.gracefulStop(30000); // 30 second timeout for clean shutdown
     * ```
     */
    public function gracefulStop(?gracefulTimeoutMs:Int = 30000):Void {
        ensureActive();
        try {
            powerButton();
            var poller = new StatePoller(PoweredOff, gracefulTimeoutMs, 500);
            
            while (true) {
                #if cpp
                var machineState:MachineState = getMachine().state;
                if (poller.checkState(machineState)) {
                    return;
                }
                #end
                
                var pollIntervalMs = poller.getPollIntervalMs();
                Sys.sleep(pollIntervalMs / 1000.0);
            }
        } catch (e:StatePollerError) {
            // Timeout occurred, force shutdown
            powerDown(0);
        }
    }

    /**
     * Force stop the VM immediately.
     * 
     * Performs hard power-off without allowing graceful shutdown.
     * Use only when gracefulStop has failed or in emergency scenarios.
     * May cause data loss or corruption - use sparingly.
     * 
     * @throws SessionError if power-off fails
     * 
     * Example:
     * ```haxe
     * session.forceStop(); // Immediate power-off
     * ```
     */
    public function forceStop():Void {
        ensureActive();
        powerDown(0);
    }

    /**
     * Stop the VM with specified stop mode.
     * 
     * Flexible shutdown method supporting multiple stop strategies:
     * - Graceful: Clean OS shutdown (may hang indefinitely)
     * - Force: Immediate hard power-off
     * - SaveState: Save VM state to disk before stopping (can resume exact state)
     * - PowerDown: Hard power-off similar to Force
     * 
     * @param stopMode The shutdown strategy to use
     * @param timeoutMs Maximum milliseconds to wait (default 30000, ignored for Force mode)
     * @throws SessionError if shutdown fails
     * 
     * Example:
     * ```haxe
     * session.stop(StopMode.Graceful, 60000); // 60 seconds for graceful shutdown
     * session.stop(StopMode.Force);           // Immediate shutdown
     * session.stop(StopMode.SaveState);       // Save and shutdown
     * ```
     */
    public function stop(stopMode:StopMode, ?timeoutMs:Int = 30000):Void {
        ensureActive();
        switch (stopMode) {
            case Graceful:
                gracefulStop(timeoutMs);
            case Force:
                forceStop();
            case SaveState:
                // SaveState is like graceful but we don't poll - let VBox save automatically
                try {
                    powerButton();
                    // Brief wait for state transition
                    var poller = new StatePoller(PoweredOff, timeoutMs, 500);
                    var remaining = poller.getRemainingMs();
                    while (remaining > 0) {
                        #if cpp
                        var machineState:MachineState = getMachine().state;
                        if (machineState == PoweredOff) break;
                        #end
                        Sys.sleep(0.5);
                        remaining = poller.getRemainingMs();
                    }
                } catch (e:Dynamic) {
                    // Best effort - don't throw if timeout
                }
            case PowerDown:
                forceStop();
        }
    }

    /**
     * Create a state poller for custom state transition monitoring.
     * 
     * Useful when you need fine-grained control over state waiting
     * or want to implement custom retry logic.
     * 
     * @param targetState The machine state to wait for
     * @param maxWaitMs Maximum milliseconds to wait (default 30000)
     * @param pollIntervalMs Poll check interval in milliseconds (default 500)
     * @return StatePoller instance for monitoring state changes
     * 
     * Example:
     * ```haxe
     * var poller = session.createStatePoller(Running, 60000, 1000);
     * while (!poller.hasTimedOut()) {
     *     if (poller.checkState(session.getMachine().state)) {
     *         break;
     *     }
     *     Sys.sleep(1.0);
     * }
     * ```
     */
    public function createStatePoller(targetState:MachineState, ?maxWaitMs:Int = 30000, ?pollIntervalMs:Int = 500):StatePoller {
        return new StatePoller(targetState, maxWaitMs, pollIntervalMs);
    }

    /**
     * Poll for a specific machine state with timeout.
     * 
     * Continuously checks machine state until target is reached or timeout expires.
     * 
     * @param targetState The state to wait for
     * @param maxWaitMs Maximum milliseconds to wait (default 30000)
     * @param pollIntervalMs Interval between state checks in milliseconds (default 500)
     * @return The machine when target state is reached
     * @throws StatePollerError if timeout exceeded before reaching target state
     * 
     * Example:
     * ```haxe
     * var machine = session.waitForState(Running, 60000); // Wait up to 60 seconds
     * ```
     */
    public function waitForState(targetState:MachineState, ?maxWaitMs:Int = 30000, ?pollIntervalMs:Int = 500):Machine {
        var poller = new StatePoller(targetState, maxWaitMs, pollIntervalMs);
        
        while (true) {
            var currentState = getMachine().state;
            if (poller.checkState(currentState)) {
                return getMachine();
            }
            Sys.sleep(pollIntervalMs / 1000.0);
        }
    }
}
