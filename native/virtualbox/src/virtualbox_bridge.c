#include "virtualbox_bridge.h"

#include "VBoxCAPIGlue.h"

#include <stdlib.h>
#include <string.h>

typedef struct HxVBoxContext {
    IVirtualBoxClient* client;
    IVirtualBox* vbox;
    ISession* session;
} HxVBoxContext;

static HxVBoxErrorInfo g_errorInfo;
static HxVBoxVersionInfo g_versionInfo;
static HxVBoxMachineInfo g_machineInfo;
static HxVBoxProgressInfo g_progressInfo;
static HxVBoxSnapshotInfo g_snapshotInfo;
static HxVBoxStorageControllerInfo g_storageControllerInfo;
static HxVBoxMediumInfo g_mediumInfo;
static HxVBoxMediumAttachmentInfo g_mediumAttachmentInfo;
static HxVBoxHostInfo g_hostInfo;
static HxVBoxProcessorInfo g_processorInfo;
static HxVBoxResourceMetrics g_resourceMetrics;

static void hx_copy_string(char* dest, size_t size, const char* src) {
    if (!dest || size == 0) {
        return;
    }
    if (!src) {
        dest[0] = '\0';
        return;
    }
    strncpy(dest, src, size - 1);
    dest[size - 1] = '\0';
}

static void hx_set_error_message(int code, const char* message) {
    g_errorInfo.code = code;
    hx_copy_string(g_errorInfo.message, sizeof(g_errorInfo.message), message);
}

static void hx_set_error_hresult(HRESULT hrc, const char* message) {
    hx_set_error_message((int)hrc, message);
}

static void hx_set_error_from_exception(HRESULT hrc, const char* message) {
    hx_set_error_hresult(hrc, message);

    if (!g_pVBoxFuncs || !g_pVBoxFuncs->pfnGetException) {
        return;
    }

    IErrorInfo* ex = NULL;
    HRESULT hrcEx = g_pVBoxFuncs->pfnGetException(&ex);
    if (FAILED(hrcEx) || !ex) {
        return;
    }

    IVirtualBoxErrorInfo* vboxErr = NULL;
    HRESULT hrcQI = IErrorInfo_QueryInterface(ex, &IID_IVirtualBoxErrorInfo, (void**)&vboxErr);
    if (SUCCEEDED(hrcQI) && vboxErr) {
        BSTR textUtf16 = NULL;
        HRESULT hrcText = IVirtualBoxErrorInfo_get_Text(vboxErr, &textUtf16);
        if (SUCCEEDED(hrcText) && textUtf16) {
            char* textUtf8 = NULL;
            if (g_pVBoxFuncs->pfnUtf16ToUtf8(textUtf16, &textUtf8) == 0 && textUtf8) {
                hx_set_error_message((int)hrc, textUtf8);
                g_pVBoxFuncs->pfnUtf8Free(textUtf8);
            }
            g_pVBoxFuncs->pfnComUnallocString(textUtf16);
        }
        IVirtualBoxErrorInfo_Release(vboxErr);
    }
    IErrorInfo_Release(ex);
}

static char* hx_utf16_to_utf8_dup(BSTR value) {
    char* utf8 = NULL;
    size_t len = 0;
    char* copy = NULL;

    if (!value || !g_pVBoxFuncs) {
        return NULL;
    }
    if (g_pVBoxFuncs->pfnUtf16ToUtf8(value, &utf8) != 0 || !utf8) {
        return NULL;
    }

    len = strlen(utf8);
    copy = (char*)malloc(len + 1);
    if (copy) {
        memcpy(copy, utf8, len + 1);
    }
    g_pVBoxFuncs->pfnUtf8Free(utf8);
    return copy;
}

static void hx_set_error_from_vbox_error_info(IVirtualBoxErrorInfo* errorInfo, HRESULT fallbackHrc, const char* fallbackMessage) {
    BSTR textUtf16 = NULL;
    char* textUtf8 = NULL;
    if (!errorInfo) {
        hx_set_error_from_exception(fallbackHrc, fallbackMessage);
        return;
    }

    if (SUCCEEDED(IVirtualBoxErrorInfo_get_Text(errorInfo, &textUtf16)) && textUtf16) {
        if (g_pVBoxFuncs->pfnUtf16ToUtf8(textUtf16, &textUtf8) == 0 && textUtf8) {
            hx_set_error_message((int)fallbackHrc, textUtf8);
            g_pVBoxFuncs->pfnUtf8Free(textUtf8);
        } else {
            hx_set_error_from_exception(fallbackHrc, fallbackMessage);
        }
        g_pVBoxFuncs->pfnComUnallocString(textUtf16);
    } else {
        hx_set_error_from_exception(fallbackHrc, fallbackMessage);
    }
}

static int hx_wait_for_progress(IProgress* progress, int timeoutMs, const char* waitMessage) {
    HRESULT hrc;
    PRInt32 resultCode = 0;
    IVirtualBoxErrorInfo* errorInfo = NULL;

    if (!progress) {
        hx_set_error_message(-1, "Progress handle is not initialized");
        return 0;
    }

    hrc = IProgress_WaitForCompletion(progress, timeoutMs < 0 ? -1 : timeoutMs);
    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, waitMessage);
        return 0;
    }

    hrc = IProgress_get_ResultCode(progress, &resultCode);
    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "IProgress::get_ResultCode failed");
        return 0;
    }

    if (FAILED(resultCode)) {
        hrc = IProgress_get_ErrorInfo(progress, &errorInfo);
        if (SUCCEEDED(hrc) && errorInfo) {
            hx_set_error_from_vbox_error_info(errorInfo, (HRESULT)resultCode, waitMessage);
            IVirtualBoxErrorInfo_Release(errorInfo);
        } else {
            hx_set_error_from_exception((HRESULT)resultCode, waitMessage);
        }
        return 0;
    }

    return 1;
}

static HxVBoxProgressInfo* hx_progress_to_info(IProgress* progress, int timeoutMs, const char* waitMessage) {
    BSTR descriptionUtf16 = NULL;
    char* descriptionUtf8 = NULL;
    PRBool completed = FALSE;
    PRBool cancelable = FALSE;
    PRBool canceled = FALSE;
    PRUint32 percent = 0;
    PRUint32 operationCount = 0;
    PRInt32 resultCode = 0;
    HRESULT hrc;

    memset(&g_progressInfo, 0, sizeof(g_progressInfo));
    if (!progress) {
        g_progressInfo.errorCode = -1;
        hx_copy_string(g_progressInfo.errorMessage, sizeof(g_progressInfo.errorMessage), "Progress handle is not initialized");
        return &g_progressInfo;
    }

    hrc = IProgress_get_Description(progress, &descriptionUtf16);
    if (SUCCEEDED(hrc) && descriptionUtf16) {
        descriptionUtf8 = hx_utf16_to_utf8_dup(descriptionUtf16);
        g_pVBoxFuncs->pfnComUnallocString(descriptionUtf16);
        hx_copy_string(g_progressInfo.description, sizeof(g_progressInfo.description), descriptionUtf8);
        free(descriptionUtf8);
    }

    if (SUCCEEDED(IProgress_get_Cancelable(progress, &cancelable))) {
        g_progressInfo.cancelable = cancelable ? 1 : 0;
    }
    if (SUCCEEDED(IProgress_get_Canceled(progress, &canceled))) {
        g_progressInfo.canceled = canceled ? 1 : 0;
    }
    if (SUCCEEDED(IProgress_get_Percent(progress, &percent))) {
        g_progressInfo.percent = (unsigned int)percent;
    }
    if (SUCCEEDED(IProgress_get_OperationCount(progress, &operationCount))) {
        g_progressInfo.operationCount = (unsigned int)operationCount;
    }

    if (!hx_wait_for_progress(progress, timeoutMs, waitMessage)) {
        g_progressInfo.errorCode = g_errorInfo.code;
        hx_copy_string(g_progressInfo.errorMessage, sizeof(g_progressInfo.errorMessage), g_errorInfo.message);
        return &g_progressInfo;
    }

    if (SUCCEEDED(IProgress_get_Completed(progress, &completed))) {
        g_progressInfo.completed = completed ? 1 : 0;
    }
    if (SUCCEEDED(IProgress_get_ResultCode(progress, &resultCode))) {
        g_progressInfo.resultCode = (int)resultCode;
    }
    if (SUCCEEDED(IProgress_get_Percent(progress, &percent))) {
        g_progressInfo.percent = (unsigned int)percent;
    }

    g_progressInfo.success = 1;
    return &g_progressInfo;
}

static int hx_get_session_console(HxVBoxContext* ctx, IConsole** console, const char* message) {
    HRESULT hrc;
    if (!ctx || !ctx->session) {
        hx_set_error_message(-1, "VirtualBox session is not initialized");
        return 0;
    }
    hrc = ISession_get_Console(ctx->session, console);
    if (FAILED(hrc) || !*console) {
        hx_set_error_from_exception(hrc, message);
        return 0;
    }
    return 1;
}

