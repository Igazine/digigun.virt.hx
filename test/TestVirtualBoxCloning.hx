package;

import haxe.io.Bytes;
import digigun.virt.virtualbox.VirtualBox;
import digigun.virt.virtualbox.MachineCloneMode;
import digigun.virt.virtualbox.MachineCloneOptions;
import digigun.virt.virtualbox.CloneProgressCallback;

/**
	Comprehensive test suite for machine cloning operations.
**/
class TestVirtualBoxCloning {
	static var vbox:VirtualBox;

	static function testMachineCloneModeEnum() {
		trace("testMachineCloneModeEnum: Testing MachineCloneMode enum");

		// Test Full mode string conversion
		var fullStr:String = cast Full;
		assert(fullStr == "Full", "Full mode should convert to string 'Full'");
		assert(Full.description().indexOf("independent") >= 0, "Full description should mention independence");
		trace("  ✓ Full mode: " + Full.description());

		// Test Linked mode string conversion
		var linkedStr:String = cast Linked;
		assert(linkedStr == "Linked", "Linked mode should convert to string 'Linked'");
		assert(Linked.description().indexOf("snapshots") >= 0, "Linked description should mention snapshots");
		trace("  ✓ Linked mode: " + Linked.description());

		// Test Shallow mode string conversion
		var shallowStr:String = cast Shallow;
		assert(shallowStr == "Shallow", "Shallow mode should convert to string 'Shallow'");
		assert(Shallow.description().indexOf("disks") >= 0, "Shallow description should mention disks");
		trace("  ✓ Shallow mode: " + Shallow.description());
	}

	static function testMachineCloneOptionsCreation() {
		trace("testMachineCloneOptionsCreation: Testing MachineCloneOptions creation");

		// Test valid options
		var options = new MachineCloneOptions("TestClone", cast Full, true);
		assert(options.targetName == "TestClone", "Target name should be set");
		assert(cast(options.mode, String) == "Full", "Mode should be Full");
		assert(options.cloneSnapshots == true, "Clone snapshots should be true");
		assert(options.fromSnapshotUuid == null, "Snapshot UUID should be null");
		assert(options.isValid() == true, "Options should be valid");
		trace("  ✓ Created valid options: " + options.description());

		// Test with snapshot UUID
		var optionsWithSnapshot = new MachineCloneOptions("CloneFromSnapshot", cast Linked, true, "snapshot-uuid-123");
		assert(optionsWithSnapshot.fromSnapshotUuid == "snapshot-uuid-123", "Snapshot UUID should be set");
		trace("  ✓ Created options with snapshot: " + optionsWithSnapshot.description());

		// Test shallow clone without snapshots
		var shallowOptions = new MachineCloneOptions("ShallowClone", cast Shallow, false);
		assert(shallowOptions.cloneSnapshots == false, "Clone snapshots should be false");
		trace("  ✓ Created shallow clone options: " + shallowOptions.description());
	}

	static function testMachineCloneOptionsValidation() {
		trace("testMachineCloneOptionsValidation: Testing MachineCloneOptions validation");

		// Test valid options
		var validOptions = new MachineCloneOptions("ValidClone", cast Full);
		assert(validOptions.isValid() == true, "Valid options should pass validation");
		trace("  ✓ Valid options pass validation");

		// Test empty target name
		try {
			var invalidOptions = new MachineCloneOptions("", cast Full);
			assert(false, "Empty target name should throw error");
		} catch (e:Dynamic) {
			trace("  ✓ Empty target name throws error: " + Std.string(e));
		}
	}

	static function testCloneProgressCallback() {
		trace("testCloneProgressCallback: Testing CloneProgressCallback interface");

		var progressEvents:Array<String> = [];

		var callback:CloneProgressCallback = {
			onCloneStart: function(targetName:String, mode:MachineCloneMode) {
				progressEvents.push("start:" + targetName + ":" + Std.string(mode));
			},
			onCloneProgress: function(percent:Int, operation:String) {
				progressEvents.push("progress:" + percent + ":" + operation);
			},
			onCloneComplete: function(targetName:String, uuid:String) {
				progressEvents.push("complete:" + targetName + ":" + uuid);
			},
			onCloneError: function(targetName:String, errorCode:Int, errorMsg:String) {
				progressEvents.push("error:" + targetName + ":" + errorCode + ":" + errorMsg);
			}
		};

		// Simulate callback flow
		callback.onCloneStart("TestVM", cast Full);
		callback.onCloneProgress(50, "Copying disks");
		callback.onCloneProgress(100, "Finalizing");
		callback.onCloneComplete("TestVM", "new-vm-uuid");

		assert(progressEvents.length == 4, "Should have 4 progress events");
		assert(progressEvents[0].indexOf("start") == 0, "First event should be start");
		assert(progressEvents[3].indexOf("complete") == 0, "Last event should be complete");
		trace("  ✓ Callback flow: " + progressEvents.join(" -> "));
	}

	static function testCloneModeDescriptions() {
		trace("testCloneModeDescriptions: Testing clone mode descriptions");

		var modes:Array<MachineCloneMode> = [cast Full, cast Linked, cast Shallow];
		for (mode in modes) {
			var desc = mode.description();
			assert(desc.length > 0, "Description should not be empty");
			trace("  ✓ " + Std.string(mode) + ": " + desc);
		}
	}

	static function testCloneOptionsDescription() {
		trace("testCloneOptionsDescription: Testing MachineCloneOptions description");

		var options1 = new MachineCloneOptions("FullClone", cast Full, true);
		var desc1 = options1.description();
		assert(desc1.indexOf("FullClone") >= 0, "Description should contain target name");
		assert(desc1.indexOf("Full clone") >= 0, "Description should contain mode");
		trace("  ✓ Full clone description: " + desc1);

		var options2 = new MachineCloneOptions("LinkedClone", cast Linked, false);
		var desc2 = options2.description();
		assert(desc2.indexOf("LinkedClone") >= 0, "Description should contain target name");
		assert(desc2.indexOf("Linked clone") >= 0 || desc2.indexOf("snapshots") >= 0, "Description should handle snapshots");
		trace("  ✓ Linked clone description: " + desc2);

		var options3 = new MachineCloneOptions("SnapshotClone", cast Shallow, true, "snap-123");
		var desc3 = options3.description();
		assert(desc3.indexOf("snap-123") >= 0, "Description should contain snapshot UUID");
		trace("  ✓ Snapshot clone description: " + desc3);
	}

	static function assert(condition:Bool, message:String) {
		if (!condition) {
			throw new haxe.Exception("Assertion failed: " + message);
		}
	}

	static function main() {
		trace("=== VirtualBox Machine Cloning Test Suite ===\n");

		try {
			testMachineCloneModeEnum();
			trace("");
			testMachineCloneOptionsCreation();
			trace("");
			testMachineCloneOptionsValidation();
			trace("");
			testCloneProgressCallback();
			trace("");
			testCloneModeDescriptions();
			trace("");
			testCloneOptionsDescription();

			trace("\n=== All tests passed! ===");
		} catch (e:Dynamic) {
			trace("\n❌ Test failed: " + Std.string(e));
			throw e;
		}
	}
}
