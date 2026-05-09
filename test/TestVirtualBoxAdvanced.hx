package;

import digigun.virt.virtualbox.VirtualBox;
import digigun.virt.virtualbox.Session;
import digigun.virt.virtualbox.LockType;
import digigun.virt.virtualbox.LaunchMode;
import digigun.virt.virtualbox.VBoxError;
import digigun.virt.virtualbox.ConnectionError;
import digigun.virt.virtualbox.MachineError;
import digigun.virt.virtualbox.SessionError;

/**
 * Advanced VirtualBox VM Control Test
 * Tests full VM lifecycle: launch, pause, resume, reset, powerdown
 */
class TestVirtualBoxAdvanced {
    static function main() {
        trace("=== Advanced VirtualBox Control Test ===\n");

        var vbox:VirtualBox = null;
        var session:Session = null;
        var success = false;

        try {
            // Connect to VirtualBox
            trace("Step 1: Connecting to VirtualBox...");
            vbox = VirtualBox.open();
            var info = vbox.getVersionInfo();
            trace('✓ Connected to VirtualBox ${info.versionString}\n');

            // Find a test machine
            trace("Step 2: Finding test machine...");
            var machines = vbox.listMachines();
            if (machines.length == 0) {
                trace("✗ No machines found. Create one in VirtualBox.\n");
                return;
            }

            var targetMachine = machines[0];
            trace('✓ Found machine: ${targetMachine.name}\n');

            // Launch VM
            trace("Step 3: Launching VM...");
            var progress = vbox.launchVmProcess(targetMachine.id, LaunchMode.Headless, -1);
            trace('✓ Launch completed! Progress: ${progress.percent}%, Result: ${progress.resultCode}\n');

            // Wait for boot
            trace("Step 4: Waiting for VM to boot (polling)...");
            try {
                session = new Session(vbox); // Create session first
                session.waitUntilRunning(30000, 500); // 30s max, 500ms poll interval
                trace("✓ VM is Running!\n");
            } catch (e:SessionError) {
                trace('✗ Boot timeout: ${e.message}\n');
                throw e;
            }

            // Test pause
            trace("Step 5: Testing pause operation...");
            try {
                session.pause();
                trace("✓ VM paused successfully!\n");

                trace("Step 6: Testing resume operation...");
                session.resume();
                trace("✓ VM resumed successfully!\n");
            } catch (e:VBoxError) {
                trace('⚠ Pause/Resume: ${e.message}\n');
            }

            // Test reset
            trace("Step 7: Testing reset operation...");
            try {
                session.reset();
                trace("✓ VM reset successfully!\n");
            } catch (e:VBoxError) {
                trace('⚠ Reset: ${e.message}\n');
            }

            // Test power button
            trace("Step 8: Testing power button (graceful shutdown)...");
            try {
                session.powerButton();
                trace("✓ Power button pressed!\n");
            } catch (e:VBoxError) {
                trace('⚠ Power button: ${e.message}\n');
            }

            // Test powerDown
            trace("Step 9: Testing powerDown with timeout...");
            try {
                session.powerDown(10000);
                trace("✓ VM powered down successfully!\n");
            } catch (e:VBoxError) {
                trace('⚠ PowerDown: ${e.message}\n');
            }

            success = true;
        } catch (e:Dynamic) {
            trace('\n✗ ERROR: ${e}');
        }

        // Cleanup
        if (session != null) {
            try {
                trace("\nStep 10: Unlocking session...");
                session.unlock();
                trace("✓ Session unlocked!\n");
            } catch (e:VBoxError) {
                trace('⚠ Unlock error: ${e.message}\n');
            }
        }

        if (vbox != null) {
            try {
                vbox.close();
                trace("✓ Connection closed\n");
            } catch (e:VBoxError) {
                trace('⚠ Close error: ${e.message}\n');
            }
        }

        if (success) {
            trace("=== Test Complete (SUCCESS) ===\n");
        } else {
            trace("=== Test Complete (WITH ERRORS) ===\n");
        }
    }
}
