package digigun.virt.virtualbox;

#if cpp
import cpp.Pointer;
import digigun.virt.virtualbox.raw.Native;
import digigun.virt.virtualbox.raw.Types.NativeErrorInfo;
import digigun.virt.virtualbox.raw.Types.NativeMachineEntry;
import digigun.virt.virtualbox.raw.Types.NativeMachineInfo;
import digigun.virt.virtualbox.raw.Types.NativeProgressInfo;
import digigun.virt.virtualbox.raw.Types.NativeVersionInfo;
import digigun.virt.virtualbox.raw.Types.NativeHostInfo;
import digigun.virt.virtualbox.raw.Types.NativeProcessorInfo;
#end

/// Version and API information for the installed VirtualBox
typedef VersionInfo = {
    var version:Int;           /// Major version number (e.g., 7 for VirtualBox 7.2.8)
    var apiVersion:Int;        /// API version number (e.g., 7002)
    var revision:Int;          /// Revision number
    var versionString:String;  /// Full version string (e.g., "7.2.8")
    var homeFolder:String;     /// Installation home directory
}

/**
 * Main VirtualBox API entry point
 * 
 * Provides connection management and machine discovery for VirtualBox automation.
 * All operations must be done within an open/close lifecycle:
 * 
 * ```haxe
 * var vbox = VirtualBox.open();
 * var machines = vbox.listMachines();
 * var machine = vbox.findMachine("my-vm");
 * vbox.close();
 * ```
 * 
 * Machine control (pause, resume, power down, etc.) is done via Session objects,
 * which must be explicitly locked and unlocked.
 * 
 * **Thread Safety:** Not thread-safe. Do not access the same VirtualBox connection
 * from multiple threads. Create separate VirtualBox instances for concurrent operations.
 * 
 * **Platform Support:** CPP target only. Other targets throw ConnectionError.
 * Tested on macOS with VirtualBox 7.2.8 and Apple Silicon (ARM64).
 */
class VirtualBox {
    #if cpp
    @:allow(digigun.virt.virtualbox.Session)
    private var handle:cpp.RawPointer<cpp.Void>;
    #end

    /**
     * Opens a connection to the local VirtualBox instance
     * 
     * This is the main entry point for VirtualBox automation. Must be paired
     * with a call to `close()` when done to release resources.
     * 
     * @return A new VirtualBox connection handle
     * @throws ConnectionError If VirtualBox is not installed, not running, or cannot be accessed
     * @throws ConnectionError If platform is not supported (non-CPP target)
     * 
     * **Example:**
     * ```haxe
     * try {
     *   var vbox = VirtualBox.open();
     *   var version = vbox.getVersionInfo();
     *   trace('Connected to VirtualBox ${version.versionString}');
     *   vbox.close();
     * } catch (e:ConnectionError) {
     *   trace('Failed to connect: ${e.message}');
     * }
     * ```
     */
    public static function open():VirtualBox {
        #if cpp
        var handle = Native.open();
        if (handle == null) {
            throw ErrorHelper.captureConnectionError("open");
        }
        return new VirtualBox(handle);
        #else
        throw new ConnectionError("VirtualBox is only supported on the cpp target", -1, {operation: "open"});
        #end
    }

    private function new(handle:cpp.RawPointer<cpp.Void>) {
        #if cpp
        this.handle = handle;
        #end
    }

