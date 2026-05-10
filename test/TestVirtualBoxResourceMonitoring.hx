package digigun.virt.virtualbox;

import digigun.virt.virtualbox.*;

/**
 * Test suite for resource monitoring functionality.
 * 
 * Tests HostResourceSnapshot and ResourceMonitor classes,
 * verifying snapshot creation, tracking, and analysis capabilities.
 */
class TestVirtualBoxResourceMonitoring {
	static function main() {
		trace("=== Resource Monitoring Test Suite ===\n");

		testResourceSnapshotCreation();
		testSnapshotMetrics();
		testResourceMonitorBasics();
		testMonitorAverages();
		testMonitorPruning();
		testSnapshotDeltas();

		trace("\n=== All tests completed ===");
	}

	/**
	 * Test: Create resource snapshots and verify properties.
	 */
	static function testResourceSnapshotCreation():Void {
		trace("TEST: Resource Snapshot Creation");

		var timestamp = haxe.Timer.stamp() * 1000;
		var snapshot = new HostResourceSnapshot(
			timestamp,
			45.5,
			8192,
			8,
			1024
		);

		assert(snapshot.timestamp == timestamp, "Timestamp mismatch");
		assert(snapshot.cpuUsagePercent == 45.5, "CPU usage mismatch");
		assert(snapshot.memoryUsedMB == 8192, "Memory mismatch");
		assert(snapshot.cpuCount == 8, "CPU count mismatch");
		assert(snapshot.activeThreads == 1024, "Thread count mismatch");
		assert(snapshot.getTimestamp() == timestamp, "getTimestamp() mismatch");

		trace("✓ Snapshots created and properties verified");
	}

	/**
	 * Test: Snapshot summary and formatting methods.
	 */
	static function testSnapshotMetrics():Void {
		trace("\nTEST: Snapshot Metrics & Formatting");

		var snapshot = new HostResourceSnapshot(
			haxe.Timer.stamp() * 1000,
			75.2,
			4096,
			4,
			512
		);

		var summary = snapshot.getMetricsSummary();
		trace("Summary: " + summary);
		assert(summary.indexOf("75.2") >= 0 || summary.indexOf("75") >= 0, "CPU in summary");
		assert(summary.indexOf("4096") >= 0, "Memory in summary");
		assert(summary.indexOf("512") >= 0, "Threads in summary");

		var str = snapshot.toString();
		trace("String: " + str);
		assert(str.indexOf("HostResourceSnapshot") >= 0, "Class name in toString");

		trace("✓ Snapshot formatting working correctly");
	}

	/**
	 * Test: Basic resource monitor operations.
	 */
	static function testResourceMonitorBasics():Void {
		trace("\nTEST: Resource Monitor Basics");

		var monitor = new ResourceMonitor();
		assert(monitor.getSnapshotCount() == 0, "Initial count should be 0");
		assert(monitor.getLatestSnapshot() == null, "No latest snapshot initially");

		var snap1 = new HostResourceSnapshot(
			haxe.Timer.stamp() * 1000,
			30.0,
			2048,
			4,
			256
		);
		monitor.addSnapshot(snap1);

		assert(monitor.getSnapshotCount() == 1, "Count should be 1");
		assert(monitor.getLatestSnapshot() != null, "Latest snapshot should exist");
		assert(monitor.getLatestSnapshot() == snap1, "Latest snapshot mismatch");
		assert(monitor.getOldestSnapshot() == snap1, "Oldest snapshot mismatch");

		trace("✓ Monitor basic operations working");
	}

	/**
	 * Test: Monitor average calculations.
	 */
	static function testMonitorAverages():Void {
		trace("\nTEST: Monitor Averages & Statistics");

		var monitor = new ResourceMonitor();
		var baseTime = haxe.Timer.stamp() * 1000;

		// Add multiple snapshots
		monitor.addSnapshot(new HostResourceSnapshot(baseTime, 20.0, 2000, 4, 100));
		monitor.addSnapshot(new HostResourceSnapshot(baseTime + 1000, 40.0, 3000, 4, 200));
		monitor.addSnapshot(new HostResourceSnapshot(baseTime + 2000, 60.0, 4000, 4, 300));

		var avgCpu = monitor.getAverageCpuUsage();
		assert(avgCpu > 39 && avgCpu < 41, "Average CPU should be ~40");

		var avgMem = monitor.getAverageMemoryUsage();
		assert(avgMem > 2999 && avgMem < 3001, "Average memory should be ~3000");

		var minCpu = monitor.getMinCpuUsage();
		assert(minCpu == 20.0, "Min CPU should be 20");

		var maxCpu = monitor.getMaxCpuUsage();
		assert(maxCpu == 60.0, "Max CPU should be 60");

		trace("✓ Average and statistic calculations verified");
	}

	/**
	 * Test: Snapshot pruning by age and count.
	 */
	static function testMonitorPruning():Void {
		trace("\nTEST: Monitor Pruning");

		// Test count-based pruning
		var monitor = new ResourceMonitor(3600000, 3); // Max 3 snapshots
		var baseTime = haxe.Timer.stamp() * 1000;

		monitor.addSnapshot(new HostResourceSnapshot(baseTime, 10.0, 1000, 4, 50));
		monitor.addSnapshot(new HostResourceSnapshot(baseTime + 1000, 20.0, 2000, 4, 100));
		monitor.addSnapshot(new HostResourceSnapshot(baseTime + 2000, 30.0, 3000, 4, 150));
		monitor.addSnapshot(new HostResourceSnapshot(baseTime + 3000, 40.0, 4000, 4, 200));

		assert(monitor.getSnapshotCount() == 3, "Should keep only 3 snapshots");
		assert(monitor.getOldestSnapshot().cpuUsagePercent == 20.0, "Oldest should be 20.0");

		// Test manual clearing
		monitor.clearAll();
		assert(monitor.getSnapshotCount() == 0, "Should clear all snapshots");

		trace("✓ Pruning working correctly");
	}

	/**
	 * Test: Delta calculations between snapshots.
	 */
	static function testSnapshotDeltas():Void {
		trace("\nTEST: Snapshot Delta Calculations");

		var time1 = haxe.Timer.stamp() * 1000;
		var snap1 = new HostResourceSnapshot(time1, 30.0, 2000, 4, 100);

		var time2 = time1 + 1000;
		var snap2 = new HostResourceSnapshot(time2, 50.0, 3000, 4, 150);

		var cpuDelta = snap2.getCpuDelta(snap1);
		assert(cpuDelta == 20.0, "CPU delta should be 20.0");

		var memDelta = snap2.getMemoryDelta(snap1);
		assert(memDelta == 1000, "Memory delta should be 1000");

		var timeDelta = snap2.getTimeDelta(snap1);
		assert(timeDelta == 1000, "Time delta should be 1000");

		trace("✓ Delta calculations verified");
	}

	// Test helper
	static function assert(condition:Bool, message:String):Void {
		if (!condition) {
			trace("✗ FAILED: " + message);
			throw new Error("Assertion failed: " + message);
		}
	}
}

// Simple Error class for testing
class Error {
	public var message:String;

	public function new(msg:String) {
		this.message = msg;
	}
}
