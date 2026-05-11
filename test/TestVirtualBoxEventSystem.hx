package;

import haxe.Int64;
import digigun.virt.virtualbox.EventType;
import digigun.virt.virtualbox.HostEvent;
import digigun.virt.virtualbox.EventListener;
import digigun.virt.virtualbox.HostEventSubscriber;

/**
	Comprehensive test suite for the VirtualBox Event System (Phase 3.3)
	Tests event types, event data, listeners, subscriptions, and polling.
**/
class TestVirtualBoxEventSystem {
	/**
		Test 1: EventType enum completeness and methods
	**/
	public static function testEventTypeEnum():Bool {
		trace("Test 1: EventType enum");

		// Test all event type constants exist
		var vm_started:EventType = EventType.VM_STARTED;
		var vm_stopped:EventType = EventType.VM_STOPPED;
		var snapshot_taken:EventType = EventType.SNAPSHOT_TAKEN;
		var host_shutdown:EventType = EventType.HOST_SHUTDOWN;

		// Test description method
		var desc = vm_started.description();
		trace('  VM_STARTED description: $desc');
		if (desc.length == 0) {
			trace("  FAIL: description() returned empty string");
			return false;
		}

		// Test category method
		var cat = vm_started.category();
		trace('  VM_STARTED category: $cat');
		if (cat != "VM Lifecycle") {
			trace("  FAIL: category() returned wrong category");
			return false;
		}

		// Test isCritical method
		var critical = host_shutdown.isCritical();
		if (!critical) {
			trace("  FAIL: HOST_SHUTDOWN should be critical");
			return false;
		}

		trace("  PASS: EventType enum fully functional");
		return true;
	}

	/**
		Test 2: HostEvent creation and properties
	**/
	public static function testHostEventCreation():Bool {
		trace("Test 2: HostEvent creation");

		var event = new HostEvent(
			EventType.VM_STARTED,
			null,
			"MyVM",
			"Virtual machine started successfully"
		);

		// Check properties
		if (event.eventType != EventType.VM_STARTED) {
			trace("  FAIL: eventType not set correctly");
			return false;
		}

		if (event.vmName != "MyVM") {
			trace("  FAIL: vmName not set correctly");
			return false;
		}

		if (event.description != "Virtual machine started successfully") {
			trace("  FAIL: description not set correctly");
			return false;
		}

		// Check timestamp is set (auto-generated since null passed)
		if (event.timestamp == 0) {
			trace("  FAIL: timestamp not auto-generated");
			return false;
		}

		trace("  PASS: HostEvent properties correct");
		return true;
	}

	/**
		Test 3: HostEvent formatting methods
	**/
	public static function testHostEventFormatting():Bool {
		trace("Test 3: HostEvent formatting");

		var event = new HostEvent(
			EventType.SNAPSHOT_TAKEN,
			1000000.0,
			"TestVM",
			"Snapshot created"
		);

		// Test toString
		var str = event.toString();
		trace('  Event string: $str');
		if (str.indexOf("[") == -1 || str.indexOf("TestVM") == -1) {
			trace("  FAIL: toString() format incorrect");
			return false;
		}

		// Test getCategory
		var cat = event.getCategory();
		if (cat != "Snapshots") {
			trace("  FAIL: getCategory() returned wrong value");
			return false;
		}

		// Test isCritical
		if (event.isCritical()) {
			trace("  FAIL: SNAPSHOT_TAKEN should not be critical");
			return false;
		}

		trace("  PASS: HostEvent formatting works correctly");
		return true;
	}

	/**
		Test 4: EventListener creation and filtering
	**/
	public static function testEventListenerCreation():Bool {
		trace("Test 4: EventListener creation");

		var callCount = 0;
		var lastEvent:HostEvent = null;

		// Test direct function conversion
		var listener:EventListener = function(event:HostEvent) {
			callCount++;
			lastEvent = event;
		};

		// Test handle method
		var event = new HostEvent(EventType.VM_STARTED, null, "VM1", "");
		listener.handle(event);

		if (callCount != 1) {
			trace("  FAIL: listener not called");
			return false;
		}

		// Test filtered listener
		var filteredCallCount = 0;
		var filtered = EventListener.filtered(EventType.VM_STARTED, function(e:HostEvent) {
			filteredCallCount++;
		});

		filtered.handle(event); // Should trigger
		var otherEvent = new HostEvent(EventType.VM_STOPPED, null, "VM1", "");
		filtered.handle(otherEvent); // Should not trigger

		if (filteredCallCount != 1) {
			trace("  FAIL: filtered listener not working correctly (count=$filteredCallCount)");
			return false;
		}

		trace("  PASS: EventListener creation and filtering works");
		return true;
	}

	/**
		Test 5: EventListener VM filtering
	**/
	public static function testEventListenerVMFilter():Bool {
		trace("Test 5: EventListener VM filtering");

		var vmCallCount = 0;
		var vmListener = EventListener.forVM("TargetVM", function(e:HostEvent) {
			vmCallCount++;
		});

		// Event from TargetVM - should trigger
		var event1 = new HostEvent(EventType.VM_STARTED, null, "TargetVM", "");
		vmListener.handle(event1);

		// Event from other VM - should not trigger
		var event2 = new HostEvent(EventType.VM_STARTED, null, "OtherVM", "");
		vmListener.handle(event2);

		if (vmCallCount != 1) {
			trace("  FAIL: VM filter not working correctly (count=$vmCallCount)");
			return false;
		}

		trace("  PASS: EventListener VM filtering works");
		return true;
	}

