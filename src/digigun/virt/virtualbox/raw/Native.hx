package digigun.virt.virtualbox.raw;

#if cpp
import digigun.virt.virtualbox.raw.Types.NativeErrorInfo;
import digigun.virt.virtualbox.raw.Types.NativeMachineEntry;
import digigun.virt.virtualbox.raw.Types.NativeMachineInfo;
import digigun.virt.virtualbox.raw.Types.NativeProgressInfo;
import digigun.virt.virtualbox.raw.Types.NativeVersionInfo;
import digigun.virt.virtualbox.raw.Types.NativeSnapshotEntry;
import digigun.virt.virtualbox.raw.Types.NativeSnapshotInfo;
import digigun.virt.virtualbox.raw.Types.NativeStorageControllerEntry;
import digigun.virt.virtualbox.raw.Types.NativeStorageControllerInfo;
import digigun.virt.virtualbox.raw.Types.NativeMediumEntry;
import digigun.virt.virtualbox.raw.Types.NativeMediumInfo;
import digigun.virt.virtualbox.raw.Types.NativeMediumAttachmentEntry;
import digigun.virt.virtualbox.raw.Types.NativeMediumAttachmentInfo;
import digigun.virt.virtualbox.raw.Types.NativeHostInfo;
import digigun.virt.virtualbox.raw.Types.NativeProcessorInfo;
import digigun.virt.virtualbox.raw.Types.NativeResourceMetrics;

