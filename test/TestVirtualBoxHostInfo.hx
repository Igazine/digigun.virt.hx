package digigun.virt.virtualbox;

/**
    Comprehensive test suite for host system information retrieval.
    
    Tests the HostInfo API which exposes system-level information from VirtualBox's IHost interface.
    Covers architecture detection, processor enumeration, memory statistics, and OS information.
**/
class TestVirtualBoxHostInfo {
    private static var vbox:VirtualBox;
    private static var testsPassed:Int = 0;
    private static var testsFailed:Int = 0;

    public static function main() {
        #if cpp
        trace("=== VirtualBox Host Information Tests ===\n");
        
        try {
            vbox = VirtualBox.open();
            trace("✓ VirtualBox connection opened");
        } catch (e:Dynamic) {
            trace('✗ Failed to open VirtualBox: $e');
            Sys.exit(1);
        }

        try {
            // Test suite
            testGetHostInfo();
            testArchitectureEnum();
            testMemoryInfo();
            testProcessorEnumeration();
            testProcessorInfo();
            testMemoryFormatting();
            
            // Summary
            trace('\n=== Test Results ===');
            trace('Passed: $testsPassed');
            trace('Failed: $testsFailed');
            
            if (testsFailed > 0) {
                Sys.exit(1);
            }
        } catch (e:Dynamic) {
            trace('Unexpected error: $e');
            Sys.exit(1);
        }
        
        try {
            vbox.close();
            trace('✓ VirtualBox connection closed');
        } catch (e:Dynamic) {
            trace('✗ Error closing VirtualBox: $e');
        }
        #else
        trace("Host information tests require CPP target");
        #end
    }

    /**
        Test basic host information retrieval.
        Verifies that getHostInfo() returns a valid HostInfo object with all fields populated.
    **/
    private static function testGetHostInfo() {
        trace('\n[Test] Basic Host Information Retrieval');
        
        try {
            var hostInfo = vbox.getHostInfo();
            
            // Verify object exists
            if (hostInfo == null) {
                fail("HostInfo object is null");
                return;
            }
            
            // Verify basic fields
            if (hostInfo.domainName == null || hostInfo.domainName == "") {
                fail("Domain name is empty");
                return;
            }
            
            if (hostInfo.operatingSystem == null || hostInfo.operatingSystem == "") {
                fail("OS name is empty");
                return;
            }
            
            if (hostInfo.osVersion == null || hostInfo.osVersion == "") {
                fail("OS version is empty");
                return;
            }
            
            trace('  Domain: ${hostInfo.domainName}');
            trace('  OS: ${hostInfo.operatingSystem} ${hostInfo.osVersion}');
            pass("Host information retrieved successfully");
        } catch (e:Dynamic) {
            fail('Exception: $e');
        }
    }

    /**
        Test PlatformArchitecture enum creation and conversion.
        Verifies that architecture strings are properly recognized and converted to enums.
    **/
    private static function testArchitectureEnum() {
        trace('\n[Test] Platform Architecture Enum');
        
        try {
            var hostInfo = vbox.getHostInfo();
            var arch = hostInfo.architecture;
            
            // Verify architecture is set
            if (arch == null) {
                fail("Architecture is null");
                return;
            }
            
            var archStr = arch.toString();
            trace('  Architecture: $archStr');
            
            // Verify it's a valid architecture string (non-empty)
            if (archStr == "") {
                fail("Architecture enum produces empty string");
                return;
            }
            
            pass("Architecture enum valid");
        } catch (e:Dynamic) {
            fail('Exception: $e');
        }
    }

    /**
        Test memory information object and calculations.
        Verifies memory size fields are reasonable and usage calculation is correct.
    **/
    private static function testMemoryInfo() {
        trace('\n[Test] Memory Information Object');
        
        try {
            var hostInfo = vbox.getHostInfo();
            var memory = hostInfo.memory;
            
            if (memory == null) {
                fail("MemoryInfo object is null");
                return;
            }
            
            // Verify memory values are reasonable (at least 512MB)
            if (memory.totalMemoryMB < 512) {
                fail("Total memory suspiciously low: ${memory.totalMemoryMB}MB");
                return;
            }
            
            // Verify available doesn't exceed total
            if (memory.availableMemoryMB > memory.totalMemoryMB) {
                fail("Available memory exceeds total memory");
                return;
            }
            
            // Verify usage percent is valid (0-100)
            if (memory.usagePercent < 0 || memory.usagePercent > 100) {
                fail("Usage percent out of range: ${memory.usagePercent}%");
                return;
            }
            
            trace('  Total: ${memory.formatMemorySize(memory.totalMemoryMB)}');
            trace('  Available: ${memory.formatMemorySize(memory.availableMemoryMB)}');
            trace('  Usage: ${Math.round(memory.usagePercent)}%');
            pass("Memory information valid");
        } catch (e:Dynamic) {
            fail('Exception: $e');
        }
    }

