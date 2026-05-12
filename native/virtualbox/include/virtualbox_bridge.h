#ifndef DIGIGUN_VIRT_VIRTUALBOX_BRIDGE_H
#define DIGIGUN_VIRT_VIRTUALBOX_BRIDGE_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct HxVBoxVersionInfo {
    int success;
    int version;
    int apiVersion;
    unsigned int revision;
    char versionString[128];
    char homeFolder[1024];
    int errorCode;
    char errorMessage[1024];
} HxVBoxVersionInfo;

typedef struct HxVBoxMachineEntry {
    void* handle;
    unsigned int state;
    char id[128];
    char name[256];
    struct HxVBoxMachineEntry* next;
} HxVBoxMachineEntry;

typedef struct HxVBoxMachineInfo {
    int success;
    int accessible;
    unsigned int state;
    unsigned int memorySize;
    char id[128];
    char name[256];
    char description[1024];
    char settingsFilePath[1024];
    char osTypeId[128];
    char osDescription[256];
    int errorCode;
    char errorMessage[1024];
} HxVBoxMachineInfo;

typedef struct HxVBoxErrorInfo {
    int code;
    char message[1024];
} HxVBoxErrorInfo;

typedef struct HxVBoxProgressInfo {
    int success;
    int completed;
    int cancelable;
    int canceled;
    unsigned int percent;
    unsigned int operationCount;
    int resultCode;
    char description[1024];
    int errorCode;
    char errorMessage[1024];
} HxVBoxProgressInfo;

typedef struct HxVBoxSnapshotEntry {
    char id[128];
    char name[256];
    char description[1024];
    int timestamp;
    int isCurrentSnapshot;
    char parentId[128];
    struct HxVBoxSnapshotEntry* next;
} HxVBoxSnapshotEntry;

typedef struct HxVBoxSnapshotInfo {
    int success;
    char id[128];
    char name[256];
    char description[1024];
    int timestamp;
    int isCurrentSnapshot;
    char parentId[128];
    int errorCode;
    char errorMessage[1024];
} HxVBoxSnapshotInfo;

typedef struct HxVBoxStorageControllerEntry {
    char id[128];
    char name[256];
    char controllerType[64];
    unsigned int maxDevices;
    int bootable;
    struct HxVBoxStorageControllerEntry* next;
} HxVBoxStorageControllerEntry;

typedef struct HxVBoxStorageControllerInfo {
    int success;
    char id[128];
    char name[256];
    char controllerType[64];
    unsigned int maxDevices;
    int bootable;
    int errorCode;
    char errorMessage[1024];
} HxVBoxStorageControllerInfo;

typedef struct HxVBoxMediumEntry {
    char id[128];
    char name[256];
    char path[1024];
    long long size;
    char type[64];
    char format[64];
    struct HxVBoxMediumEntry* next;
} HxVBoxMediumEntry;

typedef struct HxVBoxMediumInfo {
    int success;
    char id[128];
    char name[256];
    char path[1024];
    long long size;
    char type[64];
    char format[64];
    int errorCode;
    char errorMessage[1024];
} HxVBoxMediumInfo;

typedef struct HxVBoxMediumAttachmentEntry {
    char mediumId[128];
    char mediumName[256];
    char mediumType[64];
    char controllerId[128];
    char controllerName[256];
    char controllerType[64];
    unsigned int port;
    unsigned int device;
    struct HxVBoxMediumAttachmentEntry* next;
} HxVBoxMediumAttachmentEntry;

typedef struct HxVBoxMediumAttachmentInfo {
    int success;
    char mediumId[128];
    char mediumName[256];
    char mediumType[64];
    char controllerId[128];
    char controllerName[256];
    char controllerType[64];
    unsigned int port;
    unsigned int device;
    int errorCode;
    char errorMessage[1024];
} HxVBoxMediumAttachmentInfo;

typedef struct HxVBoxHostInfo {
    int success;
    char architecture[64];
    char domainName[256];
    unsigned int processorCount;
    unsigned int processorOnlineCount;
    unsigned int processorCoreCount;
    unsigned int processorOnlineCoreCount;
    unsigned int memorySize;
    unsigned int memoryAvailable;
    char operatingSystem[128];
    char osVersion[256];
    int utcTime;
    int errorCode;
    char errorMessage[1024];
} HxVBoxHostInfo;

typedef struct HxVBoxProcessorInfo {
    int success;
    unsigned int cpuId;
    unsigned int speedMHz;
    int online;
    int errorCode;
    char errorMessage[1024];
} HxVBoxProcessorInfo;