@:include("virtualbox_bridge.h")
@:noDoc
extern class Native {
    private static function __init__():Void {
        digigun.virt.virtualbox.NativeBuild.init();
    }

    @:native("hx_vbox_open")
    static function open():cpp.RawPointer<cpp.Void>;

    @:native("hx_vbox_close")
    static function close(ctx:cpp.RawPointer<cpp.Void>):Void;

    @:native("hx_vbox_get_version_info")
    static function getVersionInfo(ctx:cpp.RawPointer<cpp.Void>):cpp.RawPointer<NativeVersionInfo>;

    @:native("hx_vbox_list_machines")
    static function listMachines(ctx:cpp.RawPointer<cpp.Void>):cpp.RawPointer<NativeMachineEntry>;

    @:native("hx_vbox_find_machine")
    static function findMachine(ctx:cpp.RawPointer<cpp.Void>, nameOrId:cpp.ConstCharStar):cpp.RawPointer<NativeMachineInfo>;

    @:native("hx_vbox_session_lock_machine")
    static function sessionLockMachine(ctx:cpp.RawPointer<cpp.Void>, nameOrId:cpp.ConstCharStar, lockType:Int):Int;

    @:native("hx_vbox_session_unlock_machine")
    static function sessionUnlockMachine(ctx:cpp.RawPointer<cpp.Void>):Int;

    @:native("hx_vbox_session_get_state")
    static function sessionGetState(ctx:cpp.RawPointer<cpp.Void>):Int;

    @:native("hx_vbox_session_get_machine_info")
    static function sessionGetMachineInfo(ctx:cpp.RawPointer<cpp.Void>):cpp.RawPointer<NativeMachineInfo>;

    @:native("hx_vbox_session_pause")
    static function sessionPause(ctx:cpp.RawPointer<cpp.Void>):Int;

    @:native("hx_vbox_session_resume")
    static function sessionResume(ctx:cpp.RawPointer<cpp.Void>):Int;

    @:native("hx_vbox_session_reset")
    static function sessionReset(ctx:cpp.RawPointer<cpp.Void>):Int;

    @:native("hx_vbox_session_power_button")
    static function sessionPowerButton(ctx:cpp.RawPointer<cpp.Void>):Int;

    @:native("hx_vbox_session_power_down")
    static function sessionPowerDown(ctx:cpp.RawPointer<cpp.Void>, timeoutMs:Int):Int;

    @:native("hx_vbox_launch_vm_process")
    static function launchVmProcess(ctx:cpp.RawPointer<cpp.Void>, nameOrId:cpp.ConstCharStar, frontend:cpp.ConstCharStar, timeoutMs:Int):cpp.RawPointer<NativeProgressInfo>;

    // Machine configuration (session-based modification only)
    @:native("hx_vbox_session_set_memory_size")
    static function sessionSetMemorySize(ctx:cpp.RawPointer<cpp.Void>, memoryMB:UInt):Int;

    @:native("hx_vbox_session_set_vcpu_count")
    static function sessionSetVCpuCount(ctx:cpp.RawPointer<cpp.Void>, cpuCount:UInt):Int;

    @:native("hx_vbox_session_set_boot_order")
    static function sessionSetBootOrder(ctx:cpp.RawPointer<cpp.Void>, device:Int, position:Int):Int;

    @:native("hx_vbox_session_save_settings")
    static function sessionSaveSettings(ctx:cpp.RawPointer<cpp.Void>):Int;

    // Snapshot operations (session-based)
    @:native("hx_vbox_session_create_snapshot")
    static function sessionCreateSnapshot(ctx:cpp.RawPointer<cpp.Void>, name:cpp.ConstCharStar, description:cpp.ConstCharStar):cpp.RawPointer<NativeSnapshotInfo>;

    @:native("hx_vbox_session_list_snapshots")
    static function sessionListSnapshots(ctx:cpp.RawPointer<cpp.Void>):cpp.RawPointer<NativeSnapshotEntry>;

    @:native("hx_vbox_session_find_snapshot")
    static function sessionFindSnapshot(ctx:cpp.RawPointer<cpp.Void>, snapshotIdOrName:cpp.ConstCharStar):cpp.RawPointer<NativeSnapshotInfo>;

    @:native("hx_vbox_session_restore_snapshot")
    static function sessionRestoreSnapshot(ctx:cpp.RawPointer<cpp.Void>, snapshotIdOrName:cpp.ConstCharStar):Int;

    @:native("hx_vbox_session_delete_snapshot")
    static function sessionDeleteSnapshot(ctx:cpp.RawPointer<cpp.Void>, snapshotIdOrName:cpp.ConstCharStar):Int;

    @:native("hx_vbox_snapshot_list_free")
    static function snapshotListFree(list:cpp.RawPointer<NativeSnapshotEntry>):Void;

    @:native("hx_vbox_machine_list_free")
    static function machineListFree(list:cpp.RawPointer<NativeMachineEntry>):Void;

    // Storage controller operations (session-based, requires Write lock)
    @:native("hx_vbox_session_get_storage_controllers")
    static function sessionGetStorageControllers(ctx:cpp.RawPointer<cpp.Void>):cpp.RawPointer<NativeStorageControllerEntry>;

    @:native("hx_vbox_session_add_storage_controller")
    static function sessionAddStorageController(ctx:cpp.RawPointer<cpp.Void>, name:cpp.ConstCharStar, controllerType:cpp.ConstCharStar):cpp.RawPointer<NativeStorageControllerInfo>;

    @:native("hx_vbox_session_remove_storage_controller")
    static function sessionRemoveStorageController(ctx:cpp.RawPointer<cpp.Void>, name:cpp.ConstCharStar):Int;

    // Media operations
    @:native("hx_vbox_open_medium")
    static function openMedium(ctx:cpp.RawPointer<cpp.Void>, path:cpp.ConstCharStar):cpp.RawPointer<NativeMediumInfo>;

    @:native("hx_vbox_close_medium")
    static function closeMedium(ctx:cpp.RawPointer<cpp.Void>, mediumId:cpp.ConstCharStar):Int;

    // Medium attachment operations (session-based, requires Write lock)
    @:native("hx_vbox_session_get_medium_attachments")
    static function sessionGetMediumAttachments(ctx:cpp.RawPointer<cpp.Void>):cpp.RawPointer<NativeMediumAttachmentEntry>;

    @:native("hx_vbox_session_attach_medium")
    static function sessionAttachMedium(ctx:cpp.RawPointer<cpp.Void>, mediumId:cpp.ConstCharStar, controllerName:cpp.ConstCharStar, port:Int, device:Int):Int;

    @:native("hx_vbox_session_detach_medium")
    static function sessionDetachMedium(ctx:cpp.RawPointer<cpp.Void>, mediumId:cpp.ConstCharStar):Int;

    // List cleanup functions
    @:native("hx_vbox_storage_controller_list_free")
    static function storageControllerListFree(list:cpp.RawPointer<NativeStorageControllerEntry>):Void;

    @:native("hx_vbox_medium_list_free")
    static function mediumListFree(list:cpp.RawPointer<NativeMediumEntry>):Void;

    @:native("hx_vbox_medium_attachment_list_free")
    static function mediumAttachmentListFree(list:cpp.RawPointer<NativeMediumAttachmentEntry>):Void;

    @:native("hx_vbox_get_last_error")
    static function getLastError():cpp.RawPointer<NativeErrorInfo>;

    // Host information operations
    @:native("hx_vbox_get_host_info")
    static function getHostInfo(ctx:cpp.RawPointer<cpp.Void>):cpp.RawPointer<NativeHostInfo>;

    @:native("hx_vbox_get_processor_info")
    static function getProcessorInfo(ctx:cpp.RawPointer<cpp.Void>, cpuId:UInt):cpp.RawPointer<NativeProcessorInfo>;

    // Resource monitoring operations
    @:native("hx_vbox_get_resource_metrics")
    static function getResourceMetrics(ctx:cpp.RawPointer<cpp.Void>):cpp.RawPointer<NativeResourceMetrics>;
}