    /**
     * Retrieves version and API information from the running VirtualBox instance
     * 
     * Useful for:
     * - Verifying VirtualBox is installed and accessible
     * - Checking API compatibility before operations
     * - Logging version info for debugging
     * 
     * @return VersionInfo typedef with version, apiVersion, revision, versionString, homeFolder
     * @throws ConnectionError If version query fails (invalid context, connection lost)
     * 
     * **Example:**
     * ```haxe
     * var info = vbox.getVersionInfo();
     * trace('Version: ${info.versionString}');
     * trace('API: ${info.apiVersion}');
     * trace('Home: ${info.homeFolder}');
     * ```
     */
    public function getVersionInfo():VersionInfo {
        #if cpp
        var raw = Native.getVersionInfo(handle);
        if (raw == null) {
            throw ErrorHelper.captureConnectionError("getVersionInfo");
        }
        var info:NativeVersionInfo = Pointer.fromRaw(raw).value;
        if (info.success == 0) {
            var msg = ErrorHelper.ErrorHelper.toNullableString(info.errorMessage) ?? "Failed to get version info";
            throw new ConnectionError(msg, info.errorCode, {operation: "getVersionInfo"});
        }
        return {
            version: info.version,
            apiVersion: info.apiVersion,
            revision: info.revision,
            versionString: ErrorHelper.ErrorHelper.toNullableString(info.versionString),
            homeFolder: ErrorHelper.ErrorHelper.toNullableString(info.homeFolder)
        };
        #else
        throw new ConnectionError("VirtualBox is only supported on the cpp target", -1, {operation: "getVersionInfo"});
        #end
    }

    /**
     * Lists all available VirtualBox machines on the system
     * 
     * Returns basic machine information (id, name, state) for all registered VMs.
     * For detailed machine information, use `findMachine()`.
     * 
     * @return Array of Machine objects with state information
     * @throws MachineError If the query fails
     * 
     * **Common Use Cases:**
     * - Discovering available VMs to control
     * - Finding a target VM by name
     * - Checking total number of VMs
     * 
     * **Example:**
     * ```haxe
     * var machines = vbox.listMachines();
     * trace('Found ${machines.length} machines');
     * for (m in machines) {
     *   trace('  - ${m.name}: ${m.state}');
     * }
     * ```
     */
    public function listMachines():Array<Machine> {
        #if cpp
        var head = Native.listMachines(handle);
        if (head == null) {
            var code = getLastErrorCode();
            if (code != 0) {
                throw ErrorHelper.captureMachineError("listMachines");
            }
            return [];
        }

        var machines = new Array<Machine>();
        var current = Pointer.fromRaw(head);
        while (current != null && current.raw != null) {
            var entry:NativeMachineEntry = current.value;
            machines.push(new Machine({
                id: ErrorHelper.toNullableString(entry.id),
                name: ErrorHelper.toNullableString(entry.name),
                state: cast entry.state,
                accessible: true,
                description: null,
                settingsFilePath: null,
                memorySize: 0,
                osTypeId: null,
                osDescription: null
            }));
            current = Pointer.fromRaw(entry.next);
        }
        Native.machineListFree(head);
        return machines;
        #else
        return [];
        #end
    }

    /**
     * Finds a machine by name or UUID
     * 
     * Retrieves complete machine information including memory, OS type, and settings path.
     * This is the main way to get a Machine object for further operations.
     * 
     * @param nameOrId Machine name (case-sensitive) or UUID
     * @return Machine object with full details
     * @throws MachineError If machine is not found or query fails
     * 
     * **Example:**
     * ```haxe
     * // Find by name
     * var machine = vbox.findMachine("UbuntuServer");
     * trace('Found: ${machine.name}');
     * trace('Memory: ${machine.memorySize}MB');
     * 
     * // Find by UUID
     * var machine = vbox.findMachine("12345678-1234-5678-1234-567812345678");
     * ```
     */
    public function findMachine(nameOrId:String):Machine {
        #if cpp
        var raw = Native.findMachine(handle, nameOrId);
        if (raw == null) {
            throw ErrorHelper.captureMachineError("findMachine", nameOrId);
        }

        var info:NativeMachineInfo = Pointer.fromRaw(raw).value;
        if (info.success == 0) {
            var msg = ErrorHelper.toNullableString(info.errorMessage) ?? "Machine not found";
            throw new MachineError(msg, info.errorCode, {operation: "findMachine", param: nameOrId});
        }

        return new Machine({
            id: ErrorHelper.toNullableString(info.id),
            name: ErrorHelper.toNullableString(info.name),
            state: cast info.state,
            accessible: info.accessible != 0,
            description: ErrorHelper.toNullableString(info.description),
            settingsFilePath: ErrorHelper.toNullableString(info.settingsFilePath),
            memorySize: info.memorySize,
            osTypeId: ErrorHelper.toNullableString(info.osTypeId),
            osDescription: ErrorHelper.toNullableString(info.osDescription)
        });
        #else
        throw new MachineError("findMachine not supported on non-cpp target", -1, {operation: "findMachine", param: nameOrId});
        #end
    }