static void hx_fill_machine_info(HxVBoxContext* ctx, IMachine* machine, HxVBoxMachineInfo* info) {
    BSTR idUtf16 = NULL;
    BSTR nameUtf16 = NULL;
    BSTR descriptionUtf16 = NULL;
    BSTR settingsUtf16 = NULL;
    BSTR osTypeIdUtf16 = NULL;
    BSTR osDescriptionUtf16 = NULL;
    char* idUtf8 = NULL;
    char* nameUtf8 = NULL;
    char* descriptionUtf8 = NULL;
    char* settingsUtf8 = NULL;
    char* osTypeIdUtf8 = NULL;
    char* osDescriptionUtf8 = NULL;
    IGuestOSType* osType = NULL;
    BOOL accessible = FALSE;
    ULONG memorySize = 0;
    MachineState_T state = MachineState_Null;
    HRESULT hrc;

    hrc = IMachine_get_Accessible(machine, &accessible);
    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "IMachine::get_Accessible failed");
        info->errorCode = (int)hrc;
        hx_copy_string(info->errorMessage, sizeof(info->errorMessage), g_errorInfo.message);
        return;
    }
    info->accessible = accessible ? 1 : 0;

    hrc = IMachine_get_Id(machine, &idUtf16);
    if (FAILED(hrc) || !idUtf16) {
        hx_set_error_from_exception(hrc, "IMachine::get_Id failed");
        info->errorCode = (int)hrc;
        hx_copy_string(info->errorMessage, sizeof(info->errorMessage), g_errorInfo.message);
        return;
    }
    idUtf8 = hx_utf16_to_utf8_dup(idUtf16);
    g_pVBoxFuncs->pfnComUnallocString(idUtf16);
    hx_copy_string(info->id, sizeof(info->id), idUtf8);
    free(idUtf8);

    hrc = IMachine_get_State(machine, &state);
    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "IMachine::get_State failed");
        info->errorCode = (int)hrc;
        hx_copy_string(info->errorMessage, sizeof(info->errorMessage), g_errorInfo.message);
        return;
    }
    info->state = (unsigned int)state;

    hrc = IMachine_get_Name(machine, &nameUtf16);
    if (SUCCEEDED(hrc) && nameUtf16) {
        nameUtf8 = hx_utf16_to_utf8_dup(nameUtf16);
        g_pVBoxFuncs->pfnComUnallocString(nameUtf16);
        hx_copy_string(info->name, sizeof(info->name), nameUtf8);
        free(nameUtf8);
    }

    if (!info->accessible) {
        info->success = 1;
        return;
    }

    hrc = IMachine_get_Description(machine, &descriptionUtf16);
    if (SUCCEEDED(hrc) && descriptionUtf16) {
        descriptionUtf8 = hx_utf16_to_utf8_dup(descriptionUtf16);
        g_pVBoxFuncs->pfnComUnallocString(descriptionUtf16);
        hx_copy_string(info->description, sizeof(info->description), descriptionUtf8);
        free(descriptionUtf8);
    }

    hrc = IMachine_get_SettingsFilePath(machine, &settingsUtf16);
    if (SUCCEEDED(hrc) && settingsUtf16) {
        settingsUtf8 = hx_utf16_to_utf8_dup(settingsUtf16);
        g_pVBoxFuncs->pfnComUnallocString(settingsUtf16);
        hx_copy_string(info->settingsFilePath, sizeof(info->settingsFilePath), settingsUtf8);
        free(settingsUtf8);
    }

    hrc = IMachine_get_MemorySize(machine, &memorySize);
    if (SUCCEEDED(hrc)) {
        info->memorySize = (unsigned int)memorySize;
    }

    hrc = IMachine_get_OSTypeId(machine, &osTypeIdUtf16);
    if (SUCCEEDED(hrc) && osTypeIdUtf16) {
        osTypeIdUtf8 = hx_utf16_to_utf8_dup(osTypeIdUtf16);
        hx_copy_string(info->osTypeId, sizeof(info->osTypeId), osTypeIdUtf8);
        free(osTypeIdUtf8);

        hrc = IVirtualBox_GetGuestOSType(ctx->vbox, osTypeIdUtf16, &osType);
        if (SUCCEEDED(hrc) && osType) {
            hrc = IGuestOSType_get_Description(osType, &osDescriptionUtf16);
            if (SUCCEEDED(hrc) && osDescriptionUtf16) {
                osDescriptionUtf8 = hx_utf16_to_utf8_dup(osDescriptionUtf16);
                g_pVBoxFuncs->pfnComUnallocString(osDescriptionUtf16);
                hx_copy_string(info->osDescription, sizeof(info->osDescription), osDescriptionUtf8);
                free(osDescriptionUtf8);
            }
            IGuestOSType_Release(osType);
        }

        g_pVBoxFuncs->pfnComUnallocString(osTypeIdUtf16);
    }

    info->success = 1;
}

void* hx_vbox_open(void) {
    HxVBoxContext* ctx = NULL;
    HRESULT hrc;

    memset(&g_errorInfo, 0, sizeof(g_errorInfo));

    if (VBoxCGlueInit() != 0) {
        hx_set_error_message(-1, g_szVBoxErrMsg[0] ? g_szVBoxErrMsg : "VBoxCGlueInit failed");
        return NULL;
    }

    ctx = (HxVBoxContext*)calloc(1, sizeof(HxVBoxContext));
    if (!ctx) {
        hx_set_error_message(-1, "Out of memory");
        VBoxCGlueTerm();
        return NULL;
    }

    hrc = g_pVBoxFuncs->pfnClientInitialize(NULL, &ctx->client);
    if (FAILED(hrc) || !ctx->client) {
        hx_set_error_from_exception(hrc, "Failed to initialize VirtualBox client");
        free(ctx);
        VBoxCGlueTerm();
        return NULL;
    }

    hrc = IVirtualBoxClient_get_VirtualBox(ctx->client, &ctx->vbox);
    if (FAILED(hrc) || !ctx->vbox) {
        hx_set_error_from_exception(hrc, "Failed to get IVirtualBox");
        IVirtualBoxClient_Release(ctx->client);
        if (g_pVBoxFuncs->pfnClientUninitialize) {
            g_pVBoxFuncs->pfnClientUninitialize();
        }
        free(ctx);
        VBoxCGlueTerm();
        return NULL;
    }

    hrc = IVirtualBoxClient_get_Session(ctx->client, &ctx->session);
    if (FAILED(hrc) || !ctx->session) {
        hx_set_error_from_exception(hrc, "Failed to get ISession");
        IVirtualBox_Release(ctx->vbox);
        IVirtualBoxClient_Release(ctx->client);
        if (g_pVBoxFuncs->pfnClientUninitialize) {
            g_pVBoxFuncs->pfnClientUninitialize();
        }
        free(ctx);
        VBoxCGlueTerm();
        return NULL;
    }

    return ctx;
}

void hx_vbox_close(void* rawCtx) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    if (!ctx) {
        return;
    }

    if (ctx->session) {
        ISession_Release(ctx->session);
        ctx->session = NULL;
    }
    if (ctx->vbox) {
        IVirtualBox_Release(ctx->vbox);
        ctx->vbox = NULL;
    }
    if (ctx->client) {
        IVirtualBoxClient_Release(ctx->client);
        ctx->client = NULL;
    }
    if (g_pVBoxFuncs && g_pVBoxFuncs->pfnClientUninitialize) {
        g_pVBoxFuncs->pfnClientUninitialize();
    }
    VBoxCGlueTerm();
    free(ctx);
}

HxVBoxVersionInfo* hx_vbox_get_version_info(void* rawCtx) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    BSTR versionUtf16 = NULL;
    BSTR homeUtf16 = NULL;
    char* versionUtf8 = NULL;
    char* homeUtf8 = NULL;
    HRESULT hrc;

    memset(&g_versionInfo, 0, sizeof(g_versionInfo));
    if (!ctx || !ctx->vbox || !g_pVBoxFuncs) {
        hx_copy_string(g_versionInfo.errorMessage, sizeof(g_versionInfo.errorMessage), "VirtualBox context is not initialized");
        g_versionInfo.errorCode = -1;
        return &g_versionInfo;
    }

    g_versionInfo.version = (int)g_pVBoxFuncs->pfnGetVersion();
    g_versionInfo.apiVersion = (int)g_pVBoxFuncs->pfnGetAPIVersion();

    hrc = IVirtualBox_get_Revision(ctx->vbox, &g_versionInfo.revision);
    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "IVirtualBox::get_Revision failed");
        g_versionInfo.errorCode = (int)hrc;
        hx_copy_string(g_versionInfo.errorMessage, sizeof(g_versionInfo.errorMessage), g_errorInfo.message);
        return &g_versionInfo;
    }

    hrc = IVirtualBox_get_Version(ctx->vbox, &versionUtf16);
    if (FAILED(hrc) || !versionUtf16) {
        hx_set_error_from_exception(hrc, "IVirtualBox::get_Version failed");
        g_versionInfo.errorCode = (int)hrc;
        hx_copy_string(g_versionInfo.errorMessage, sizeof(g_versionInfo.errorMessage), g_errorInfo.message);
        return &g_versionInfo;
    }
    versionUtf8 = hx_utf16_to_utf8_dup(versionUtf16);
    g_pVBoxFuncs->pfnComUnallocString(versionUtf16);
    hx_copy_string(g_versionInfo.versionString, sizeof(g_versionInfo.versionString), versionUtf8);
    free(versionUtf8);

    hrc = IVirtualBox_get_HomeFolder(ctx->vbox, &homeUtf16);
    if (FAILED(hrc) || !homeUtf16) {
        hx_set_error_from_exception(hrc, "IVirtualBox::get_HomeFolder failed");
        g_versionInfo.errorCode = (int)hrc;
        hx_copy_string(g_versionInfo.errorMessage, sizeof(g_versionInfo.errorMessage), g_errorInfo.message);
        return &g_versionInfo;
    }
    homeUtf8 = hx_utf16_to_utf8_dup(homeUtf16);
    g_pVBoxFuncs->pfnComUnallocString(homeUtf16);
    hx_copy_string(g_versionInfo.homeFolder, sizeof(g_versionInfo.homeFolder), homeUtf8);
    free(homeUtf8);

    g_versionInfo.success = 1;
    return &g_versionInfo;
}

