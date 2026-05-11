package digigun.virt.virtualbox.raw;

#if cpp
@:include("virtualbox_bridge.h")
@:native("HxVBoxVersionInfo")
@:structAccess
@:noDoc
extern class NativeVersionInfo {
    @:native("success") var success:Int;
    @:native("version") var version:Int;
    @:native("apiVersion") var apiVersion:Int;
    @:native("revision") var revision:Int;
    @:native("versionString") var versionString:cpp.ConstCharStar;
    @:native("homeFolder") var homeFolder:cpp.ConstCharStar;
    @:native("errorCode") var errorCode:Int;
    @:native("errorMessage") var errorMessage:cpp.ConstCharStar;
}

@:include("virtualbox_bridge.h")
@:native("HxVBoxMachineEntry")
@:structAccess
@:noDoc
extern class NativeMachineEntry {
    @:native("handle") var handle:cpp.RawPointer<cpp.Void>;
    @:native("state") var state:Int;
    @:native("id") var id:cpp.ConstCharStar;
    @:native("name") var name:cpp.ConstCharStar;
    @:native("next") var next:cpp.RawPointer<NativeMachineEntry>;
}

@:include("virtualbox_bridge.h")
@:native("HxVBoxMachineInfo")
@:structAccess
@:noDoc
extern class NativeMachineInfo {
    @:native("success") var success:Int;
    @:native("accessible") var accessible:Int;
    @:native("state") var state:Int;
    @:native("memorySize") var memorySize:Int;
    @:native("id") var id:cpp.ConstCharStar;
    @:native("name") var name:cpp.ConstCharStar;
    @:native("description") var description:cpp.ConstCharStar;
    @:native("settingsFilePath") var settingsFilePath:cpp.ConstCharStar;
    @:native("osTypeId") var osTypeId:cpp.ConstCharStar;
    @:native("osDescription") var osDescription:cpp.ConstCharStar;
    @:native("errorCode") var errorCode:Int;
    @:native("errorMessage") var errorMessage:cpp.ConstCharStar;
}

@:include("virtualbox_bridge.h")
@:native("HxVBoxErrorInfo")
@:structAccess
@:noDoc
extern class NativeErrorInfo {
    @:native("code") var code:Int;
    @:native("message") var message:cpp.ConstCharStar;
}

@:include("virtualbox_bridge.h")
@:native("HxVBoxProgressInfo")
@:structAccess
@:noDoc
extern class NativeProgressInfo {
    @:native("success") var success:Int;
    @:native("completed") var completed:Int;
    @:native("cancelable") var cancelable:Int;
    @:native("canceled") var canceled:Int;
    @:native("percent") var percent:Int;
    @:native("operationCount") var operationCount:Int;
    @:native("resultCode") var resultCode:Int;
    @:native("description") var description:cpp.ConstCharStar;
    @:native("errorCode") var errorCode:Int;
    @:native("errorMessage") var errorMessage:cpp.ConstCharStar;
}

@:include("virtualbox_bridge.h")
@:native("HxVBoxSnapshotEntry")
@:structAccess
@:noDoc
extern class NativeSnapshotEntry {
    @:native("id") var id:cpp.ConstCharStar;
    @:native("name") var name:cpp.ConstCharStar;
    @:native("description") var description:cpp.ConstCharStar;
    @:native("timestamp") var timestamp:Int;
    @:native("isCurrentSnapshot") var isCurrentSnapshot:Int;
    @:native("parentId") var parentId:cpp.ConstCharStar;
    @:native("next") var next:cpp.RawPointer<NativeSnapshotEntry>;
}

@:include("virtualbox_bridge.h")
@:native("HxVBoxSnapshotInfo")
@:structAccess
@:noDoc
extern class NativeSnapshotInfo {
    @:native("success") var success:Int;
    @:native("id") var id:cpp.ConstCharStar;
    @:native("name") var name:cpp.ConstCharStar;
    @:native("description") var description:cpp.ConstCharStar;
    @:native("timestamp") var timestamp:Int;
    @:native("isCurrentSnapshot") var isCurrentSnapshot:Int;
    @:native("parentId") var parentId:cpp.ConstCharStar;
    @:native("errorCode") var errorCode:Int;
    @:native("errorMessage") var errorMessage:cpp.ConstCharStar;
}

@:include("virtualbox_bridge.h")
@:native("HxVBoxStorageControllerEntry")
@:structAccess
@:noDoc
extern class NativeStorageControllerEntry {
    @:native("id") var id:cpp.ConstCharStar;
    @:native("name") var name:cpp.ConstCharStar;
    @:native("controllerType") var controllerType:cpp.ConstCharStar;
    @:native("maxDevices") var maxDevices:Int;
    @:native("bootable") var bootable:Int;
    @:native("next") var next:cpp.RawPointer<NativeStorageControllerEntry>;
}

@:include("virtualbox_bridge.h")
@:native("HxVBoxStorageControllerInfo")
@:structAccess
@:noDoc
extern class NativeStorageControllerInfo {
    @:native("success") var success:Int;
    @:native("id") var id:cpp.ConstCharStar;
    @:native("name") var name:cpp.ConstCharStar;
    @:native("controllerType") var controllerType:cpp.ConstCharStar;
    @:native("maxDevices") var maxDevices:Int;
    @:native("bootable") var bootable:Int;
    @:native("errorCode") var errorCode:Int;
    @:native("errorMessage") var errorMessage:cpp.ConstCharStar;
}

@:include("virtualbox_bridge.h")
@:native("HxVBoxMediumEntry")
@:structAccess
@:noDoc
extern class NativeMediumEntry {
    @:native("id") var id:cpp.ConstCharStar;
    @:native("name") var name:cpp.ConstCharStar;
    @:native("path") var path:cpp.ConstCharStar;
    @:native("size") var size:Int;
    @:native("type") var type:cpp.ConstCharStar;
    @:native("format") var format:cpp.ConstCharStar;
    @:native("next") var next:cpp.RawPointer<NativeMediumEntry>;
}

