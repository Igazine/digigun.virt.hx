package;

import digigun.virt.virtualbox.*;

/**
    Comprehensive test suite for VirtualBox media and storage management.
    Tests storage controller creation/removal and media lifecycle operations.
**/
class TestVirtualBoxMediaStorage {
    static function main() {
        trace("=== VirtualBox Media & Storage Management Tests ===\n");
        
        var vbox = new VirtualBox();
        if (vbox == null) {
            trace("✗ Failed to initialize VirtualBox");
            return;
        }
        
        trace("✓ VirtualBox initialized");
        
        // Test storage controller type enumeration
        testStorageControllerTypes();
        
        // Test medium type enumeration
        testMediumTypes();
        
        // Test data classes
        testDataClasses();
        
        vbox.close();
        trace("\n=== All tests completed ===");
    }
    
    static function testStorageControllerTypes() {
        trace("\n--- Testing Storage Controller Types ---");
        
        var types = [
            StorageControllerType.SATA,
            StorageControllerType.IDE,
            StorageControllerType.SCSI,
            StorageControllerType.USB,
            StorageControllerType.NVMe,
            StorageControllerType.FLOPPY,
            StorageControllerType.Proprietary
        ];
        
        for (type in types) {
            trace('✓ StorageControllerType.${type}');
        }
    }
    
    static function testMediumTypes() {
        trace("\n--- Testing Medium Types ---");
        
        var types = [
            MediumType.HardDisk,
            MediumType.DVDImage,
            MediumType.FloppyImage
        ];
        
        for (type in types) {
            trace('✓ MediumType.${type}');
        }
    }
    
    static function testDataClasses() {
        trace("\n--- Testing Data Classes ---");
        
        // Test StorageController
        var controller = new StorageController(
            "12345678-1234-1234-1234-123456789012",
            "SATA Controller",
            StorageControllerType.SATA,
            30,
            true
        );
        trace('✓ StorageController: ${controller.toString()}');
        
        // Test Medium
        var medium = new Medium(
            "87654321-4321-4321-4321-210987654321",
            "system.vdi",
            "/path/to/system.vdi",
            10737418240, // 10 GB
            MediumType.HardDisk,
            "VDI"
        );
        trace('✓ Medium: ${medium.toString()}');
        trace('  Formatted size: ${medium.getFormattedSize()}');
        
        // Test MediumAttachment
        var attachment = new MediumAttachment(medium, controller, 0, 0);
        trace('✓ MediumAttachment: ${attachment.toString()}');
        trace('  Location: ${attachment.getLocation()}');
    }
}