    /**
     * Locks a machine for exclusive control operations
     * 
     * Creates a session that allows you to control a VM (pause, resume, power down, etc.).
     * Must be paired with `session.unlock()` when done.
     * 
     * @param nameOrId Machine name or UUID
     * @param lockType LockType.Shared (default) or LockType.Exclusive - Use Shared for normal control
     * @return Session handle for machine control operations
     * @throws SessionError If machine is already locked by another session, not found, or lock fails
     * 
     * **Lock Types:**
     * - `Shared` - Allows other processes to also lock the machine (default, safe)
     * - `Exclusive` - Prevents other locks (more restrictive, rarely needed)
     * 
     * **Example:**
     * ```haxe
     * var machine = vbox.findMachine("UbuntuServer");
     * var session = vbox.lockMachine(machine.id, LockType.Shared);
     * session.pause();
     * session.unlock();
     * ```
     */
    public function lockMachine(nameOrId:String, ?lockType:LockType = Shared):Session {
        #if cpp
        if (Native.sessionLockMachine(handle, nameOrId, lockType) == 0) {
            throw ErrorHelper.captureSessionError("lockMachine", nameOrId);
        }
        return new Session(this);
        #else
        throw new SessionError("lockMachine not supported on non-cpp target", -1, {operation: "lockMachine", param: nameOrId});
        #end
    }

    /**
     * Starts a VM in the specified frontend mode
     * 
     * Launches a virtual machine and waits for the operation to complete internally.
     * After this call returns, the launch operation is finished, but the guest OS may
     * still be booting. Use `session.waitUntilRunning()` to detect when the VM is ready
     * for commands.
     * 
     * **Important Architecture Note:**
     * This function internally locks the session as part of the launch operation.
     * Therefore, after calling `launchVmProcess()`, you should NOT call `lockMachine()`.
     * Instead, create a Session directly: `new Session(vbox)`.
     * 
     * @param nameOrId Machine name or UUID
     * @param frontend UI frontend to use (default LaunchMode.Headless)
     *                  Other options: LaunchMode.GUI, LaunchMode.SDL, LaunchMode.VRDP, LaunchMode.Separate
     * @param timeoutMs Timeout in milliseconds. -1 means wait indefinitely (default)
     * @return Progress object with operation status (percent, resultCode)
     * @throws MachineError If machine not found or launch fails
     * 
     * **Example:**
     * ```haxe
     * var progress = vbox.launchVmProcess(machineId, LaunchMode.Headless, -1);
     * trace('Launch progress: ${progress.percent}%');
     * 
     * var session = new Session(vbox);
     * session.waitUntilRunning(30000);  // Wait for guest OS to boot
     * session.pause();                  // Now safe to control
     * ```
     */
    public function launchVmProcess(nameOrId:String, ?frontend:LaunchMode = LaunchMode.Headless, ?timeoutMs:Int = -1):Progress {
        #if cpp
        var raw = Native.launchVmProcess(handle, nameOrId, cast(frontend:String), timeoutMs);
        if (raw == null) {
            throw ErrorHelper.captureMachineError("launchVmProcess", nameOrId);
        }

        var info:NativeProgressInfo = Pointer.fromRaw(raw).value;
        if (info.success == 0) {
            var msg = ErrorHelper.toNullableString(info.errorMessage) ?? "Failed to launch VM process";
            throw new MachineError(msg, info.errorCode, {operation: "launchVmProcess", param: nameOrId});
        }

        return new Progress({
            completed: info.completed != 0,
            cancelable: info.cancelable != 0,
            canceled: info.canceled != 0,
            percent: info.percent,
            operationCount: info.operationCount,
            resultCode: info.resultCode,
            description: ErrorHelper.toNullableString(info.description)
        });
        #else
        throw new MachineError("launchVmProcess not supported on non-cpp target", -1, {operation: "launchVmProcess", param: nameOrId});
        #end
    }

