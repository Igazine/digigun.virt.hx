package digigun.virt.virtualbox;

/**
    Enumeration of storage controller types available in VirtualBox.
    
    Each controller type supports different attachment configurations:
    - SATA/SCSI: Up to 30 devices per controller
    - IDE: Maximum 4 devices (legacy)
    - USB/NVMe: Variable device support
    - Floppy: Single device controller
**/
@:enum abstract StorageControllerType(String) {
    /// SATA storage controller (modern HDD/SSD standard)
    var SATA = "SATA";
    
    /// IDE storage controller (legacy, for compatibility)
    var IDE = "IDE";
    
    /// SCSI storage controller (high-performance storage)
    var SCSI = "SCSI";
    
    /// USB-based storage controller
    var USB = "USB";
    
    /// NVMe storage controller (ultra-high performance)
    var NVMe = "NVMe";
    
    /// Floppy disk controller (legacy, rarely used)
    var FLOPPY = "Floppy";
    
    /// Vendor-specific proprietary controller
    var Proprietary = "Proprietary";
    
    @:to public function toString():String {
        return this;
    }
}