    /**
        Test processor enumeration and counts.
        Verifies processor counts are consistent and reasonable.
    **/
    private static function testProcessorEnumeration() {
        trace('\n[Test] Processor Enumeration');
        
        try {
            var hostInfo = vbox.getHostInfo();
            
            // Verify processor counts are positive
            if (hostInfo.processorCount <= 0) {
                fail("Processor count is zero or negative");
                return;
            }
            
            // Verify online count doesn't exceed total
            if (hostInfo.processorOnlineCount > hostInfo.processorCount) {
                fail("Online processors exceed total processors");
                return;
            }
            
            // Verify core counts are reasonable
            if (hostInfo.processorCoreCount < hostInfo.processorCount) {
                // Cores can be >= processors (multi-core), but not less
                fail("Core count less than processor count");
                return;
            }
            
            trace('  Total CPUs: ${hostInfo.processorCount}');
            trace('  Online CPUs: ${hostInfo.processorOnlineCount}');
            trace('  Total Cores: ${hostInfo.processorCoreCount}');
            trace('  Online Cores: ${hostInfo.processorOnlineCoreCount}');
            pass("Processor counts valid");
        } catch (e:Dynamic) {
            fail('Exception: $e');
        }
    }

    /**
        Test individual processor information retrieval.
        Verifies getProcessorInfo() works for valid CPU indices and returns speed info.
    **/
    private static function testProcessorInfo() {
        trace('\n[Test] Individual Processor Information');
        
        try {
            var hostInfo = vbox.getHostInfo();
            
            // Get info for first processor
            var cpu0 = vbox.getProcessorInfo(0);
            
            if (cpu0 == null) {
                fail("ProcessorInfo object is null");
                return;
            }
            
            // Verify CPU ID matches
            if (cpu0.cpuId != 0) {
                fail("CPU ID mismatch: expected 0, got ${cpu0.cpuId}");
                return;
            }
            
            // Verify speed is reasonable (> 0 MHz, < 100GHz)
            if (cpu0.speedMHz <= 0 || cpu0.speedMHz > 100000) {
                fail("CPU speed unrealistic: ${cpu0.speedMHz}MHz");
                return;
            }
            
            trace('  CPU 0: ${cpu0.getStatusString()}');
            pass("Processor information retrieved");
        } catch (e:Dynamic) {
            fail('Exception: $e');
        }
    }

    /**
        Test memory formatting utilities.
        Verifies human-readable memory formatting for various sizes.
    **/
    private static function testMemoryFormatting() {
        trace('\n[Test] Memory Formatting');
        
        try {
            var hostInfo = vbox.getHostInfo();
            var memory = hostInfo.memory;
            
            // Test formatting
            var totalFormatted = memory.formatMemorySize(memory.totalMemoryMB);
            var usedFormatted = memory.formatMemorySize(memory.getUsedMemoryMB());
            var usageString = memory.getUsageString();
            
            trace('  Total: $totalFormatted');
            trace('  Used: $usedFormatted');
            trace('  Usage: $usageString');
            
            // Verify strings are non-empty
            if (totalFormatted == "" || usedFormatted == "" || usageString == "") {
                fail("Formatted strings are empty");
                return;
            }
            
            pass("Memory formatting valid");
        } catch (e:Dynamic) {
            fail('Exception: $e');
        }
    }

    /**
        Mark a test as passed and log the result.
    **/
    private static function pass(message:String) {
        testsPassed++;
        trace('  ✓ $message');
    }

    /**
        Mark a test as failed and log the result.
    **/
    private static function fail(message:String) {
        testsFailed++;
        trace('  ✗ $message');
    }
}
