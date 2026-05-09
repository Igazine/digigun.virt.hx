package digigun.virt.virtualbox;

/**
    Enumeration of storage medium types supported by VirtualBox.
    
    Types represent different storage media that can be attached to storage controllers:
    - HardDisk: Virtual hard disk images (VDI, VMDK, VHD, etc.)
    - DVDImage: ISO-9660 disc images for DVD/CDROM
    - FloppyImage: Legacy floppy disk images (IMG, IMA)
**/
@:enum abstract MediumType(String) {
    /// Hard disk image (primary storage medium)
    var HardDisk = "HardDisk";
    
    /// DVD/CD-ROM image (ISO format typically)
    var DVDImage = "DVDImage";
    
    /// Floppy disk image (legacy, rarely used)
    var FloppyImage = "FloppyImage";
    
    @:to public function toString():String {
        return this;
    }
}
