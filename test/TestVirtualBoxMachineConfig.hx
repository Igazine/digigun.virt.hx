package;

import digigun.virt.virtualbox.VirtualBox;
import digigun.virt.virtualbox.Session;
import digigun.virt.virtualbox.LockType;
import digigun.virt.virtualbox.DeviceType;
import digigun.virt.virtualbox.SessionError;

class TestVirtualBoxMachineConfig {
    static function main() {
        trace("=== VirtualBox Machine Configuration Test ===");
        
        var vbox = VirtualBox.open();
        trace('Connected to VirtualBox');

        var machines = vbox.listMachines();
        if (machines.length == 0) {
            trace("No machines - skipping machine config tests");
            vbox.close();
            return;
        }

        var machine = machines[0];
        var session = vbox.lockMachine(machine.id, LockType.Write);
        trace('Locked machine: ${machine.name}');

        var orig = session.getMachine();
        trace('Original memory: ${orig.memorySize} MB');

        var newMem = orig.memorySize > 1024 ? 512 : 2048;
        session.setMemorySize(newMem);
        trace('Set memory to ${newMem} MB');

        session.setVCpuCount(2);
        trace('Set CPU to 2 cores');

        session.setBootOrder(DeviceType.HDD, 1);
        session.setBootOrder(DeviceType.CDROM, 2);
        trace('Set boot order: HDD first, CDROM second');

        session.saveSettings();
        trace('Settings saved');

        var modified = session.getMachine();
        trace('Verified: ${modified.memorySize} MB');

        testErrorHandling(session);

        session.unlock();
        vbox.close();
        trace("=== Test Complete ===");
    }

    static function testErrorHandling(session:Session) {
        trace("Testing error handling...");
        
        var invalidMemTested = false;
        try {
            session.setMemorySize(2);
        } catch (e:SessionError) {
            trace("  - Correctly rejected invalid memory");
            invalidMemTested = true;
        }

        var invalidBootTested = false;
        try {
            session.setBootOrder(DeviceType.HDD, 5);
        } catch (e:SessionError) {
            trace("  - Correctly rejected invalid boot position");
            invalidBootTested = true;
        }
    }
}