typedef struct HxVBoxResourceMetrics {
    int success;
    int64_t timestamp;
    float cpuUsagePercent;
    uint32_t memoryUsedMB;
    uint32_t cpuCount;
    uint32_t activeThreads;
    int errorCode;
    char errorMessage[1024];
} HxVBoxResourceMetrics;

typedef struct HxVBoxEvent {
    int success;
    char eventType[128];
    int64_t timestamp;
    char vmName[256];
    char description[1024];
    int errorCode;
    char errorMessage[1024];
} HxVBoxEvent;

typedef struct HxVBoxEventSubscription {
    int success;
    int64_t subscriptionId;
    int errorCode;
    char errorMessage[1024];
} HxVBoxEventSubscription;

typedef struct HxVBoxCloneResult {
    int success;
    char clonedMachineId[256];
    char clonedMachineName[256];
    int progressPercent;
    int errorCode;
    char errorMessage[1024];
} HxVBoxCloneResult;

void* hx_vbox_open(void);
void hx_vbox_close(void* ctx);
HxVBoxVersionInfo* hx_vbox_get_version_info(void* ctx);
HxVBoxMachineEntry* hx_vbox_list_machines(void* ctx);
HxVBoxMachineInfo* hx_vbox_find_machine(void* ctx, const char* nameOrId);
int hx_vbox_session_lock_machine(void* ctx, const char* nameOrId, int lockType);
int hx_vbox_session_unlock_machine(void* ctx);
int hx_vbox_session_get_state(void* ctx);
HxVBoxMachineInfo* hx_vbox_session_get_machine_info(void* ctx);
int hx_vbox_session_pause(void* ctx);
int hx_vbox_session_resume(void* ctx);
int hx_vbox_session_reset(void* ctx);
int hx_vbox_session_power_button(void* ctx);
int hx_vbox_session_power_down(void* ctx, int timeoutMs);
HxVBoxProgressInfo* hx_vbox_launch_vm_process(void* ctx, const char* nameOrId, const char* frontend, int timeoutMs);

// Machine configuration (session-based modification only)
int hx_vbox_session_set_memory_size(void* ctx, unsigned int memoryMB);
int hx_vbox_session_set_vcpu_count(void* ctx, unsigned int cpuCount);
int hx_vbox_session_set_boot_order(void* ctx, int device, int position);
int hx_vbox_session_save_settings(void* ctx);

// Snapshot operations (session-based)
HxVBoxSnapshotInfo* hx_vbox_session_create_snapshot(void* ctx, const char* name, const char* description);
HxVBoxSnapshotEntry* hx_vbox_session_list_snapshots(void* ctx);
HxVBoxSnapshotInfo* hx_vbox_session_find_snapshot(void* ctx, const char* snapshotIdOrName);
int hx_vbox_session_restore_snapshot(void* ctx, const char* snapshotIdOrName);
int hx_vbox_session_delete_snapshot(void* ctx, const char* snapshotIdOrName);

// Storage controller operations (session-based, requires Write lock)
HxVBoxStorageControllerEntry* hx_vbox_session_get_storage_controllers(void* ctx);
HxVBoxStorageControllerInfo* hx_vbox_session_add_storage_controller(void* ctx, const char* name, const char* controllerType);
int hx_vbox_session_remove_storage_controller(void* ctx, const char* name);

// Media operations
HxVBoxMediumInfo* hx_vbox_open_medium(void* ctx, const char* path);
int hx_vbox_close_medium(void* ctx, const char* mediumId);

// Medium attachment operations (session-based, requires Write lock)
HxVBoxMediumAttachmentEntry* hx_vbox_session_get_medium_attachments(void* ctx);
int hx_vbox_session_attach_medium(void* ctx, const char* mediumId, const char* controllerName, unsigned int port, unsigned int device);
int hx_vbox_session_detach_medium(void* ctx, const char* mediumId);

// Host information operations
HxVBoxHostInfo* hx_vbox_get_host_info(void* ctx);
HxVBoxProcessorInfo* hx_vbox_get_processor_info(void* ctx, unsigned int cpuId);

// Resource monitoring operations
HxVBoxResourceMetrics* hx_vbox_get_resource_metrics(void* ctx);

