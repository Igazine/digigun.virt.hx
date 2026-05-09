package digigun.virt.virtualbox;

/**
    Represents a virtual storage medium (disk image, ISO file, etc).
    
    Mediums are storage files that can be attached to storage controllers.
    They can be in various formats (VDI, VMDK, VHD, QCOW2, ISO) and contain
    either VM storage data or optical media content.
**/
class Medium {
    /// Unique identifier for this medium (UUID format)
    public var id:String;
    
    /// Display name of the medium
    public var name:String;
    
    /// File system path to the medium file
    public var path:String;
    
    /// Size of the medium in bytes
    public var size:Int;
    
    /// Type of medium (HardDisk, DVDImage, FloppyImage)
    public var type:MediumType;
    
    /// File format (VDI, VMDK, VHD, QCOW2, ISO, IMA, etc.)
    public var format:String;
    
    /**
        Create a new Medium instance.
        
        @param id Unique identifier (typically UUID)
        @param name Display name
        @param path Full file system path to medium file
        @param size Size in bytes
        @param type Type of medium (HardDisk, DVDImage, FloppyImage)
        @param format File format (VDI, VMDK, ISO, etc.)
    **/
    public function new(id:String, name:String, path:String, size:Int, type:MediumType, format:String) {
        this.id = id;
        this.name = name;
        this.path = path;
        this.size = size;
        this.type = type;
        this.format = format;
    }
    
    /**
        Get human-readable size string.
        
        @return Size formatted as "X.XX MB/GB/TB"
    **/
    public function getFormattedSize():String {
        if (size < 1024) return size + " B";
        if (size < 1024 * 1024) return Math.round(size / 1024.0 * 100) / 100 + " KB";
        if (size < 1024 * 1024 * 1024) return Math.round(size / (1024 * 1024) * 100) / 100 + " MB";
        return Math.round(size / (1024 * 1024 * 1024) * 100) / 100 + " GB";
    }
    
    public function toString():String {
        return 'Medium {id: $id, name: $name, type: $type, format: $format, size: ${getFormattedSize()}}';
    }
}

/**
    Type definition for medium information used in C interop.
    Contains metadata about a storage medium.
**/
typedef MediumInfo = {
    ?id:String,
    ?name:String,
    ?path:String,
    ?size:Int,
    ?type:String,
    ?format:String
};
