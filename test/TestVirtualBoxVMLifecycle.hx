package digigun.virt.virtualbox;

import haxe.Timer;

/**
    Test suite for VM lifecycle enhancements (Phase 2.4).
    
    Tests state polling, graceful/force shutdown modes, and alternative launch methods.
**/
class TestVirtualBoxVMLifecycle {
    public static function main() {
        #if cpp
        trace("=== VirtualBox VM Lifecycle Tests ===");
        trace("");
        
        testStatePollerClass();
        testStatePollerTimeout();
        testStopModes();
        testStartModes();
        testStatePollerElapsedTime();
        testStatePollerToString();
        testLaunchMethods();
        
        trace("");
        trace("✓ All VM lifecycle tests passed!");
        #else
        trace("VM lifecycle tests require CPP target");
        #end
    }
    
    private static function testStatePollerClass() {
        trace("Test: StatePoller class creation");
        var poller = new StatePoller(Running, 10000, 500);
        
        assert(poller.getTargetState() == Running, "Target state should match");
        assert(poller.getPollIntervalMs() == 500, "Poll interval should be 500ms");
        assert(poller.getRemainingMs() > 0, "Should have remaining time");
        assert(!poller.hasTimedOut(), "Should not be timed out initially");
        
        trace("  ✓ StatePoller creation works");
    }
    
    private static function testStatePollerTimeout() {
        trace("Test: StatePoller timeout detection");
        var poller = new StatePoller(Running, 100, 50); // 100ms timeout
        
        // Sleep longer than timeout
        Sys.sleep(0.15);
        
        assert(poller.hasTimedOut(), "Should detect timeout");
        assert(poller.getRemainingMs() == 0, "Remaining time should be 0 when timed out");
        
        // Test timeout exception
        var timeoutThrown = false;
        try {
            poller.checkState(PoweredOff); // Wrong state
        } catch (e:StatePollerError) {
            timeoutThrown = true;
            assert(e.context.targetState == Running, "Error context should have target state");
            assert(e.context.currentState == PoweredOff, "Error context should have current state");
            assert(e.context.elapsedMs >= 100, "Elapsed time should exceed timeout");
        }
        
        assert(timeoutThrown, "Should throw StatePollerError on timeout");
        trace("  ✓ StatePoller timeout works");
    }
    
    private static function testStatePollerSuccess() {
        trace("Test: StatePoller success case");
        var poller = new StatePoller(Running, 5000, 100);
        
        // Simulate reaching target state
        var reached = poller.checkState(Running);
        assert(reached, "Should detect target state reached");
        
        trace("  ✓ StatePoller state detection works");
    }
    
    private static function testStopModes() {
        trace("Test: StopMode enum values");
        
        // Verify all stop modes are defined
        var graceful:StopMode = Graceful;
        var force:StopMode = Force;
        var saveState:StopMode = SaveState;
        var powerDown:StopMode = PowerDown;
        
        assert(graceful.toString() == "graceful", "Graceful mode string");
        assert(force.toString() == "force", "Force mode string");
        assert(saveState.toString() == "savestate", "SaveState mode string");
        assert(powerDown.toString() == "powerdown", "PowerDown mode string");
        
        trace("  ✓ StopMode enum works");
    }
    
    private static function testStartModes() {
        trace("Test: StartMode enum values");
        
        // Verify all start modes are defined
        var gui:StartMode = GUI;
        var headless:StartMode = Headless;
        var separate:StartMode = Separate;
        
        assert(gui.toString() == "gui", "GUI mode string");
        assert(headless.toString() == "headless", "Headless mode string");
        assert(separate.toString() == "separate", "Separate mode string");
        
        trace("  ✓ StartMode enum works");
    }
    
    private static function testLaunchMethods() {
        trace("Test: Launch method enum parameters");
        
        // Test LaunchMode values (used by VirtualBox.launchGui, etc.)
        var gui:LaunchMode = GUI;
        var headless:LaunchMode = Headless;
        var separate:LaunchMode = Separate;
        
        trace("  ✓ Launch mode parameters work");
    }
    
    private static function testStatePollerElapsedTime() {
        trace("Test: StatePoller elapsed time tracking");
        var poller = new StatePoller(Running, 5000, 100);
        
        var elapsed1 = poller.getElapsedMs();
        Sys.sleep(0.2);
        var elapsed2 = poller.getElapsedMs();
        
        assert(elapsed2 >= elapsed1, "Elapsed time should increase");
        assert(elapsed2 - elapsed1 >= 150, "Should account for sleep time");
        
        trace("  ✓ StatePoller elapsed time works");
    }
    
    private static function testStatePollerToString() {
        trace("Test: StatePoller toString");
        var poller = new StatePoller(Running, 5000, 500);
        var str = poller.toString();
        
        assert(str.indexOf("StatePoller") >= 0, "Should contain class name");
        assert(str.indexOf("ms") >= 0, "Should contain time units");
        assert(str.indexOf("elapsed") >= 0, "Should contain 'elapsed'");
        assert(str.indexOf("remaining") >= 0, "Should contain 'remaining'");
        
        trace("  ✓ StatePoller toString works");
    }
    
    private static function assert(condition:Bool, ?message:String) {
        if (!condition) {
            var msg = message != null ? message : "Assertion failed";
            throw new haxe.Exception(msg);
        }
    }
}