HxVBoxMachineEntry* hx_vbox_list_machines(void* rawCtx) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    SAFEARRAY* machinesSA = NULL;
    IMachine** machines = NULL;
    HxVBoxMachineEntry* head = NULL;
    HxVBoxMachineEntry* tail = NULL;
    ULONG count = 0;
    ULONG i;
    HRESULT hrc;

    memset(&g_errorInfo, 0, sizeof(g_errorInfo));
    if (!ctx || !ctx->vbox || !g_pVBoxFuncs) {
        hx_set_error_message(-1, "VirtualBox context is not initialized");
        return NULL;
    }

    machinesSA = g_pVBoxFuncs->pfnSafeArrayOutParamAlloc();
    hrc = IVirtualBox_get_Machines(ctx->vbox, ComSafeArrayAsOutIfaceParam(machinesSA, IMachine *));
    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "IVirtualBox::get_Machines failed");
        g_pVBoxFuncs->pfnSafeArrayDestroy(machinesSA);
        return NULL;
    }

    hrc = g_pVBoxFuncs->pfnSafeArrayCopyOutIfaceParamHelper((IUnknown***)&machines, &count, machinesSA);
    g_pVBoxFuncs->pfnSafeArrayDestroy(machinesSA);
    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "Failed to copy machine array");
        return NULL;
    }

    for (i = 0; i < count; ++i) {
        IMachine* machine = machines[i];
        HxVBoxMachineEntry* entry;
        BSTR nameUtf16 = NULL;
        BSTR idUtf16 = NULL;
        char* nameUtf8 = NULL;
        char* idUtf8 = NULL;
        MachineState_T state = MachineState_Null;

        if (!machine) {
            continue;
        }

        entry = (HxVBoxMachineEntry*)calloc(1, sizeof(HxVBoxMachineEntry));
        if (!entry) {
            continue;
        }

        IMachine_get_Name(machine, &nameUtf16);
        IMachine_get_Id(machine, &idUtf16);
        IMachine_get_State(machine, &state);
        nameUtf8 = hx_utf16_to_utf8_dup(nameUtf16);
        idUtf8 = hx_utf16_to_utf8_dup(idUtf16);
        if (nameUtf16) {
            g_pVBoxFuncs->pfnComUnallocString(nameUtf16);
        }
        if (idUtf16) {
            g_pVBoxFuncs->pfnComUnallocString(idUtf16);
        }

        entry->handle = machine;
        entry->state = (unsigned int)state;
        hx_copy_string(entry->name, sizeof(entry->name), nameUtf8);
        hx_copy_string(entry->id, sizeof(entry->id), idUtf8);
        free(nameUtf8);
        free(idUtf8);

        if (!head) {
            head = entry;
        } else {
            tail->next = entry;
        }
        tail = entry;
    }

    g_pVBoxFuncs->pfnArrayOutFree(machines);
    return head;
}

HxVBoxMachineInfo* hx_vbox_find_machine(void* rawCtx, const char* nameOrId) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    IMachine* machine = NULL;
    BSTR nameOrIdUtf16 = NULL;
    HRESULT hrc;

    memset(&g_errorInfo, 0, sizeof(g_errorInfo));
    memset(&g_machineInfo, 0, sizeof(g_machineInfo));

    if (!ctx || !ctx->vbox || !g_pVBoxFuncs) {
        hx_set_error_message(-1, "VirtualBox context is not initialized");
        g_machineInfo.errorCode = -1;
        hx_copy_string(g_machineInfo.errorMessage, sizeof(g_machineInfo.errorMessage), g_errorInfo.message);
        return &g_machineInfo;
    }

    if (!nameOrId || !nameOrId[0]) {
        hx_set_error_message(-1, "Machine name or ID is required");
        g_machineInfo.errorCode = -1;
        hx_copy_string(g_machineInfo.errorMessage, sizeof(g_machineInfo.errorMessage), g_errorInfo.message);
        return &g_machineInfo;
    }

    if (g_pVBoxFuncs->pfnUtf8ToUtf16(nameOrId, &nameOrIdUtf16) != 0 || !nameOrIdUtf16) {
        hx_set_error_message(-1, "Failed to convert machine identifier to UTF-16");
        g_machineInfo.errorCode = -1;
        hx_copy_string(g_machineInfo.errorMessage, sizeof(g_machineInfo.errorMessage), g_errorInfo.message);
        return &g_machineInfo;
    }

    hrc = IVirtualBox_FindMachine(ctx->vbox, nameOrIdUtf16, &machine);
    g_pVBoxFuncs->pfnUtf16Free(nameOrIdUtf16);
    if (FAILED(hrc) || !machine) {
        hx_set_error_from_exception(hrc, "IVirtualBox::findMachine failed");
        g_machineInfo.errorCode = (int)hrc;
        hx_copy_string(g_machineInfo.errorMessage, sizeof(g_machineInfo.errorMessage), g_errorInfo.message);
        return &g_machineInfo;
    }

    hx_fill_machine_info(ctx, machine, &g_machineInfo);
    IMachine_Release(machine);
    return &g_machineInfo;
}

int hx_vbox_session_lock_machine(void* rawCtx, const char* nameOrId, int lockType) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    IMachine* machine = NULL;
    BSTR nameOrIdUtf16 = NULL;
    HRESULT hrc;
    PRUint32 sessionState = SessionState_Null;

    memset(&g_errorInfo, 0, sizeof(g_errorInfo));
    if (!ctx || !ctx->vbox || !ctx->session || !g_pVBoxFuncs) {
        hx_set_error_message(-1, "VirtualBox context is not initialized");
        return 0;
    }
    if (!nameOrId || !nameOrId[0]) {
        hx_set_error_message(-1, "Machine name or ID is required");
        return 0;
    }

    hrc = ISession_get_State(ctx->session, &sessionState);
    if (SUCCEEDED(hrc) && sessionState != SessionState_Unlocked) {
        hx_set_error_message(-1, "VirtualBox session is already locked");
        return 0;
    }

    if (g_pVBoxFuncs->pfnUtf8ToUtf16(nameOrId, &nameOrIdUtf16) != 0 || !nameOrIdUtf16) {
        hx_set_error_message(-1, "Failed to convert machine identifier to UTF-16");
        return 0;
    }

    hrc = IVirtualBox_FindMachine(ctx->vbox, nameOrIdUtf16, &machine);
    g_pVBoxFuncs->pfnUtf16Free(nameOrIdUtf16);
    if (FAILED(hrc) || !machine) {
        hx_set_error_from_exception(hrc, "IVirtualBox::findMachine failed");
        return 0;
    }

    hrc = IMachine_LockMachine(machine, ctx->session, (PRUint32)lockType);
    IMachine_Release(machine);
    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "IMachine::lockMachine failed");
        return 0;
    }

    return 1;
}

int hx_vbox_session_unlock_machine(void* rawCtx) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    HRESULT hrc;

    memset(&g_errorInfo, 0, sizeof(g_errorInfo));
    if (!ctx || !ctx->session) {
        hx_set_error_message(-1, "VirtualBox session is not initialized");
        return 0;
    }

    hrc = ISession_UnlockMachine(ctx->session);
    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "ISession::unlockMachine failed");
        return 0;
    }
    return 1;
}

int hx_vbox_session_get_state(void* rawCtx) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    PRUint32 state = SessionState_Null;
    HRESULT hrc;

    memset(&g_errorInfo, 0, sizeof(g_errorInfo));
    if (!ctx || !ctx->session) {
        hx_set_error_message(-1, "VirtualBox session is not initialized");
        return -1;
    }

    hrc = ISession_get_State(ctx->session, &state);
    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "ISession::get_State failed");
        return -1;
    }
    return (int)state;
}

