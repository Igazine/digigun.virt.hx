package;

import digigun.virt.virtualbox.Error;
import digigun.virt.virtualbox.VirtualBox;
import digigun.virt.virtualbox.LockType;
import digigun.virt.virtualbox.LaunchMode;

class TestVirtualBox {
    static public function main() {
        var vbox = null;
        try {
            trace("=== VirtualBox Connection Test ===");
            vbox = VirtualBox.open();
            var info = vbox.getVersionInfo();
            trace('✓ Connected to VirtualBox ${info.versionString}');
            trace('  API Version: ${info.apiVersion}, Revision: ${info.revision}');
            trace('  Home Folder: ${info.homeFolder}');

            trace("\n=== Machine Listing Test ===");
            var machines = vbox.listMachines();
            trace('✓ Found ${machines.length} machine(s)');
            for (machine in machines) {
                trace('  - ${machine.name} (ID: ${machine.id}, State: ${machine.state})');
            }

            if (machines.length > 0) {
                trace("\n=== Machine Lookup Test ===");
                var first = vbox.findMachine(machines[0].id);
                trace('✓ Found machine: ${first.name}');
                trace('  - Accessible: ${first.accessible}');
                trace('  - Memory: ${first.memorySize} MB');
                trace('  - OS Type: ${first.osTypeId}');
                trace('  - OS Description: ${first.osDescription}');
                trace('  - Settings: ${first.settingsFilePath}');

                // Test VM control via launchVmProcess
                var controlMode = Sys.getEnv("DIGIGUN_VBOX_CONTROL_TEST");
                if (controlMode != null && controlMode != "") {
                    trace("\n=== VM Control Test ===");
                    try {
                        trace('Testing VM control mode: ${controlMode}');

                        switch (controlMode) {
                            case "launch":
                                trace("→ Launching VM...");
                                var frontendStr = Sys.getEnv("DIGIGUN_VBOX_FRONTEND");
                                if (frontendStr == null || frontendStr == "") {
                                    frontendStr = "headless";
                                }
                                var frontend:LaunchMode = cast frontendStr;
                                var progress = vbox.launchVmProcess(first.id, frontend, -1);
                                trace('✓ VM launched!');
                                trace('  - Description: ${progress.description}');
                                trace('  - Completed: ${progress.completed}');
                                trace('  - Percent: ${progress.percent}%');
                                trace('  - Result Code: ${progress.resultCode}');

                            case "session-lock":
                                trace("→ Locking machine for session...");
                                var session = vbox.lockMachine(first.id, LockType.Shared);
                                trace('✓ Session locked!');
                                trace('  - Session State: ${session.state}');

                                var sessionMachine = session.getMachine();
                                trace('  - Machine in session: ${sessionMachine.name}');

                                trace("→ Unlocking session...");
                                session.unlock();
                                trace('✓ Session unlocked!');

                            case "pause-resume":
                                trace("→ Locking machine for session...");
                                var session = vbox.lockMachine(first.id, LockType.Shared);
                                trace('✓ Session locked!');

                                trace("→ Attempting to pause VM...");
                                try {
                                    session.pause();
                                    trace('✓ VM paused!');

                                    // Wait a bit
                                    Sys.sleep(1);

                                    trace("→ Attempting to resume VM...");
                                    session.resume();
                                    trace('✓ VM resumed!');
                                } catch (e:Error) {
                                    trace('⚠ Pause/resume error (expected if VM not running): ${e.message}');
                                }

                                trace("→ Unlocking session...");
                                session.unlock();
                                trace('✓ Session unlocked!');

                            default:
                                trace('Unknown control mode: ${controlMode}');
                        }
                    } catch (error:Error) {
                        trace('✗ VM control error: ${error.message} (code: ${error.code})');
                    }
                } else {
                    trace("\n[Tip] Set DIGIGUN_VBOX_CONTROL_TEST environment variable to test VM control:");
                    trace("  DIGIGUN_VBOX_CONTROL_TEST=launch              # Start VM");
                    trace("  DIGIGUN_VBOX_CONTROL_TEST=session-lock       # Test session lock/unlock");
                    trace("  DIGIGUN_VBOX_CONTROL_TEST=pause-resume       # Test pause/resume");
                }
            } else {
                trace("⚠ No machines found - create one in VirtualBox to test control functions");
            }

            trace("\n=== Test Complete ===");
        } catch (error:Error) {
            trace('✗ VirtualBox error: ${error.message} (code: ${error.code})');
        } catch (error:Dynamic) {
            trace('✗ Unexpected error: ${error}');
        }

        if (vbox != null) {
            try {
                vbox.close();
                trace("✓ VirtualBox connection closed");
            } catch (error:Error) {
                trace('✗ Error closing connection: ${error.message}');
            }
        }
    }
}
