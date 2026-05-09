package digigun.virt.virtualbox;

/**
    Represents a storage controller configuration in a VirtualBox VM.
    
    Storage controllers manage media attachments and determine how virtual disks
    and media are connected to the virtual machine. Each controller has properties
    that affect performance, compatibility, and device count limits.
**/
class StorageController {
    /// Unique identifier for this storage controller (UUID format)
    public var id:String;
    
    /// Display name of the storage controller
    public var name:String;
    
    /// Type of storage controller (SATA, IDE, SCSI, USB, NVMe, Floppy, Proprietary)
    public var controllerType:StorageControllerType;
    
    /// Maximum number of devices that can be attached to this controller
    public var maxDevices:Int;
    
    /// Whether this controller is used for VM boot
    public var bootable:Bool;
    
    /**
        Create a new StorageController instance.
        
        @param id Unique identifier (typically UUID)
        @param name Display name of the controller
        @param controllerType Type of controller (see StorageControllerType)
        @param maxDevices Maximum attachable devices (typically 4-30 depending on type)
        @param bootable Whether controller supports boot operations
    **/
    public function new(id:String, name:String, controllerType:StorageControllerType, maxDevices:Int, bootable:Bool = false) {
        this.id = id;
        this.name = name;
        this.controllerType = controllerType;
        this.maxDevices = maxDevices;
        this.bootable = bootable;
    }
    
    public function toString():String {
        return 'StorageController {id: $id, name: $name, type: $controllerType, maxDevices: $maxDevices}';
    }
}

/**
    Type definition for storage controller information used in C interop.
    Contains metadata about a storage controller.
**/
typedef StorageControllerInfo = {
    ?id:String,
    ?name:String,
    ?controllerType:String,
    ?maxDevices:Int,
    ?bootable:Bool
};