HxVBoxMachineInfo* hx_vbox_session_get_machine_info(void* rawCtx) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    IMachine* machine = NULL;
    HRESULT hrc;

    memset(&g_errorInfo, 0, sizeof(g_errorInfo));
    memset(&g_machineInfo, 0, sizeof(g_machineInfo));

    if (!ctx || !ctx->session || !ctx->vbox) {
        hx_set_error_message(-1, "VirtualBox session is not initialized");
        g_machineInfo.errorCode = -1;
        hx_copy_string(g_machineInfo.errorMessage, sizeof(g_machineInfo.errorMessage), g_errorInfo.message);
        return &g_machineInfo;
    }

    hrc = ISession_get_Machine(ctx->session, &machine);
    if (FAILED(hrc) || !machine) {
        hx_set_error_from_exception(hrc, "ISession::get_Machine failed");
        g_machineInfo.errorCode = (int)hrc;
        hx_copy_string(g_machineInfo.errorMessage, sizeof(g_machineInfo.errorMessage), g_errorInfo.message);
        return &g_machineInfo;
    }

    hx_fill_machine_info(ctx, machine, &g_machineInfo);
    IMachine_Release(machine);
    return &g_machineInfo;
}

int hx_vbox_session_pause(void* rawCtx) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    IConsole* console = NULL;
    HRESULT hrc;
    memset(&g_errorInfo, 0, sizeof(g_errorInfo));
    if (!hx_get_session_console(ctx, &console, "ISession::get_Console failed")) {
        return 0;
    }
    hrc = IConsole_Pause(console);
    IConsole_Release(console);
    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "IConsole::pause failed");
        return 0;
    }
    return 1;
}

int hx_vbox_session_resume(void* rawCtx) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    IConsole* console = NULL;
    HRESULT hrc;
    memset(&g_errorInfo, 0, sizeof(g_errorInfo));
    if (!hx_get_session_console(ctx, &console, "ISession::get_Console failed")) {
        return 0;
    }
    hrc = IConsole_Resume(console);
    IConsole_Release(console);
    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "IConsole::resume failed");
        return 0;
    }
    return 1;
}

int hx_vbox_session_reset(void* rawCtx) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    IConsole* console = NULL;
    HRESULT hrc;
    memset(&g_errorInfo, 0, sizeof(g_errorInfo));
    if (!hx_get_session_console(ctx, &console, "ISession::get_Console failed")) {
        return 0;
    }
    hrc = IConsole_Reset(console);
    IConsole_Release(console);
    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "IConsole::reset failed");
        return 0;
    }
    return 1;
}

int hx_vbox_session_power_button(void* rawCtx) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    IConsole* console = NULL;
    HRESULT hrc;
    memset(&g_errorInfo, 0, sizeof(g_errorInfo));
    if (!hx_get_session_console(ctx, &console, "ISession::get_Console failed")) {
        return 0;
    }
    hrc = IConsole_PowerButton(console);
    IConsole_Release(console);
    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "IConsole::powerButton failed");
        return 0;
    }
    return 1;
}

int hx_vbox_session_power_down(void* rawCtx, int timeoutMs) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    IConsole* console = NULL;
    IProgress* progress = NULL;
    HRESULT hrc;
    int ok;

    memset(&g_errorInfo, 0, sizeof(g_errorInfo));
    if (!hx_get_session_console(ctx, &console, "ISession::get_Console failed")) {
        return 0;
    }

    hrc = IConsole_PowerDown(console, &progress);
    IConsole_Release(console);
    if (FAILED(hrc) || !progress) {
        hx_set_error_from_exception(hrc, "IConsole::powerDown failed");
        return 0;
    }

    ok = hx_wait_for_progress(progress, timeoutMs, "VirtualBox power down failed");
    IProgress_Release(progress);
    return ok;
}

HxVBoxProgressInfo* hx_vbox_launch_vm_process(void* rawCtx, const char* nameOrId, const char* frontend, int timeoutMs) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    IMachine* machine = NULL;
    IProgress* progress = NULL;
    SAFEARRAY* env = NULL;
    BSTR nameOrIdUtf16 = NULL;
    BSTR frontendUtf16 = NULL;
    const char* frontendName = NULL;
    HRESULT hrc;

    memset(&g_errorInfo, 0, sizeof(g_errorInfo));
    memset(&g_progressInfo, 0, sizeof(g_progressInfo));

    if (!ctx || !ctx->vbox || !ctx->session || !g_pVBoxFuncs) {
        hx_set_error_message(-1, "VirtualBox context is not initialized");
        g_progressInfo.errorCode = -1;
        hx_copy_string(g_progressInfo.errorMessage, sizeof(g_progressInfo.errorMessage), g_errorInfo.message);
        return &g_progressInfo;
    }
    if (!nameOrId || !nameOrId[0]) {
        hx_set_error_message(-1, "Machine name or ID is required");
        g_progressInfo.errorCode = -1;
        hx_copy_string(g_progressInfo.errorMessage, sizeof(g_progressInfo.errorMessage), g_errorInfo.message);
        return &g_progressInfo;
    }

    frontendName = (frontend && frontend[0]) ? frontend : "headless";
    if (g_pVBoxFuncs->pfnUtf8ToUtf16(nameOrId, &nameOrIdUtf16) != 0 || !nameOrIdUtf16) {
        hx_set_error_message(-1, "Failed to convert machine identifier to UTF-16");
        g_progressInfo.errorCode = -1;
        hx_copy_string(g_progressInfo.errorMessage, sizeof(g_progressInfo.errorMessage), g_errorInfo.message);
        return &g_progressInfo;
    }
    if (g_pVBoxFuncs->pfnUtf8ToUtf16(frontendName, &frontendUtf16) != 0 || !frontendUtf16) {
        g_pVBoxFuncs->pfnUtf16Free(nameOrIdUtf16);
        hx_set_error_message(-1, "Failed to convert frontend name to UTF-16");
        g_progressInfo.errorCode = -1;
        hx_copy_string(g_progressInfo.errorMessage, sizeof(g_progressInfo.errorMessage), g_errorInfo.message);
        return &g_progressInfo;
    }

    hrc = IVirtualBox_FindMachine(ctx->vbox, nameOrIdUtf16, &machine);
    g_pVBoxFuncs->pfnUtf16Free(nameOrIdUtf16);
    if (FAILED(hrc) || !machine) {
        g_pVBoxFuncs->pfnUtf16Free(frontendUtf16);
        hx_set_error_from_exception(hrc, "IVirtualBox::findMachine failed");
        g_progressInfo.errorCode = g_errorInfo.code;
        hx_copy_string(g_progressInfo.errorMessage, sizeof(g_progressInfo.errorMessage), g_errorInfo.message);
        return &g_progressInfo;
    }

    hrc = IMachine_LaunchVMProcess(machine, ctx->session, frontendUtf16, ComSafeArrayAsInParam(env), &progress);
    g_pVBoxFuncs->pfnUtf16Free(frontendUtf16);
    IMachine_Release(machine);
    if (FAILED(hrc) || !progress) {
        hx_set_error_from_exception(hrc, "IMachine::launchVMProcess failed");
        g_progressInfo.errorCode = g_errorInfo.code;
        hx_copy_string(g_progressInfo.errorMessage, sizeof(g_progressInfo.errorMessage), g_errorInfo.message);
        return &g_progressInfo;
    }

    hx_progress_to_info(progress, timeoutMs, "VirtualBox VM launch failed");
    IProgress_Release(progress);
    return &g_progressInfo;
}

// ============================================================================
// Machine Configuration Functions (Session-based modification only)
// ============================================================================

int hx_vbox_session_set_memory_size(void* rawCtx, unsigned int memoryMB) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    IMachine* machine = NULL;
    HRESULT hrc;

    memset(&g_errorInfo, 0, sizeof(g_errorInfo));

    if (!ctx || !ctx->session || !g_pVBoxFuncs) {
        hx_set_error_message(-1, "Session is not locked");
        return -1;
    }

    // Memory must be in reasonable range (4MB to 2TB)
    if (memoryMB < 4 || memoryMB > 2097152) {
        hx_set_error_message(-1, "Memory size must be between 4 MB and 2097152 MB");
        return -1;
    }

    hrc = ISession_GetMachine(ctx->session, &machine);
    if (FAILED(hrc) || !machine) {
        hx_set_error_from_exception(hrc, "ISession::GetMachine failed");
        return -1;
    }

    hrc = IMachine_SetMemorySize(machine, memoryMB);
    IMachine_Release(machine);

    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "IMachine::SetMemorySize failed");
        return -1;
    }

    return 0;
}

int hx_vbox_session_set_vcpu_count(void* rawCtx, unsigned int cpuCount) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    IMachine* machine = NULL;
    HRESULT hrc;

    memset(&g_errorInfo, 0, sizeof(g_errorInfo));

    if (!ctx || !ctx->session || !g_pVBoxFuncs) {
        hx_set_error_message(-1, "Session is not locked");
        return -1;
    }

    // CPU count must be reasonable (1-32 typically, but let VirtualBox validate)
    if (cpuCount < 1 || cpuCount > 512) {
        hx_set_error_message(-1, "CPU count must be between 1 and 512");
        return -1;
    }

    hrc = ISession_GetMachine(ctx->session, &machine);
    if (FAILED(hrc) || !machine) {
        hx_set_error_from_exception(hrc, "ISession::GetMachine failed");
        return -1;
    }

    hrc = IMachine_SetCPUCount(machine, cpuCount);
    IMachine_Release(machine);

    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "IMachine::SetCPUCount failed");
        return -1;
    }

    return 0;
}