	/**
		Test 6: HostEventSubscriber basics
	**/
	public static function testEventSubscriberBasics():Bool {
		trace("Test 6: HostEventSubscriber basics");

		#if cpp
		// Create dummy context pointer (use null as placeholder)
		var dummyCtx:cpp.RawPointer<cpp.Void> = cast 0x1234;

		var subscriber = new HostEventSubscriber(EventType.VM_STARTED, dummyCtx);

		// Check initial state
		if (subscriber.getIsActive()) {
			trace("  FAIL: subscriber should not be active initially");
			return false;
		}

		if (subscriber.getListenerCount() != 0) {
			trace("  FAIL: subscriber should have no listeners initially");
			return false;
		}

		// Add listener
		var called = false;
		subscriber.addListener(function(e:HostEvent) {
			called = true;
		});

		if (subscriber.getListenerCount() != 1) {
			trace("  FAIL: listener count should be 1");
			return false;
		}

		trace("  PASS: HostEventSubscriber basics work");
		return true;
		#else
		trace("  SKIP: HostEventSubscriber requires CPP target");
		return true;
		#end
	}

	/**
		Test 7: HostEventSubscriber listener management
	**/
	public static function testEventSubscriberListenerManagement():Bool {
		trace("Test 7: HostEventSubscriber listener management");

		#if cpp
		var dummyCtx:cpp.RawPointer<cpp.Void> = cast 0x5678;
		var subscriber = new HostEventSubscriber(EventType.VM_STOPPED, dummyCtx);

		// Add multiple listeners
		var listener1 = function(e:HostEvent) {};
		var listener2 = function(e:HostEvent) {};

		subscriber.addListener(listener1);
		subscriber.addListener(listener2);

		if (subscriber.getListenerCount() != 2) {
			trace("  FAIL: should have 2 listeners");
			return false;
		}

		// Remove one listener
		subscriber.removeListener(listener1);

		if (subscriber.getListenerCount() != 1) {
			trace("  FAIL: should have 1 listener after removal");
			return false;
		}

		// Clear all listeners
		subscriber.clearListeners();

		if (subscriber.getListenerCount() != 0) {
			trace("  FAIL: should have 0 listeners after clear");
			return false;
		}

		trace("  PASS: HostEventSubscriber listener management works");
		return true;
		#else
		trace("  SKIP: HostEventSubscriber requires CPP target");
		return true;
		#end
	}

	/**
		Test 8: HostEvent details map
	**/
	public static function testHostEventDetails():Bool {
		trace("Test 8: HostEvent details map");

		var details = new Map<String, String>();
		details.set("snapshotId", "snap-123");
		details.set("vmId", "vm-456");

		var event = new HostEvent(
			EventType.SNAPSHOT_TAKEN,
			null,
			"MyVM",
			"Snapshot created",
			details
		);

		// Test getDetail
		var snapId = event.getDetail("snapshotId");
		if (snapId != "snap-123") {
			trace("  FAIL: getDetail() returned wrong value");
			return false;
		}

		// Test hasDetail
		if (!event.hasDetail("vmId")) {
			trace("  FAIL: hasDetail() returned false for existing detail");
			return false;
		}

		if (event.hasDetail("nonexistent")) {
			trace("  FAIL: hasDetail() returned true for non-existent detail");
			return false;
		}

		// Test default value
		var missing = event.getDetail("missing", "default-value");
		if (missing != "default-value") {
			trace("  FAIL: getDetail() default value not returned");
			return false;
		}

		trace("  PASS: HostEvent details map works");
		return true;
	}

	/**
		Test 9: HostEvent comparison functions
	**/
	public static function testHostEventComparison():Bool {
		trace("Test 9: HostEvent comparison");

		var event1 = new HostEvent(EventType.VM_STARTED, 1000.0, "VM1", "");
		var event2 = new HostEvent(EventType.VM_STARTED, 2000.0, "VM1", "");
		var event3 = new HostEvent(EventType.VM_STOPPED, 1500.0, "VM1", "");

		// Test compareByTime
		var timeCmp = HostEvent.compareByTime(event1, event2);
		if (timeCmp >= 0) {
			trace("  FAIL: compareByTime should return negative for earlier event");
			return false;
		}

		// Test compareByType
		var typeCmp = HostEvent.compareByType(event1, event3);
		if (typeCmp == 0) {
			trace("  FAIL: compareByType should return non-zero for different types");
			return false;
		}

		trace("  PASS: HostEvent comparison works");
		return true;
	}

	/**
		Run all tests
	**/
	public static function main():Void {
		trace("=== VirtualBox Event System Tests (Phase 3.3) ===\n");

		var results:Array<{name:String, passed:Bool}> = [];

		results.push({name: "EventType enum", passed: testEventTypeEnum()});
		results.push({name: "HostEvent creation", passed: testHostEventCreation()});
		results.push({name: "HostEvent formatting", passed: testHostEventFormatting()});
		results.push({name: "EventListener creation", passed: testEventListenerCreation()});
		results.push({name: "EventListener VM filter", passed: testEventListenerVMFilter()});
		results.push({name: "HostEventSubscriber basics", passed: testEventSubscriberBasics()});
		results.push({name: "HostEventSubscriber listener management", passed: testEventSubscriberListenerManagement()});
		results.push({name: "HostEvent details", passed: testHostEventDetails()});
		results.push({name: "HostEvent comparison", passed: testHostEventComparison()});

		// Summary
		trace("\n=== Test Summary ===");
		var passCount = 0;
		for (result in results) {
			var status = result.passed ? "✓ PASS" : "✗ FAIL";
			trace('$status: ${result.name}');
			if (result.passed) passCount++;
		}

		trace('\nTotal: $passCount/${results.length} tests passed');
	}
}