// Event operations
HxVBoxEventSubscription* hx_vbox_register_event_listener(void* ctx, const char* eventType);
int hx_vbox_unregister_event_listener(void* ctx, int64_t subscriptionId);
HxVBoxEvent* hx_vbox_poll_event(void* ctx, int64_t subscriptionId);
void hx_vbox_event_free(HxVBoxEvent* event);
void hx_vbox_event_subscription_free(HxVBoxEventSubscription* sub);

// Machine cloning operations
HxVBoxCloneResult* hx_vbox_clone_machine(void* ctx, const char* machineId, const char* targetName, const char* cloneMode, int cloneSnapshots);
void hx_vbox_clone_result_free(HxVBoxCloneResult* result);

void hx_vbox_machine_list_free(HxVBoxMachineEntry* list);
void hx_vbox_snapshot_list_free(HxVBoxSnapshotEntry* list);
void hx_vbox_storage_controller_list_free(HxVBoxStorageControllerEntry* list);
void hx_vbox_medium_list_free(HxVBoxMediumEntry* list);
void hx_vbox_medium_attachment_list_free(HxVBoxMediumAttachmentEntry* list);
HxVBoxErrorInfo* hx_vbox_get_last_error(void);

#ifdef __cplusplus
}
#endif

#endif

typedef struct HxVBoxNetworkAdapter {
    int success;
    int slot;
    char adapterType[64];
    char attachmentType[64];
    char networkName[256];
    char macAddress[64];
    int enabled;
    int cableConnected;
    int errorCode;
    char errorMessage[1024];
} HxVBoxNetworkAdapter;

typedef struct HxVBoxNetworkAdapterList {
    int success;
    int count;
    HxVBoxNetworkAdapter** adapters;
    int errorCode;
    char errorMessage[1024];
} HxVBoxNetworkAdapterList;

typedef struct HxVBoxVirtualNetwork {
    int success;
    char name[256];
    char networkCIDR[64];
    char broadcastAddress[64];
    int dhcpEnabled;
    char dhcpLowerIP[64];
    char dhcpUpperIP[64];
    char networkType[64];
    int errorCode;
    char errorMessage[1024];
} HxVBoxVirtualNetwork;

typedef struct HxVBoxVirtualNetworkList {
    int success;
    int count;
    HxVBoxVirtualNetwork** networks;
    int errorCode;
    char errorMessage[1024];
} HxVBoxVirtualNetworkList;

// Network operations
HxVBoxNetworkAdapterList* hx_vbox_get_network_adapters(void* ctx, const char* machineId);
HxVBoxNetworkAdapter* hx_vbox_set_network_adapter(void* ctx, const char* machineId, int slot, const char* adapterType, const char* attachmentType, const char* networkName);
HxVBoxVirtualNetworkList* hx_vbox_get_virtual_networks(void* ctx);
void hx_vbox_network_adapter_free(HxVBoxNetworkAdapter* adapter);
void hx_vbox_network_adapter_list_free(HxVBoxNetworkAdapterList* list);
void hx_vbox_virtual_network_free(HxVBoxVirtualNetwork* network);
void hx_vbox_virtual_network_list_free(HxVBoxVirtualNetworkList* list);

typedef struct HxVBoxRemoteDisplayInfo {
    int success;
    int rdpEnabled;
    int rdpPort;
    int vncEnabled;
    int vncPort;
    char vncAddress[256];
    int displayWidth;
    int displayHeight;
    int displayBitDepth;
    int guestResizableDisplay;
    char displayId[64];
    int errorCode;
    char errorMessage[1024];
} HxVBoxRemoteDisplayInfo;

typedef struct HxVBoxDisplayFrameBuffer {
    int success;
    int displayIndex;
    int width;
    int height;
    int bitsPerPixel;
    int bytesPerLine;
    char pixelFormat[64];
    char pixelDataPtr[64];
    int bufferSize;
    int isValid;
    int usesHardwareAcceleration;
    int isUpdating;
    int vSyncEnabled;
    int lastUpdateTime;
    int errorCode;
    char errorMessage[1024];
} HxVBoxDisplayFrameBuffer;

// Display operations
HxVBoxRemoteDisplayInfo* hx_vbox_get_remote_display_info(void* ctx, const char* machineId);
HxVBoxDisplayFrameBuffer* hx_vbox_get_display_framebuffer(void* ctx, const char* machineId, int displayIndex);
void hx_vbox_remote_display_info_free(HxVBoxRemoteDisplayInfo* info);
void hx_vbox_display_framebuffer_free(HxVBoxDisplayFrameBuffer* buffer);