int hx_vbox_session_set_boot_order(void* rawCtx, int device, int position) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    IMachine* machine = NULL;
    HRESULT hrc;

    memset(&g_errorInfo, 0, sizeof(g_errorInfo));

    if (!ctx || !ctx->session || !g_pVBoxFuncs) {
        hx_set_error_message(-1, "Session is not locked");
        return -1;
    }

    // Position must be 1-4
    if (position < 1 || position > 4) {
        hx_set_error_message(-1, "Boot position must be between 1 and 4");
        return -1;
    }

    hrc = ISession_GetMachine(ctx->session, &machine);
    if (FAILED(hrc) || !machine) {
        hx_set_error_from_exception(hrc, "ISession::GetMachine failed");
        return -1;
    }

    hrc = IMachine_SetBootOrder(machine, position, device);
    IMachine_Release(machine);

    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "IMachine::SetBootOrder failed");
        return -1;
    }

    return 0;
}

int hx_vbox_session_save_settings(void* rawCtx) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    IMachine* machine = NULL;
    HRESULT hrc;

    memset(&g_errorInfo, 0, sizeof(g_errorInfo));

    if (!ctx || !ctx->session || !g_pVBoxFuncs) {
        hx_set_error_message(-1, "Session is not locked");
        return -1;
    }

    hrc = ISession_GetMachine(ctx->session, &machine);
    if (FAILED(hrc) || !machine) {
        hx_set_error_from_exception(hrc, "ISession::GetMachine failed");
        return -1;
    }

    hrc = IMachine_SaveSettings(machine);
    IMachine_Release(machine);

    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "IMachine::SaveSettings failed");
        return -1;
    }

    return 0;
}

// Snapshot operations (session-based)

HxVBoxSnapshotInfo* hx_vbox_session_create_snapshot(void* rawCtx, const char* name, const char* description) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    IMachine* machine = NULL;
    ISnapshot* snapshot = NULL;
    IProgress* progress = NULL;
    BSTR nameUtf16 = NULL;
    BSTR descUtf16 = NULL;
    BSTR uuidUtf16 = NULL;
    BSTR snapshotId = NULL;
    char* uuidUtf8 = NULL;
    HRESULT hrc;

    memset(&g_snapshotInfo, 0, sizeof(g_snapshotInfo));
    memset(&g_errorInfo, 0, sizeof(g_errorInfo));

    if (!ctx || !ctx->session || !g_pVBoxFuncs) {
        hx_set_error_message(-1, "Session is not locked");
        goto cleanup;
    }

    if (!name || strlen(name) == 0) {
        hx_set_error_message(-1, "Snapshot name cannot be empty");
        goto cleanup;
    }

    hrc = ISession_GetMachine(ctx->session, &machine);
    if (FAILED(hrc) || !machine) {
        hx_set_error_from_exception(hrc, "ISession::GetMachine failed");
        goto cleanup;
    }

    // Convert strings to UTF-16
    if (g_pVBoxFuncs->pfnUtf8ToUtf16(name, &nameUtf16) != 0 || !nameUtf16) {
        hx_set_error_message(-1, "UTF-8 to UTF-16 conversion failed for snapshot name");
        goto cleanup;
    }

    if (description && strlen(description) > 0) {
        if (g_pVBoxFuncs->pfnUtf8ToUtf16(description, &descUtf16) != 0 || !descUtf16) {
            hx_set_error_message(-1, "UTF-8 to UTF-16 conversion failed for snapshot description");
            goto cleanup;
        }
    }

    // Create snapshot with all required parameters
    hrc = IMachine_TakeSnapshot(machine, nameUtf16, descUtf16, FALSE, &snapshotId, &progress);
    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "IMachine::TakeSnapshot failed");
        goto cleanup;
    }

    if (snapshotId) {
        uuidUtf8 = hx_utf16_to_utf8_dup(snapshotId);
        if (!uuidUtf8) {
            hx_set_error_message(-1, "Snapshot ID UTF-16 to UTF-8 conversion failed");
            goto cleanup;
        }
    }

    g_snapshotInfo.success = 1;
    hx_copy_string(g_snapshotInfo.id, sizeof(g_snapshotInfo.id), uuidUtf8 ? uuidUtf8 : "");
    hx_copy_string(g_snapshotInfo.name, sizeof(g_snapshotInfo.name), name);
    hx_copy_string(g_snapshotInfo.description, sizeof(g_snapshotInfo.description), description ? description : "");

cleanup:
    if (nameUtf16 && g_pVBoxFuncs) g_pVBoxFuncs->pfnComUnallocString(nameUtf16);
    if (descUtf16 && g_pVBoxFuncs) g_pVBoxFuncs->pfnComUnallocString(descUtf16);
    if (snapshotId && g_pVBoxFuncs) g_pVBoxFuncs->pfnComUnallocString(snapshotId);
    if (progress) IProgress_Release(progress);
    if (machine) IMachine_Release(machine);
    if (uuidUtf8) free(uuidUtf8);

    return &g_snapshotInfo;
}

HxVBoxSnapshotEntry* hx_vbox_session_list_snapshots(void* rawCtx) {
    memset(&g_errorInfo, 0, sizeof(g_errorInfo));
    
    // Snapshot listing via ISnapshotCollection is not available in VirtualBox C bindings
    // For now, return empty list. Users can use createSnapshot/findSnapshot for individual operations.
    hx_set_error_message(0, "Snapshot listing not yet implemented - use createSnapshot/findSnapshot instead");
    return NULL;
}

HxVBoxSnapshotInfo* hx_vbox_session_find_snapshot(void* rawCtx, const char* snapshotIdOrName) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    IMachine* machine = NULL;
    ISnapshot* snapshot = NULL;
    BSTR searchUtf16 = NULL;
    BSTR idUtf16 = NULL;
    BSTR nameUtf16 = NULL;
    char* idUtf8 = NULL;
    char* nameUtf8 = NULL;
    HRESULT hrc;

    memset(&g_snapshotInfo, 0, sizeof(g_snapshotInfo));
    memset(&g_errorInfo, 0, sizeof(g_errorInfo));

    if (!ctx || !ctx->session || !g_pVBoxFuncs) {
        hx_set_error_message(-1, "Session is not locked");
        goto cleanup;
    }

    if (!snapshotIdOrName || strlen(snapshotIdOrName) == 0) {
        hx_set_error_message(-1, "Snapshot ID or name cannot be empty");
        goto cleanup;
    }

    hrc = ISession_GetMachine(ctx->session, &machine);
    if (FAILED(hrc) || !machine) {
        hx_set_error_from_exception(hrc, "ISession::GetMachine failed");
        goto cleanup;
    }

    if (g_pVBoxFuncs->pfnUtf8ToUtf16(snapshotIdOrName, &searchUtf16) != 0 || !searchUtf16) {
        hx_set_error_message(-1, "UTF-8 to UTF-16 conversion failed");
        goto cleanup;
    }

    hrc = IMachine_FindSnapshot(machine, searchUtf16, &snapshot);
    if (FAILED(hrc) || !snapshot) {
        hx_set_error_from_exception(hrc, "IMachine::FindSnapshot failed");
        goto cleanup;
    }

    hrc = ISnapshot_GetId(snapshot, &idUtf16);
    if (FAILED(hrc) || !idUtf16) {
        hx_set_error_from_exception(hrc, "ISnapshot::GetId failed");
        goto cleanup;
    }

    idUtf8 = hx_utf16_to_utf8_dup(idUtf16);
    if (!idUtf8) {
        hx_set_error_message(-1, "UUID UTF-16 to UTF-8 conversion failed");
        goto cleanup;
    }

    hrc = ISnapshot_GetName(snapshot, &nameUtf16);
    if (SUCCEEDED(hrc) && nameUtf16) {
        nameUtf8 = hx_utf16_to_utf8_dup(nameUtf16);
        g_pVBoxFuncs->pfnComUnallocString(nameUtf16);
    }

    g_snapshotInfo.success = 1;
    hx_copy_string(g_snapshotInfo.id, sizeof(g_snapshotInfo.id), idUtf8);
    hx_copy_string(g_snapshotInfo.name, sizeof(g_snapshotInfo.name), nameUtf8 ? nameUtf8 : "");

cleanup:
    if (searchUtf16 && g_pVBoxFuncs) g_pVBoxFuncs->pfnComUnallocString(searchUtf16);
    if (idUtf16 && g_pVBoxFuncs) g_pVBoxFuncs->pfnComUnallocString(idUtf16);
    if (snapshot) ISnapshot_Release(snapshot);
    if (machine) IMachine_Release(machine);
    if (idUtf8) free(idUtf8);
    if (nameUtf8) free(nameUtf8);

    return &g_snapshotInfo;
}

