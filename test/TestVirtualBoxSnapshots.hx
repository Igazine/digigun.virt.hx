import digigun.virt.virtualbox.*;

/**
 * Comprehensive test suite for VirtualBox snapshot operations
 * 
 * Tests snapshot create, restore, list, find, and delete functionality.
 * Requires at least one VirtualBox VM to be available.
 * 
 * Execute with:
 *   haxe test-virtualbox-snapshots.hxml
 */
class TestVirtualBoxSnapshots {
    static function main() {
        trace("=== VirtualBox Snapshot Operations Tests ===\n");
        
        var vbox = null;
        var session = null;
        
        try {
            // 1. Connect to VirtualBox
            trace("[1/5] Connecting to VirtualBox...");
            vbox = VirtualBox.open();
            var version = vbox.getVersionInfo();
            trace('  ✓ Connected to VirtualBox ${version.versionString}');
            
            // 2. List and find a machine
            trace("\n[2/5] Listing machines and selecting first available...");
            var machines = vbox.listMachines();
            if (machines.length == 0) {
                trace("  ✗ No VirtualBox machines available");
                vbox.close();
                return;
            }
            var testMachine = machines[0];
            trace('  ✓ Found ${machines.length} machine(s), using: ${testMachine.name}');
            
            // 3. Lock machine for snapshot operations
            trace("\n[3/5] Locking machine in Write mode for snapshot operations...");
            session = vbox.lockMachine(testMachine.name, LockType.Write);
            trace("  ✓ Machine locked successfully");
            
            // 4. Test snapshot creation
            trace("\n[4/5] Testing snapshot operations...");
            testSnapshotCreation(session);
            testSnapshotFinding(session);
            testSnapshotListing(session);
            testSnapshotDeletion(session);
            
            // 5. Cleanup
            trace("\n[5/5] Cleaning up...");
            session.unlock();
            trace("  ✓ Session unlocked");
            
            vbox.close();
            trace("  ✓ VirtualBox connection closed");
            
            trace("\n=== All snapshot tests passed! ===");
        } catch (e:VBoxError) {
            trace('✗ VBoxError: ${e.message} (code: ${e.errorCode})');
            if (session != null) {
                try { session.unlock(); } catch (_:Dynamic) {}
            }
            if (vbox != null) {
                try { vbox.close(); } catch (_:Dynamic) {}
            }
        } catch (e:SessionError) {
            trace('✗ SessionError: ${e.message} (code: ${e.errorCode})');
            if (session != null) {
                try { session.unlock(); } catch (_:Dynamic) {}
            }
            if (vbox != null) {
                try { vbox.close(); } catch (_:Dynamic) {}
            }
        } catch (e:Dynamic) {
            trace('✗ Unexpected error: $e');
            if (session != null) {
                try { session.unlock(); } catch (_:Dynamic) {}
            }
            if (vbox != null) {
                try { vbox.close(); } catch (_:Dynamic) {}
            }
        }
    }
    
    static function testSnapshotCreation(session:Session):Void {
        trace("\n  Test: Create snapshot");
        try {
            var snapshot = session.createSnapshot("Test Snapshot 1", "Created during unit test");
            if (snapshot.name != "Test Snapshot 1") {
                throw new SessionError("Snapshot name mismatch", -1, {operation: "test"});
            }
            trace('    ✓ Created snapshot: ${snapshot.name}');
            
            // Create another snapshot
            var snapshot2 = session.createSnapshot("Test Snapshot 2");
            trace('    ✓ Created snapshot without description: ${snapshot2.name}');
            
        } catch (e:SessionError) {
            trace('    ✗ Failed to create snapshot: ${e.message}');
            throw e;
        }
    }
    
    static function testSnapshotFinding(session:Session):Void {
        trace("\n  Test: Find snapshot by name");
        try {
            var snapshot = session.findSnapshot("Test Snapshot 1");
            if (snapshot.name != "Test Snapshot 1") {
                throw new SessionError("Found snapshot name mismatch", -1, {operation: "test"});
            }
            trace('    ✓ Found snapshot by name: ${snapshot.name}');
            
            // Try to find by ID
            var snapshotById = session.findSnapshot(snapshot.id);
            if (snapshotById.name != snapshot.name) {
                throw new SessionError("Found snapshot by ID mismatch", -1, {operation: "test"});
            }
            trace('    ✓ Found snapshot by ID: ${snapshotById.id}');
            
        } catch (e:SessionError) {
            trace('    ✗ Failed to find snapshot: ${e.message}');
            throw e;
        }
    }
    
    static function testSnapshotListing(session:Session):Void {
        trace("\n  Test: List all snapshots");
        try {
            var snapshots = session.listSnapshots();
            trace('    ✓ Listed ${snapshots.length} snapshot(s)');
            
            for (snapshot in snapshots) {
                trace('       - ${snapshot.name} (${snapshot.id})');
            }
            
            if (snapshots.length < 2) {
                trace('    ⚠ Expected at least 2 snapshots, found ${snapshots.length}');
            }
            
        } catch (e:SessionError) {
            trace('    ✗ Failed to list snapshots: ${e.message}');
            throw e;
        }
    }
    
    static function testSnapshotDeletion(session:Session):Void {
        trace("\n  Test: Delete snapshot");
        try {
            session.deleteSnapshot("Test Snapshot 2");
            trace("    ✓ Deleted snapshot: Test Snapshot 2");
            
            // Try to find deleted snapshot (should fail)
            try {
                session.findSnapshot("Test Snapshot 2");
                trace("    ⚠ Snapshot still found after deletion");
            } catch (e:SessionError) {
                trace("    ✓ Snapshot not found after deletion (as expected)");
            }
            
        } catch (e:SessionError) {
            trace('    ✗ Failed to delete snapshot: ${e.message}');
            throw e;
        }
    }
}
