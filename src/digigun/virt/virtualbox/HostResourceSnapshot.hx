package digigun.virt.virtualbox;

/**
 * A point-in-time snapshot of host system resource metrics.
 * 
 * Captures CPU and memory utilization along with a timestamp.
 * Used for resource monitoring and change tracking over time.
 */
class HostResourceSnapshot {
	/**
	 * Millisecond timestamp when this snapshot was taken
	 */
	public final timestamp:Float;

	/**
	 * CPU usage percentage (0-100)
	 */
	public final cpuUsagePercent:Float;

	/**
	 * Memory used in MB
	 */
	public final memoryUsedMB:Int;

	/**
	 * Total number of logical CPUs
	 */
	public final cpuCount:Int;

	/**
	 * Number of currently active threads
	 */
	public final activeThreads:Int;

	/**
	 * Create a new resource snapshot with the given metrics.
	 * 
	 * @param timestamp Milliseconds since epoch when snapshot was taken
	 * @param cpuUsagePercent CPU usage as percentage (0-100)
	 * @param memoryUsedMB Memory used in megabytes
	 * @param cpuCount Total logical CPU count
	 * @param activeThreads Number of active system threads
	 */
	public function new(
		timestamp:Float,
		cpuUsagePercent:Float,
		memoryUsedMB:Int,
		cpuCount:Int,
		activeThreads:Int
	) {
		this.timestamp = timestamp;
		this.cpuUsagePercent = cpuUsagePercent;
		this.memoryUsedMB = memoryUsedMB;
		this.cpuCount = cpuCount;
		this.activeThreads = activeThreads;
	}

	/**
	 * Get the timestamp when this snapshot was taken.
	 * 
	 * @return Milliseconds since epoch
	 */
	public function getTimestamp():Float {
		return timestamp;
	}

	/**
	 * Get the age of this snapshot in milliseconds.
	 * 
	 * @return Age in ms (current time minus snapshot time)
	 */
	public function getAgeMs():Float {
		return haxe.Timer.stamp() * 1000 - timestamp;
	}

	/**
	 * Get a human-readable summary of the metrics.
	 * 
	 * Format: "CPU: X%, Memory: Y MB, Threads: Z"
	 * 
	 * @return Formatted summary string
	 */
	public function getMetricsSummary():String {
		var cpuStr = StringTools.replace(
			'${Math.round(cpuUsagePercent * 100) / 100}',
			'.',
			'.'
		);
		return 'CPU: ${cpuStr}%, Memory: ${memoryUsedMB} MB, Threads: ${activeThreads}';
	}

	/**
	 * Get a detailed string representation of this snapshot.
	 * 
	 * @return Detailed string including timestamp and all metrics
	 */
	public function toString():String {
		var date = DateTools.format(
			new Date(Math.round(timestamp)),
			'%Y-%m-%d %H:%M:%S'
		);
		return 'HostResourceSnapshot[${date}, ${getMetricsSummary()}]';
	}

	/**
	 * Calculate the change in CPU usage since another snapshot.
	 * 
	 * @param other Previous snapshot to compare against
	 * @return CPU usage delta (current - previous)
	 */
	public function getCpuDelta(other:HostResourceSnapshot):Float {
		return cpuUsagePercent - other.cpuUsagePercent;
	}

	/**
	 * Calculate the change in memory usage since another snapshot.
	 * 
	 * @param other Previous snapshot to compare against
	 * @return Memory usage delta in MB (current - previous)
	 */
	public function getMemoryDelta(other:HostResourceSnapshot):Int {
		return memoryUsedMB - other.memoryUsedMB;
	}

	/**
	 * Calculate the time elapsed since another snapshot.
	 * 
	 * @param other Previous snapshot
	 * @return Time delta in milliseconds
	 */
	public function getTimeDelta(other:HostResourceSnapshot):Float {
		return timestamp - other.timestamp;
	}

	/**
	 * Calculate average CPU usage rate between snapshots.
	 * 
	 * @param other Previous snapshot
	 * @return Average CPU usage percent per millisecond
	 */
	public function getCpuRateBetween(other:HostResourceSnapshot):Float {
		var timeDelta = getTimeDelta(other);
		if (timeDelta == 0)
			return 0;
		return getCpuDelta(other) / timeDelta;
	}

	/**
	 * Calculate average memory change rate between snapshots.
	 * 
	 * @param other Previous snapshot
	 * @return Average memory change in MB per millisecond
	 */
	public function getMemoryRateBetween(other:HostResourceSnapshot):Float {
		var timeDelta = getTimeDelta(other);
		if (timeDelta == 0)
			return 0;
		return getMemoryDelta(other) / timeDelta;
	}
}