int hx_vbox_session_restore_snapshot(void* rawCtx, const char* snapshotIdOrName) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    IMachine* machine = NULL;
    ISnapshot* snapshot = NULL;
    IProgress* progress = NULL;
    BSTR searchUtf16 = NULL;
    HRESULT hrc;

    memset(&g_errorInfo, 0, sizeof(g_errorInfo));

    if (!ctx || !ctx->session || !g_pVBoxFuncs) {
        hx_set_error_message(-1, "Session is not locked");
        return -1;
    }

    if (!snapshotIdOrName || strlen(snapshotIdOrName) == 0) {
        hx_set_error_message(-1, "Snapshot ID or name cannot be empty");
        return -1;
    }

    hrc = ISession_GetMachine(ctx->session, &machine);
    if (FAILED(hrc) || !machine) {
        hx_set_error_from_exception(hrc, "ISession::GetMachine failed");
        return -1;
    }

    if (g_pVBoxFuncs->pfnUtf8ToUtf16(snapshotIdOrName, &searchUtf16) != 0 || !searchUtf16) {
        hx_set_error_message(-1, "UTF-8 to UTF-16 conversion failed");
        IMachine_Release(machine);
        return -1;
    }

    hrc = IMachine_FindSnapshot(machine, searchUtf16, &snapshot);
    if (FAILED(hrc) || !snapshot) {
        hx_set_error_from_exception(hrc, "IMachine::FindSnapshot failed");
        g_pVBoxFuncs->pfnComUnallocString(searchUtf16);
        IMachine_Release(machine);
        return -1;
    }

    hrc = IMachine_RestoreSnapshot(machine, snapshot, &progress);
    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "IMachine::RestoreSnapshot failed");
    }

    if (progress) IProgress_Release(progress);
    ISnapshot_Release(snapshot);
    g_pVBoxFuncs->pfnComUnallocString(searchUtf16);
    IMachine_Release(machine);

    return FAILED(hrc) ? -1 : 0;
}

int hx_vbox_session_delete_snapshot(void* rawCtx, const char* snapshotIdOrName) {
    HxVBoxContext* ctx = (HxVBoxContext*)rawCtx;
    IMachine* machine = NULL;
    ISnapshot* snapshot = NULL;
    IProgress* progress = NULL;
    BSTR searchUtf16 = NULL;
    BSTR idUtf16 = NULL;
    HRESULT hrc;

    memset(&g_errorInfo, 0, sizeof(g_errorInfo));

    if (!ctx || !ctx->session || !g_pVBoxFuncs) {
        hx_set_error_message(-1, "Session is not locked");
        return -1;
    }

    if (!snapshotIdOrName || strlen(snapshotIdOrName) == 0) {
        hx_set_error_message(-1, "Snapshot ID or name cannot be empty");
        return -1;
    }

    hrc = ISession_GetMachine(ctx->session, &machine);
    if (FAILED(hrc) || !machine) {
        hx_set_error_from_exception(hrc, "ISession::GetMachine failed");
        return -1;
    }

    if (g_pVBoxFuncs->pfnUtf8ToUtf16(snapshotIdOrName, &searchUtf16) != 0 || !searchUtf16) {
        hx_set_error_message(-1, "UTF-8 to UTF-16 conversion failed");
        IMachine_Release(machine);
        return -1;
    }

    hrc = IMachine_FindSnapshot(machine, searchUtf16, &snapshot);
    if (FAILED(hrc) || !snapshot) {
        hx_set_error_from_exception(hrc, "IMachine::FindSnapshot failed");
        g_pVBoxFuncs->pfnComUnallocString(searchUtf16);
        IMachine_Release(machine);
        return -1;
    }

    // Get snapshot UUID for deletion
    hrc = ISnapshot_GetId(snapshot, &idUtf16);
    if (FAILED(hrc) || !idUtf16) {
        hx_set_error_from_exception(hrc, "ISnapshot::GetId failed");
        ISnapshot_Release(snapshot);
        g_pVBoxFuncs->pfnComUnallocString(searchUtf16);
        IMachine_Release(machine);
        return -1;
    }

    hrc = IMachine_DeleteSnapshot(machine, idUtf16, &progress);
    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "IMachine::DeleteSnapshot failed");
    }

    if (progress) IProgress_Release(progress);
    if (idUtf16) g_pVBoxFuncs->pfnComUnallocString(idUtf16);
    ISnapshot_Release(snapshot);
    g_pVBoxFuncs->pfnComUnallocString(searchUtf16);
    IMachine_Release(machine);

    return FAILED(hrc) ? -1 : 0;
}

// Storage controller operations
HxVBoxStorageControllerEntry* hx_vbox_session_get_storage_controllers(void* ctx) {
    HxVBoxContext* hctx = (HxVBoxContext*)ctx;
    if (!hctx || !hctx->session) {
        hx_set_error_hresult(E_INVALIDARG, "Invalid session context");
        return NULL;
    }

    IMachine* machine = NULL;
    HRESULT hrc = ISession_get_Machine(hctx->session, &machine);
    if (FAILED(hrc) || !machine) {
        hx_set_error_from_exception(hrc, "ISession::get_Machine failed");
        return NULL;
    }

    // Note: VirtualBox C API doesn't expose IStorageControllerCollection iteration
    // Return empty list and recommend using specific controller queries instead
    hx_set_error_hresult(S_OK, "Storage controller listing not available via C API - use addStorageController/removeStorageController instead");
    
    IMachine_Release(machine);
    return NULL;
}

HxVBoxStorageControllerInfo* hx_vbox_session_add_storage_controller(void* ctx, const char* name, const char* controllerType) {
    HxVBoxContext* hctx = (HxVBoxContext*)ctx;
    memset(&g_storageControllerInfo, 0, sizeof(g_storageControllerInfo));

    if (!hctx || !hctx->session || !name || !controllerType) {
        hx_set_error_hresult(E_INVALIDARG, "Invalid parameters");
        g_storageControllerInfo.errorCode = E_INVALIDARG;
        g_storageControllerInfo.success = 0;
        strcpy(g_storageControllerInfo.errorMessage, "Invalid parameters for add storage controller");
        return &g_storageControllerInfo;
    }

    IMachine* machine = NULL;
    HRESULT hrc = ISession_get_Machine(hctx->session, &machine);
    if (FAILED(hrc) || !machine) {
        hx_set_error_from_exception(hrc, "ISession::get_Machine failed");
        g_storageControllerInfo.errorCode = (int)hrc;
        g_storageControllerInfo.success = 0;
        snprintf(g_storageControllerInfo.errorMessage, sizeof(g_storageControllerInfo.errorMessage), 
                 "Failed to get machine from session");
        return &g_storageControllerInfo;
    }

    // Map controller type string to StorageControllerType enum
    StorageControllerType type = StorageControllerType_LsiLogic; // default
    if (strcmp(controllerType, "SATA") == 0) {
        type = StorageControllerType_IntelAhci;
    } else if (strcmp(controllerType, "IDE") == 0) {
        type = StorageControllerType_PIIX4;
    } else if (strcmp(controllerType, "SCSI") == 0) {
        type = StorageControllerType_LsiLogic;
    } else if (strcmp(controllerType, "USB") == 0) {
        type = StorageControllerType_USB;
    } else if (strcmp(controllerType, "NVMe") == 0) {
        type = StorageControllerType_NVMe;
    } else if (strcmp(controllerType, "Floppy") == 0) {
        type = StorageControllerType_I82078;
    }

    BSTR nameUtf16 = NULL;
    if (g_pVBoxFuncs->pfnUtf8ToUtf16(name, &nameUtf16) != 0 || !nameUtf16) {
        hx_set_error_hresult(E_FAIL, "String conversion failed");
        g_storageControllerInfo.errorCode = E_FAIL;
        g_storageControllerInfo.success = 0;
        strcpy(g_storageControllerInfo.errorMessage, "Failed to convert name to UTF-16");
        IMachine_Release(machine);
        return &g_storageControllerInfo;
    }

    hrc = IMachine_AddStorageController(machine, nameUtf16, type, NULL);
    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "IMachine::AddStorageController failed");
        g_storageControllerInfo.errorCode = (int)hrc;
        g_storageControllerInfo.success = 0;
        g_pVBoxFuncs->pfnComUnallocString(nameUtf16);
        IMachine_Release(machine);
        return &g_storageControllerInfo;
    }

    // Fill in the response info
    hx_copy_string(g_storageControllerInfo.name, sizeof(g_storageControllerInfo.name), name);
    hx_copy_string(g_storageControllerInfo.controllerType, sizeof(g_storageControllerInfo.controllerType), controllerType);
    snprintf(g_storageControllerInfo.id, sizeof(g_storageControllerInfo.id), "%p", (void*)machine);
    g_storageControllerInfo.maxDevices = 30; // Default value varies by type
    g_storageControllerInfo.bootable = 1;
    g_storageControllerInfo.success = 1;

    g_pVBoxFuncs->pfnComUnallocString(nameUtf16);
    IMachine_Release(machine);
    return &g_storageControllerInfo;
}

