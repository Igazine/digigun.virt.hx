package digigun.virt.virtualbox;

/**
 * Tracks resource metrics over time and provides analysis capabilities.
 * 
 * Maintains a list of resource snapshots and calculates trends,
 * averages, and deltas between measurements.
 */
class ResourceMonitor {
	/**
	 * List of resource snapshots ordered by timestamp
	 */
	private var snapshots:Array<HostResourceSnapshot> = [];

	/**
	 * Maximum age (in milliseconds) to keep snapshots.
	 * Snapshots older than this are automatically pruned.
	 */
	private var maxSnapshotAge:Float = 3600000; // 1 hour default

	/**
	 * Maximum number of snapshots to keep.
	 * When exceeded, oldest snapshots are removed.
	 */
	private var maxSnapshots:Int = 1000;

	/**
	 * Create a new resource monitor.
	 * 
	 * @param maxSnapshotAgeMs Maximum age for snapshots in milliseconds (default 1 hour)
	 * @param maxSnapshotsCount Maximum number of snapshots to store (default 1000)
	 */
	public function new(maxSnapshotAgeMs:Float = 3600000, maxSnapshotsCount:Int = 1000) {
		this.maxSnapshotAge = maxSnapshotAgeMs;
		this.maxSnapshots = maxSnapshotsCount;
	}

	/**
	 * Add a new resource snapshot to the monitor.
	 * 
	 * Automatically prunes old snapshots based on age and count limits.
	 * 
	 * @param snapshot New snapshot to add
	 */
	public function addSnapshot(snapshot:HostResourceSnapshot):Void {
		snapshots.push(snapshot);
		pruneSnapshots();
	}

	/**
	 * Get the most recent snapshot, if available.
	 * 
	 * @return Latest snapshot or null if no snapshots exist
	 */
	public function getLatestSnapshot():Null<HostResourceSnapshot> {
		return snapshots.length > 0 ? snapshots[snapshots.length - 1] : null;
	}

	/**
	 * Get the oldest snapshot currently stored.
	 * 
	 * @return Oldest snapshot or null if no snapshots exist
	 */
	public function getOldestSnapshot():Null<HostResourceSnapshot> {
		return snapshots.length > 0 ? snapshots[0] : null;
	}

	/**
	 * Get the number of snapshots currently stored.
	 * 
	 * @return Snapshot count
	 */
	public function getSnapshotCount():Int {
		return snapshots.length;
	}

	/**
	 * Get all snapshots as an array.
	 * 
	 * @return Copy of snapshots array
	 */
	public function getAllSnapshots():Array<HostResourceSnapshot> {
		return snapshots.copy();
	}

	/**
	 * Get the change metrics since the last snapshot.
	 * 
	 * Compares the most recent snapshot with the one before it.
	 * Returns null if fewer than 2 snapshots are available.
	 * 
	 * @return Object with cpuDelta, memoryDelta, and timeDelta, or null
	 */
	public function getDeltaSinceLast():Null<{cpuDelta:Float, memoryDelta:Int, timeDelta:Float}> {
		if (snapshots.length < 2)
			return null;

		var current = snapshots[snapshots.length - 1];
		var previous = snapshots[snapshots.length - 2];

		return {
			cpuDelta: current.getCpuDelta(previous),
			memoryDelta: current.getMemoryDelta(previous),
			timeDelta: current.getTimeDelta(previous)
		};
	}

	/**
	 * Calculate average CPU usage across all snapshots.
	 * 
	 * @return Average CPU usage percentage, or 0 if no snapshots
	 */
	public function getAverageCpuUsage():Float {
		if (snapshots.length == 0)
			return 0;

		var total:Float = 0;
		for (snapshot in snapshots) {
			total += snapshot.cpuUsagePercent;
		}
		return total / snapshots.length;
	}

	/**
	 * Calculate average memory usage across all snapshots.
	 * 
	 * @return Average memory used in MB, or 0 if no snapshots
	 */
	public function getAverageMemoryUsage():Float {
		if (snapshots.length == 0)
			return 0;

		var total:Float = 0;
		for (snapshot in snapshots) {
			total += snapshot.memoryUsedMB;
		}
		return total / snapshots.length;
	}

	/**
	 * Get minimum CPU usage in the snapshot history.
	 * 
	 * @return Minimum CPU percentage, or 0 if no snapshots
	 */
	public function getMinCpuUsage():Float {
		if (snapshots.length == 0)
			return 0;

		var min = snapshots[0].cpuUsagePercent;
		for (snapshot in snapshots) {
			if (snapshot.cpuUsagePercent < min)
				min = snapshot.cpuUsagePercent;
		}
		return min;
	}