    /**
     * Closes the VirtualBox connection and releases all resources
     * 
     * Must be called when done with VirtualBox operations to clean up.
     * Ensure all sessions are unlocked before closing.
     * 
     * **Example:**
     * ```haxe
     * var vbox = VirtualBox.open();
     * try {
     *   // ... operations ...
     * } finally {
     *   vbox.close();
     * }
     * ```
     */
    public function close():Void {
        #if cpp
        if (handle != null) {
            Native.close(handle);
            handle = null;
        }
        #end
    }

    // Helper to check last error code
    private inline function getLastErrorCode():Int {
        #if cpp
        var raw = Native.getLastError();
        if (raw == null) return 0;
        var info:NativeErrorInfo = Pointer.fromRaw(raw).value;
        return info.code;
        #else
        return 0;
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function getSessionState():SessionState {
        #if cpp
        var state = Native.sessionGetState(handle);
        if (state < 0) {
            throw ErrorHelper.captureSessionError("getSessionState");
        }
        return cast state;
        #else
        throw new SessionError("getSessionState not supported on non-cpp target", -1, {operation: "getSessionState"});
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function getSessionMachine():Machine {
        #if cpp
        var raw = Native.sessionGetMachineInfo(handle);
        if (raw == null) {
            throw ErrorHelper.captureSessionError("getSessionMachine");
        }
        var info:NativeMachineInfo = Pointer.fromRaw(raw).value;
        if (info.success == 0) {
            var msg = ErrorHelper.toNullableString(info.errorMessage) ?? "Failed to get session machine";
            throw new SessionError(msg, info.errorCode, {operation: "getSessionMachine"});
        }
        return new Machine({
            id: ErrorHelper.toNullableString(info.id),
            name: ErrorHelper.toNullableString(info.name),
            state: cast info.state,
            accessible: info.accessible != 0,
            description: ErrorHelper.toNullableString(info.description),
            settingsFilePath: ErrorHelper.toNullableString(info.settingsFilePath),
            memorySize: info.memorySize,
            osTypeId: ErrorHelper.toNullableString(info.osTypeId),
            osDescription: ErrorHelper.toNullableString(info.osDescription)
        });
        #else
        throw new SessionError("getSessionMachine not supported on non-cpp target", -1, {operation: "getSessionMachine"});
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function unlockSession():Void {
        #if cpp
        if (Native.sessionUnlockMachine(handle) == 0) {
            throw ErrorHelper.captureSessionError("unlockSession");
        }
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function sessionPause():Void {
        #if cpp
        if (Native.sessionPause(handle) == 0) {
            throw ErrorHelper.captureSessionError("pause");
        }
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function sessionResume():Void {
        #if cpp
        if (Native.sessionResume(handle) == 0) {
            throw ErrorHelper.captureSessionError("resume");
        }
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function sessionReset():Void {
        #if cpp
        if (Native.sessionReset(handle) == 0) {
            throw ErrorHelper.captureSessionError("reset");
        }
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function sessionPowerButton():Void {
        #if cpp
        if (Native.sessionPowerButton(handle) == 0) {
            throw ErrorHelper.captureSessionError("powerButton");
        }
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function sessionPowerDown(timeoutMs:Int):Void {
        #if cpp
        if (Native.sessionPowerDown(handle, timeoutMs) == 0) {
            throw ErrorHelper.captureSessionError("powerDown");
        }
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function sessionSetMemorySize(memoryMB:Int):Int {
        #if cpp
        return Native.sessionSetMemorySize(handle, memoryMB);
        #else
        return -1;
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function sessionSetVCpuCount(cpuCount:Int):Int {
        #if cpp
        return Native.sessionSetVCpuCount(handle, cpuCount);
        #else
        return -1;
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function sessionSetBootOrder(device:Int, position:Int):Int {
        #if cpp
        return Native.sessionSetBootOrder(handle, device, position);
        #else
        return -1;
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function sessionSaveSettings():Int {
        #if cpp
        return Native.sessionSaveSettings(handle);
        #else
        return -1;
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function sessionCreateSnapshot(name:String, description:String):Dynamic {
        #if cpp
        return Native.sessionCreateSnapshot(handle, name, description);
        #else
        return null;
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function sessionListSnapshots():Dynamic {
        #if cpp
        return Native.sessionListSnapshots(handle);
        #else
        return null;
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function sessionFindSnapshot(snapshotIdOrName:String):Dynamic {
        #if cpp
        return Native.sessionFindSnapshot(handle, snapshotIdOrName);
        #else
        return null;
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function sessionRestoreSnapshot(snapshotIdOrName:String):Int {
        #if cpp
        return Native.sessionRestoreSnapshot(handle, snapshotIdOrName);
        #else
        return -1;
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function sessionDeleteSnapshot(snapshotIdOrName:String):Int {
        #if cpp
        return Native.sessionDeleteSnapshot(handle, snapshotIdOrName);
        #else
        return -1;
        #end
    }

    // Storage controller operations
    @:allow(digigun.virt.virtualbox.Session)
    private function sessionGetStorageControllers():Dynamic {
        #if cpp
        return Native.sessionGetStorageControllers(handle);
        #else
        return null;
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function sessionAddStorageController(name:String, controllerType:String):Dynamic {
        #if cpp
        return Native.sessionAddStorageController(handle, name, controllerType);
        #else
        return null;
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function sessionRemoveStorageController(name:String):Int {
        #if cpp
        return Native.sessionRemoveStorageController(handle, name);
        #else
        return -1;
        #end
    }

    // Media operations
    @:allow(digigun.virt.virtualbox.Session)
    private function openMedium(path:String):Dynamic {
        #if cpp
        return Native.openMedium(handle, path);
        #else
        return null;
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function closeMedium(mediumId:String):Int {
        #if cpp
        return Native.closeMedium(handle, mediumId);
        #else
        return -1;
        #end
    }

    // Medium attachment operations
    @:allow(digigun.virt.virtualbox.Session)
    private function sessionGetMediumAttachments():Dynamic {
        #if cpp
        return Native.sessionGetMediumAttachments(handle);
        #else
        return null;
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function sessionAttachMedium(mediumId:String, controllerName:String, port:Int, device:Int):Int {
        #if cpp
        return Native.sessionAttachMedium(handle, mediumId, controllerName, port, device);
        #else
        return -1;
        #end
    }

    @:allow(digigun.virt.virtualbox.Session)
    private function sessionDetachMedium(mediumId:String):Int {
        #if cpp
        return Native.sessionDetachMedium(handle, mediumId);
        #else
        return -1;
        #end
    }

    /**
     * Launch VM in GUI mode (normal windowed interface).
     * 
     * Convenience method for starting VM with graphical interface.
     * Equivalent to `launchVmProcess(nameOrId, LaunchMode.GUI, -1)`.
     * 
     * @param nameOrId Machine name or UUID
     * @return Progress object tracking the launch operation
     * @throws MachineError If machine not found or launch fails
     * 
     * Example:
     * ```haxe
     * var progress = vbox.launchGui("MyVM");
     * trace('GUI launched: ${progress.percent}%');
     * ```
     */
    public function launchGui(nameOrId:String):Progress {
        return launchVmProcess(nameOrId, GUI, -1);
    }

    /**
     * Launch VM in headless mode (server without UI).
     * 
     * Convenience method for automated/server deployments.
     * Equivalent to `launchVmProcess(nameOrId, LaunchMode.Headless, -1)`.
     * 
     * @param nameOrId Machine name or UUID
     * @return Progress object tracking the launch operation
     * @throws MachineError If machine not found or launch fails
     * 
     * Example:
     * ```haxe
     * var progress = vbox.launchHeadless("WebServer");
     * trace('Headless launched: ${progress.percent}%');
     * ```
     */
    public function launchHeadless(nameOrId:String):Progress {
        return launchVmProcess(nameOrId, Headless, -1);
    }

    /**
     * Launch VM in separate window mode (Windows-specific).
     * 
     * @param nameOrId Machine name or UUID
     * @return Progress object tracking the launch operation
     * @throws MachineError If machine not found or launch fails
     */
    public function launchSeparate(nameOrId:String):Progress {
        return launchVmProcess(nameOrId, Separate, -1);
    }

    /**
     * Get comprehensive host system information.
     * 
     * Retrieves system information from VirtualBox's IHost interface including
     * processor counts, memory, OS details, and architecture.
     * 
     * @return HostInfo object with system details
     * @throws ConnectionError If VirtualBox connection is invalid
     * 
     * Example:
     * ```haxe
     * var vbox = VirtualBox.open();
     * var hostInfo = vbox.getHostInfo();
     * trace('Architecture: ${hostInfo.architecture}');
     * trace('CPUs: ${hostInfo.processorOnlineCount}/${hostInfo.processorCount}');
     * trace('Memory: ${hostInfo.memory.getUsageString()}');
     * vbox.close();
     * ```
     */
    public function getHostInfo():HostInfo {
        #if cpp
        if (handle == null) {
            throw new ConnectionError("VirtualBox connection not open");
        }
        
        var raw = Native.getHostInfo(handle);
        ErrorHelper.checkPointerOrThrow(raw, "getHostInfo");
        
        var nativeInfo:NativeHostInfo = Pointer.fromRaw(raw).value;
        if (nativeInfo.success == 0) {
            var msg = ErrorHelper.toNullableString(nativeInfo.errorMessage) ?? "Failed to get host information";
            throw new ConnectionError(msg, nativeInfo.errorCode);
        }
        
        var arch = try {
            var archStr = ErrorHelper.toNullableString(nativeInfo.architecture) ?? "X64";
            cast archStr;
        } catch (e:Dynamic) {
            PlatformArchitecture.X64;
        };
        var memory = new MemoryInfo(
            cast nativeInfo.memorySize,
            cast nativeInfo.memoryAvailable
        );
        
        return new HostInfo(
            arch,
            ErrorHelper.toNullableString(nativeInfo.domainName) ?? "unknown",
            cast nativeInfo.processorCount,
            cast nativeInfo.processorOnlineCount,
            cast nativeInfo.processorCoreCount,
            cast nativeInfo.processorOnlineCoreCount,
            memory,
            ErrorHelper.toNullableString(nativeInfo.operatingSystem) ?? "unknown",
            ErrorHelper.toNullableString(nativeInfo.osVersion) ?? "unknown",
            nativeInfo.utcTime
        );
        #else
        throw new ConnectionError("Host information requires CPP target");
        #end
    }

    /**
     * Get information about a specific processor.
     * 
     * Retrieves CPU-specific information such as speed and online status.
     * 
     * @param cpuId CPU index (0-based)
     * @return ProcessorInfo object with CPU details
     * @throws ConnectionError If VirtualBox connection is invalid
     * @throws MachineError If CPU ID is invalid
     * 
     * Example:
     * ```haxe
     * var vbox = VirtualBox.open();
     * var hostInfo = vbox.getHostInfo();
     * for (i in 0...hostInfo.processorCount) {
     *     var cpu = vbox.getProcessorInfo(i);
     *     trace(cpu.getStatusString());
     * }
     * vbox.close();
     * ```
     */
    public function getProcessorInfo(cpuId:Int):ProcessorInfo {
        #if cpp
        if (handle == null) {
            throw new ConnectionError("VirtualBox connection not open");
        }
        
        var raw = Native.getProcessorInfo(handle, cast cpuId);
        ErrorHelper.checkPointerOrThrow(raw, "getProcessorInfo", '$cpuId');
        
        var nativeInfo:NativeProcessorInfo = Pointer.fromRaw(raw).value;
        if (nativeInfo.success == 0) {
            var msg = ErrorHelper.toNullableString(nativeInfo.errorMessage) ?? "Failed to get processor information";
            throw new MachineError(msg, nativeInfo.errorCode, {operation: "getProcessorInfo", param: '$cpuId'});
        }
        
        return new ProcessorInfo(
            cpuId,
            cast nativeInfo.speedMHz,
            nativeInfo.online != 0
        );
        #else
        throw new ConnectionError("Processor information requires CPP target");
        #end
    }
}