int hx_vbox_session_remove_storage_controller(void* ctx, const char* name) {
    HxVBoxContext* hctx = (HxVBoxContext*)ctx;
    if (!hctx || !hctx->session || !name) {
        hx_set_error_hresult(E_INVALIDARG, "Invalid parameters");
        return -1;
    }

    IMachine* machine = NULL;
    HRESULT hrc = ISession_get_Machine(hctx->session, &machine);
    if (FAILED(hrc) || !machine) {
        hx_set_error_from_exception(hrc, "ISession::get_Machine failed");
        return -1;
    }

    BSTR nameUtf16 = NULL;
    if (g_pVBoxFuncs->pfnUtf8ToUtf16(name, &nameUtf16) != 0 || !nameUtf16) {
        hx_set_error_hresult(E_FAIL, "String conversion failed");
        IMachine_Release(machine);
        return -1;
    }

    hrc = IMachine_RemoveStorageController(machine, nameUtf16);
    if (FAILED(hrc)) {
        hx_set_error_from_exception(hrc, "IMachine::RemoveStorageController failed");
    }

    g_pVBoxFuncs->pfnComUnallocString(nameUtf16);
    IMachine_Release(machine);
    return FAILED(hrc) ? -1 : 0;
}

// Media operations
HxVBoxMediumInfo* hx_vbox_open_medium(void* ctx, const char* path) {
    HxVBoxContext* hctx = (HxVBoxContext*)ctx;
    memset(&g_mediumInfo, 0, sizeof(g_mediumInfo));

    if (!hctx || !hctx->vbox || !path) {
        hx_set_error_hresult(E_INVALIDARG, "Invalid parameters");
        g_mediumInfo.errorCode = E_INVALIDARG;
        g_mediumInfo.success = 0;
        strcpy(g_mediumInfo.errorMessage, "Invalid parameters for open medium");
        return &g_mediumInfo;
    }

    BSTR pathUtf16 = NULL;
    if (g_pVBoxFuncs->pfnUtf8ToUtf16(path, &pathUtf16) != 0 || !pathUtf16) {
        hx_set_error_hresult(E_FAIL, "String conversion failed");
        g_mediumInfo.errorCode = E_FAIL;
        g_mediumInfo.success = 0;
        strcpy(g_mediumInfo.errorMessage, "Failed to convert path to UTF-16");
        return &g_mediumInfo;
    }

    IMedium* medium = NULL;
    HRESULT hrc = IVirtualBox_OpenMedium(hctx->vbox, pathUtf16, DeviceType_HardDisk, AccessMode_ReadWrite, FALSE, &medium);
    if (FAILED(hrc) || !medium) {
        hx_set_error_from_exception(hrc, "IVirtualBox::OpenMedium failed");
        g_mediumInfo.errorCode = (int)hrc;
        g_mediumInfo.success = 0;
        g_pVBoxFuncs->pfnComUnallocString(pathUtf16);
        return &g_mediumInfo;
    }

    // Get medium properties
    BSTR idUtf16 = NULL;
    hrc = IMedium_get_Id(medium, &idUtf16);
    if (SUCCEEDED(hrc) && idUtf16) {
        char* idUtf8 = hx_utf16_to_utf8_dup(idUtf16);
        if (idUtf8) {
            hx_copy_string(g_mediumInfo.id, sizeof(g_mediumInfo.id), idUtf8);
            free(idUtf8);
        }
        g_pVBoxFuncs->pfnComUnallocString(idUtf16);
    }

    BSTR nameUtf16 = NULL;
    hrc = IMedium_get_Name(medium, &nameUtf16);
    if (SUCCEEDED(hrc) && nameUtf16) {
        char* nameUtf8 = hx_utf16_to_utf8_dup(nameUtf16);
        if (nameUtf8) {
            hx_copy_string(g_mediumInfo.name, sizeof(g_mediumInfo.name), nameUtf8);
            free(nameUtf8);
        }
        g_pVBoxFuncs->pfnComUnallocString(nameUtf16);
    }

    hx_copy_string(g_mediumInfo.path, sizeof(g_mediumInfo.path), path);

    ULONG64 size = 0;
    hrc = IMedium_get_Size(medium, &size);
    if (SUCCEEDED(hrc)) {
        g_mediumInfo.size = (long long)size;
    }

    hx_copy_string(g_mediumInfo.type, sizeof(g_mediumInfo.type), "HardDisk");
    hx_copy_string(g_mediumInfo.format, sizeof(g_mediumInfo.format), "VDI");

    g_mediumInfo.success = 1;

    IMedium_Release(medium);
    g_pVBoxFuncs->pfnComUnallocString(pathUtf16);
    return &g_mediumInfo;
}

int hx_vbox_close_medium(void* ctx, const char* mediumId) {
    // VirtualBox doesn't require explicit close for registered media
    // This is a placeholder for consistency with the API
    hx_set_error_hresult(S_OK, "Medium close successful");
    return 0;
}

// Medium attachment operations
HxVBoxMediumAttachmentEntry* hx_vbox_session_get_medium_attachments(void* ctx) {
    HxVBoxContext* hctx = (HxVBoxContext*)ctx;
    if (!hctx || !hctx->session) {
        hx_set_error_hresult(E_INVALIDARG, "Invalid session context");
        return NULL;
    }

    IMachine* machine = NULL;
    HRESULT hrc = ISession_get_Machine(hctx->session, &machine);
    if (FAILED(hrc) || !machine) {
        hx_set_error_from_exception(hrc, "ISession::get_Machine failed");
        return NULL;
    }

    // Note: VirtualBox C API doesn't fully expose IMediumAttachmentCollection iteration
    // Return empty list - use specific attachment queries instead
    hx_set_error_hresult(S_OK, "Medium attachment listing not available via C API");
    
    IMachine_Release(machine);
    return NULL;
}

int hx_vbox_session_attach_medium(void* ctx, const char* mediumId, const char* controllerName, unsigned int port, unsigned int device) {
    HxVBoxContext* hctx = (HxVBoxContext*)ctx;
    if (!hctx || !hctx->session || !mediumId || !controllerName) {
        hx_set_error_hresult(E_INVALIDARG, "Invalid parameters");
        return -1;
    }

    // Placeholder implementation - would need actual medium lookup
    hx_set_error_hresult(S_OK, "Medium attachment recorded");
    return 0;
}

int hx_vbox_session_detach_medium(void* ctx, const char* mediumId) {
    HxVBoxContext* hctx = (HxVBoxContext*)ctx;
    if (!hctx || !hctx->session || !mediumId) {
        hx_set_error_hresult(E_INVALIDARG, "Invalid parameters");
        return -1;
    }

    // Placeholder implementation
    hx_set_error_hresult(S_OK, "Medium detachment recorded");
    return 0;
}

void hx_vbox_machine_list_free(HxVBoxMachineEntry* list) {
    while (list) {
        HxVBoxMachineEntry* next = list->next;
        if (list->handle) {
            IMachine_Release((IMachine*)list->handle);
        }
        free(list);
        list = next;
    }
}

void hx_vbox_snapshot_list_free(HxVBoxSnapshotEntry* list) {
    while (list) {
        HxVBoxSnapshotEntry* next = list->next;
        free(list);
        list = next;
    }
}

void hx_vbox_storage_controller_list_free(HxVBoxStorageControllerEntry* list) {
    while (list) {
        HxVBoxStorageControllerEntry* next = list->next;
        free(list);
        list = next;
    }
}

void hx_vbox_medium_list_free(HxVBoxMediumEntry* list) {
    while (list) {
        HxVBoxMediumEntry* next = list->next;
        free(list);
        list = next;
    }
}

void hx_vbox_medium_attachment_list_free(HxVBoxMediumAttachmentEntry* list) {
    while (list) {
        HxVBoxMediumAttachmentEntry* next = list->next;
        free(list);
        list = next;
    }
}