	/**
	 * Get maximum CPU usage in the snapshot history.
	 * 
	 * @return Maximum CPU percentage, or 0 if no snapshots
	 */
	public function getMaxCpuUsage():Float {
		if (snapshots.length == 0)
			return 0;

		var max = snapshots[0].cpuUsagePercent;
		for (snapshot in snapshots) {
			if (snapshot.cpuUsagePercent > max)
				max = snapshot.cpuUsagePercent;
		}
		return max;
	}

	/**
	 * Get minimum memory usage in the snapshot history.
	 * 
	 * @return Minimum memory in MB, or 0 if no snapshots
	 */
	public function getMinMemoryUsage():Int {
		if (snapshots.length == 0)
			return 0;

		var min = snapshots[0].memoryUsedMB;
		for (snapshot in snapshots) {
			if (snapshot.memoryUsedMB < min)
				min = snapshot.memoryUsedMB;
		}
		return min;
	}

	/**
	 * Get maximum memory usage in the snapshot history.
	 * 
	 * @return Maximum memory in MB, or 0 if no snapshots
	 */
	public function getMaxMemoryUsage():Int {
		if (snapshots.length == 0)
			return 0;

		var max = snapshots[0].memoryUsedMB;
		for (snapshot in snapshots) {
			if (snapshot.memoryUsedMB > max)
				max = snapshot.memoryUsedMB;
		}
		return max;
	}

	/**
	 * Clear all snapshots older than the specified age.
	 * 
	 * @param maxAgeMs Maximum age to keep in milliseconds
	 */
	public function clearOldSnapshots(maxAgeMs:Float):Void {
		var cutoff = haxe.Timer.stamp() * 1000 - maxAgeMs;
		snapshots = snapshots.filter(s -> s.timestamp >= cutoff);
	}

	/**
	 * Clear all snapshots from the monitor.
	 */
	public function clearAll():Void {
		snapshots = [];
	}

	/**
	 * Get a statistics summary of current snapshots.
	 * 
	 * @return Object with average, min, max for CPU and memory
	 */
	public function getStatistics():Dynamic {
		return {
			snapshotCount: snapshots.length,
			cpuAverage: getAverageCpuUsage(),
			cpuMin: getMinCpuUsage(),
			cpuMax: getMaxCpuUsage(),
			memoryAverageBytes: Math.round(getAverageMemoryUsage() * 1024 * 1024),
			memoryMinBytes: getMinMemoryUsage() * 1024 * 1024,
			memoryMaxBytes: getMaxMemoryUsage() * 1024 * 1024,
			timeSpanMs: snapshots.length >= 2 ? getLatestSnapshot().getTimeDelta(getOldestSnapshot()) : 0
		};
	}

	/**
	 * Prune snapshots based on age and count limits.
	 * 
	 * Removes oldest snapshots when either:
	 * - Total snapshot count exceeds maxSnapshots
	 * - Individual snapshot age exceeds maxSnapshotAge
	 * 
	 * Private helper method.
	 */
	private function pruneSnapshots():Void {
		// Remove by age
		clearOldSnapshots(maxSnapshotAge);

		// Remove by count (keep latest N)
		if (snapshots.length > maxSnapshots) {
			var toRemove = snapshots.length - maxSnapshots;
			snapshots = snapshots.slice(toRemove);
		}
	}

	/**
	 * Set maximum snapshot age for auto-pruning.
	 * 
	 * @param maxAgeMs Age limit in milliseconds
	 */
	public function setMaxSnapshotAge(maxAgeMs:Float):Void {
		maxSnapshotAge = maxAgeMs;
		pruneSnapshots();
	}

	/**
	 * Set maximum number of snapshots to keep.
	 * 
	 * @param maxCount Maximum snapshot count
	 */
	public function setMaxSnapshots(maxCount:Int):Void {
		maxSnapshots = maxCount;
		pruneSnapshots();
	}

	/**
	 * Get current memory metrics.
	 * 
	 * Returns memory info as object with stats.
	 * 
	 * @return Object with averageUsedMB, minUsedMB, maxUsedMB
	 */
	public function getMemoryMetrics():Dynamic {
		return {
			averageUsedMB: Math.round(getAverageMemoryUsage() * 100) / 100,
			minUsedMB: getMinMemoryUsage(),
			maxUsedMB: getMaxMemoryUsage()
		};
	}

	/**
	 * Get current CPU metrics.
	 * 
	 * @return Object with averagePercent, minPercent, maxPercent
	 */
	public function getCpuMetrics():Dynamic {
		return {
			averagePercent: Math.round(getAverageCpuUsage() * 100) / 100,
			minPercent: Math.round(getMinCpuUsage() * 100) / 100,
			maxPercent: Math.round(getMaxCpuUsage() * 100) / 100
		};
	}
}
