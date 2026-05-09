package digigun.virt.virtualbox;

/**
    Represents the attachment of a storage medium to a controller port/device.
    
    An attachment is the relationship between a medium (disk image/ISO)
    and a storage controller, specifying which port and device the medium
    is connected to.
**/
class MediumAttachment {
    /// The medium being attached (disk image, ISO, etc.)
    public var medium:Medium;
    
    /// The storage controller this medium is attached to
    public var controller:StorageController;
    
    /// Port number on the controller (0-based typically)
    public var port:Int;
    
    /// Device number at the port (usually 0 or 1)
    public var device:Int;
    
    /**
        Create a new MediumAttachment instance.
        
        @param medium The Medium being attached
        @param controller The StorageController receiving the attachment
        @param port Port number on the controller
        @param device Device number at the port
    **/
    public function new(medium:Medium, controller:StorageController, port:Int, device:Int) {
        this.medium = medium;
        this.controller = controller;
        this.port = port;
        this.device = device;
    }
    
    /**
        Get a human-readable location string.
        
        @return String like "SATA-Port1-Dev0"
    **/
    public function getLocation():String {
        return '${controller.controllerType}-Port${port}-Dev${device}';
    }
    
    public function toString():String {
        return 'MediumAttachment {medium: $medium, controller: ${controller.name}, location: ${getLocation()}}';
    }
}

/**
    Type definition for medium attachment information used in C interop.
    Contains references to medium and controller info.
**/
typedef MediumAttachmentInfo = {
    ?mediumId:String,
    ?controllerId:String,
    ?port:Int,
    ?device:Int
};