@:include("virtualbox_bridge.h")
@:native("HxVBoxMediumInfo")
@:structAccess
@:noDoc
extern class NativeMediumInfo {
    @:native("success") var success:Int;
    @:native("id") var id:cpp.ConstCharStar;
    @:native("name") var name:cpp.ConstCharStar;
    @:native("path") var path:cpp.ConstCharStar;
    @:native("size") var size:Int;
    @:native("type") var type:cpp.ConstCharStar;
    @:native("format") var format:cpp.ConstCharStar;
    @:native("errorCode") var errorCode:Int;
    @:native("errorMessage") var errorMessage:cpp.ConstCharStar;
}

@:include("virtualbox_bridge.h")
@:native("HxVBoxMediumAttachmentEntry")
@:structAccess
@:noDoc
extern class NativeMediumAttachmentEntry {
    @:native("mediumId") var mediumId:cpp.ConstCharStar;
    @:native("mediumName") var mediumName:cpp.ConstCharStar;
    @:native("mediumType") var mediumType:cpp.ConstCharStar;
    @:native("controllerId") var controllerId:cpp.ConstCharStar;
    @:native("controllerName") var controllerName:cpp.ConstCharStar;
    @:native("controllerType") var controllerType:cpp.ConstCharStar;
    @:native("port") var port:Int;
    @:native("device") var device:Int;
    @:native("next") var next:cpp.RawPointer<NativeMediumAttachmentEntry>;
}

@:include("virtualbox_bridge.h")
@:native("HxVBoxMediumAttachmentInfo")
@:structAccess
@:noDoc
extern class NativeMediumAttachmentInfo {
    @:native("success") var success:Int;
    @:native("mediumId") var mediumId:cpp.ConstCharStar;
    @:native("mediumName") var mediumName:cpp.ConstCharStar;
    @:native("mediumType") var mediumType:cpp.ConstCharStar;
    @:native("controllerId") var controllerId:cpp.ConstCharStar;
    @:native("controllerName") var controllerName:cpp.ConstCharStar;
    @:native("controllerType") var controllerType:cpp.ConstCharStar;
    @:native("port") var port:Int;
    @:native("device") var device:Int;
    @:native("errorCode") var errorCode:Int;
    @:native("errorMessage") var errorMessage:cpp.ConstCharStar;
}

@:include("virtualbox_bridge.h")
@:native("HxVBoxHostInfo")
@:structAccess
@:noDoc
extern class NativeHostInfo {
    @:native("success") var success:Int;
    @:native("architecture") var architecture:cpp.ConstCharStar;
    @:native("domainName") var domainName:cpp.ConstCharStar;
    @:native("processorCount") var processorCount:UInt;
    @:native("processorOnlineCount") var processorOnlineCount:UInt;
    @:native("processorCoreCount") var processorCoreCount:UInt;
    @:native("processorOnlineCoreCount") var processorOnlineCoreCount:UInt;
    @:native("memorySize") var memorySize:UInt;
    @:native("memoryAvailable") var memoryAvailable:UInt;
    @:native("operatingSystem") var operatingSystem:cpp.ConstCharStar;
    @:native("osVersion") var osVersion:cpp.ConstCharStar;
    @:native("utcTime") var utcTime:Int;
    @:native("errorCode") var errorCode:Int;
    @:native("errorMessage") var errorMessage:cpp.ConstCharStar;
}

@:include("virtualbox_bridge.h")
@:native("HxVBoxProcessorInfo")
@:structAccess
@:noDoc
extern class NativeProcessorInfo {
    @:native("success") var success:Int;
    @:native("cpuId") var cpuId:UInt;
    @:native("speedMHz") var speedMHz:UInt;
    @:native("online") var online:Int;
    @:native("errorCode") var errorCode:Int;
    @:native("errorMessage") var errorMessage:cpp.ConstCharStar;
}

@:include("virtualbox_bridge.h")
@:native("HxVBoxResourceMetrics")
@:structAccess
@:noDoc
extern class NativeResourceMetrics {
    @:native("success") var success:Int;
    @:native("timestamp") var timestamp:cpp.Int64;
    @:native("cpuUsagePercent") var cpuUsagePercent:cpp.Float32;
    @:native("memoryUsedMB") var memoryUsedMB:cpp.UInt32;
    @:native("cpuCount") var cpuCount:cpp.UInt32;
    @:native("activeThreads") var activeThreads:cpp.UInt32;
    @:native("errorCode") var errorCode:Int;
    @:native("errorMessage") var errorMessage:cpp.ConstCharStar;
}

@:include("virtualbox_bridge.h")
@:native("HxVBoxEvent")
@:structAccess
@:noDoc
extern class NativeEvent {
    @:native("success") var success:Int;
    @:native("eventType") var eventType:cpp.ConstCharStar;
    @:native("timestamp") var timestamp:cpp.Int64;
    @:native("vmName") var vmName:cpp.ConstCharStar;
    @:native("description") var description:cpp.ConstCharStar;
    @:native("errorCode") var errorCode:Int;
    @:native("errorMessage") var errorMessage:cpp.ConstCharStar;
}

@:include("virtualbox_bridge.h")
@:native("HxVBoxEventSubscription")
@:structAccess
@:noDoc
extern class NativeEventSubscription {
    @:native("success") var success:Int;
    @:native("subscriptionId") var subscriptionId:cpp.Int64;
    @:native("errorCode") var errorCode:Int;
    @:native("errorMessage") var errorMessage:cpp.ConstCharStar;
}
#end