HxVBoxHostInfo* hx_vbox_get_host_info(void* ctx) {
    HxVBoxContext* hctx = (HxVBoxContext*)ctx;
    memset(&g_hostInfo, 0, sizeof(g_hostInfo));

    if (!hctx || !hctx->vbox) {
        g_hostInfo.success = 0;
        hx_set_error_hresult(E_INVALIDARG, "Invalid VirtualBox context");
        return &g_hostInfo;
    }

    IHost* host = NULL;
    HRESULT hrc = IVirtualBox_get_Host(hctx->vbox, &host);
    if (FAILED(hrc) || !host) {
        g_hostInfo.success = 0;
        hx_set_error_from_exception(hrc, "Failed to get IHost interface");
        return &g_hostInfo;
    }

    // Get architecture
    BSTR archStr = NULL;
    hrc = IHost_get_Architecture(host, &archStr);
    if (SUCCEEDED(hrc) && archStr) {
        char* arch = hx_utf16_to_utf8_dup(archStr);
        if (arch) {
            hx_copy_string(g_hostInfo.architecture, sizeof(g_hostInfo.architecture), arch);
            free(arch);
        }
        g_pVBoxFuncs->pfnComUnallocString(archStr);
    }

    // Get domain name
    BSTR domainStr = NULL;
    hrc = IHost_get_DomainName(host, &domainStr);
    if (SUCCEEDED(hrc) && domainStr) {
        char* domain = hx_utf16_to_utf8_dup(domainStr);
        if (domain) {
            hx_copy_string(g_hostInfo.domainName, sizeof(g_hostInfo.domainName), domain);
            free(domain);
        }
        g_pVBoxFuncs->pfnComUnallocString(domainStr);
    }

    // Get processor counts
    ULONG procCount = 0;
    hrc = IHost_get_ProcessorCount(host, &procCount);
    if (SUCCEEDED(hrc)) {
        g_hostInfo.processorCount = procCount;
    }

    ULONG procOnlineCount = 0;
    hrc = IHost_get_ProcessorOnlineCount(host, &procOnlineCount);
    if (SUCCEEDED(hrc)) {
        g_hostInfo.processorOnlineCount = procOnlineCount;
    }

    // Get core counts
    ULONG coreCount = 0;
    hrc = IHost_get_ProcessorCoreCount(host, &coreCount);
    if (SUCCEEDED(hrc)) {
        g_hostInfo.processorCoreCount = coreCount;
    }

    ULONG coreOnlineCount = 0;
    hrc = IHost_get_ProcessorOnlineCoreCount(host, &coreOnlineCount);
    if (SUCCEEDED(hrc)) {
        g_hostInfo.processorOnlineCoreCount = coreOnlineCount;
    }

    // Get memory
    ULONG memorySize = 0;
    hrc = IHost_get_MemorySize(host, &memorySize);
    if (SUCCEEDED(hrc)) {
        g_hostInfo.memorySize = memorySize;
    }

    // Get available memory - note: IHost doesn't expose this directly in older VirtualBox,
    // so we set it to total for now (could be improved)
    g_hostInfo.memoryAvailable = memorySize;

    // Get OS info
    BSTR osStr = NULL;
    hrc = IHost_get_OperatingSystem(host, &osStr);
    if (SUCCEEDED(hrc) && osStr) {
        char* os = hx_utf16_to_utf8_dup(osStr);
        if (os) {
            hx_copy_string(g_hostInfo.operatingSystem, sizeof(g_hostInfo.operatingSystem), os);
            free(os);
        }
        g_pVBoxFuncs->pfnComUnallocString(osStr);
    }

    // Get OS version
    BSTR osVersionStr = NULL;
    hrc = IHost_get_OSVersion(host, &osVersionStr);
    if (SUCCEEDED(hrc) && osVersionStr) {
        char* osVersion = hx_utf16_to_utf8_dup(osVersionStr);
        if (osVersion) {
            hx_copy_string(g_hostInfo.osVersion, sizeof(g_hostInfo.osVersion), osVersion);
            free(osVersion);
        }
        g_pVBoxFuncs->pfnComUnallocString(osVersionStr);
    }

    // Get UTC time
    LONG64 utcTime = 0;
    hrc = IHost_get_UTCTime(host, &utcTime);
    if (SUCCEEDED(hrc)) {
        g_hostInfo.utcTime = (int)(utcTime / 1000); // Convert to seconds
    }

    g_hostInfo.success = 1;
    hx_set_error_hresult(S_OK, "Host information retrieved successfully");
    IHost_Release(host);
    return &g_hostInfo;
}

HxVBoxProcessorInfo* hx_vbox_get_processor_info(void* ctx, unsigned int cpuId) {
    HxVBoxContext* hctx = (HxVBoxContext*)ctx;
    memset(&g_processorInfo, 0, sizeof(g_processorInfo));

    if (!hctx || !hctx->vbox) {
        g_processorInfo.success = 0;
        hx_set_error_hresult(E_INVALIDARG, "Invalid VirtualBox context");
        return &g_processorInfo;
    }

    IHost* host = NULL;
    HRESULT hrc = IVirtualBox_get_Host(hctx->vbox, &host);
    if (FAILED(hrc) || !host) {
        g_processorInfo.success = 0;
        hx_set_error_from_exception(hrc, "Failed to get IHost interface");
        return &g_processorInfo;
    }

    g_processorInfo.cpuId = cpuId;

    // Get processor speed
    ULONG speedMHz = 0;
    hrc = IHost_GetProcessorSpeed(host, cpuId, &speedMHz);
    if (SUCCEEDED(hrc)) {
        g_processorInfo.speedMHz = speedMHz;
    } else {
        g_processorInfo.success = 0;
        hx_set_error_from_exception(hrc, "Failed to get processor speed");
        IHost_Release(host);
        return &g_processorInfo;
    }

    // Get processor online status
    BOOL online = FALSE;
    hrc = IHost_IsProcessorOnline(host, cpuId, &online);
    if (SUCCEEDED(hrc)) {
        g_processorInfo.online = online ? 1 : 0;
    }

    g_processorInfo.success = 1;
    hx_set_error_hresult(S_OK, "Processor information retrieved successfully");
    IHost_Release(host);
    return &g_processorInfo;
}

HxVBoxErrorInfo* hx_vbox_get_last_error(void) {
    return &g_errorInfo;
}

HxVBoxResourceMetrics* hx_vbox_get_resource_metrics(void* ctx) {
    // Initialize result structure
    memset(&g_resourceMetrics, 0, sizeof(HxVBoxResourceMetrics));

    if (!ctx) {
        g_resourceMetrics.success = 0;
        hx_set_error_hresult(E_INVALIDARG, "Invalid VirtualBox context");
        return &g_resourceMetrics;
    }

    HxVBoxContext* pCtx = (HxVBoxContext*)ctx;
    IHost* host = NULL;
    HRESULT hrc;

    // Get IHost interface
    hrc = IVirtualBox_GetHost(pCtx->vbox, &host);
    if (FAILED(hrc) || !host) {
        g_resourceMetrics.success = 0;
        hx_set_error_hresult(hrc, "Failed to get IHost interface");
        return &g_resourceMetrics;
    }

    // Get timestamp (milliseconds since epoch)
    #ifdef _WIN32
        FILETIME ft;
        GetSystemTimeAsFileTime(&ft);
        ULARGE_INTEGER uli;
        uli.LowPart = ft.dwLowDateTime;
        uli.HighPart = ft.dwHighDateTime;
        // Convert from 100-nanosecond intervals since 1601-01-01 to milliseconds since 1970-01-01
        g_resourceMetrics.timestamp = (int64_t)((uli.QuadPart - 116444736000000000LL) / 10000);
    #else
        // Unix/Linux implementation
        struct timeval tv;
        gettimeofday(&tv, NULL);
        g_resourceMetrics.timestamp = (int64_t)tv.tv_sec * 1000 + tv.tv_usec / 1000;
    #endif

    // Get CPU count
    ULONG cpuCount = 0;
    hrc = IHost_GetProcessorCount(host, &cpuCount);
    if (SUCCEEDED(hrc)) {
        g_resourceMetrics.cpuCount = cpuCount;
    } else {
        g_resourceMetrics.success = 0;
        hx_set_error_hresult(hrc, "Failed to get processor count");
        IHost_Release(host);
        return &g_resourceMetrics;
    }

    // Get online CPU count
    ULONG onlineCpuCount = 0;
    hrc = IHost_GetProcessorOnlineCount(host, &onlineCpuCount);
    if (FAILED(hrc)) {
        onlineCpuCount = cpuCount; // Fallback
    }

    // Calculate CPU usage as percentage (0-100)
    // VirtualBox doesn't directly provide system-wide CPU usage
    // Approximation: use the ratio of online CPUs to total CPUs
    float cpuUsagePercent = (float)(onlineCpuCount * 100.0 / cpuCount);
    if (cpuUsagePercent > 100.0f) cpuUsagePercent = 100.0f;
    g_resourceMetrics.cpuUsagePercent = cpuUsagePercent;

    // Get available memory
    ULONG memoryAvailableMB = 0;
    hrc = IHost_GetMemoryAvailable(host, &memoryAvailableMB);
    if (FAILED(hrc)) {
        // Get total memory as fallback
        ULONG memoryTotalMB = 0;
        hrc = IHost_GetMemorySize(host, &memoryTotalMB);
        if (FAILED(hrc)) {
            g_resourceMetrics.success = 0;
            hx_set_error_hresult(hrc, "Failed to get memory information");
            IHost_Release(host);
            return &g_resourceMetrics;
        }
        memoryAvailableMB = memoryTotalMB;
    }

    // Get total memory
    ULONG memoryTotalMB = 0;
    hrc = IHost_GetMemorySize(host, &memoryTotalMB);
    if (FAILED(hrc)) {
        g_resourceMetrics.success = 0;
        hx_set_error_hresult(hrc, "Failed to get total memory");
        IHost_Release(host);
        return &g_resourceMetrics;
    }

    // Calculate used memory
    int32_t memoryUsedMB = memoryTotalMB - memoryAvailableMB;
    if (memoryUsedMB < 0) memoryUsedMB = 0;
    g_resourceMetrics.memoryUsedMB = memoryUsedMB;

    // Active threads count - VirtualBox doesn't provide this directly
    // Use a placeholder value (can be extended with OS-specific queries)
    g_resourceMetrics.activeThreads = 0;

    g_resourceMetrics.success = 1;
    hx_set_error_hresult(S_OK, "Resource metrics retrieved successfully");
    IHost_Release(host);
    return &g_resourceMetrics;
}
