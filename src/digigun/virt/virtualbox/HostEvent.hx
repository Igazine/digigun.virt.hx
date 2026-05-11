package digigun.virt.virtualbox;

/**
	HostEvent represents a VirtualBox event occurrence.
	
	This is an immutable snapshot of an event at a point in time,
	capturing the event type, timestamp, and source information.
**/
class HostEvent {
	/**
		The type of event that occurred.
	**/
	public final eventType:EventType;

	/**
		Timestamp when the event occurred (milliseconds since Unix epoch).
	**/
	public final timestamp:Float;

	/**
		Name of the VM that triggered the event (if applicable).
		Empty string if event originated from host.
	**/
	public final vmName:String;

	/**
		Human-readable event description.
	**/
	public final description:String;

	/**
		Event details map for event-specific information.
		For example, media events may include medium ID or attachment point.
	**/
	public final details:Map<String, String>;

	/**
		Creates a new HostEvent instance.
		
		@param eventType The type of event
		@param timestamp Timestamp in milliseconds (defaults to current time)
		@param vmName Name of the VM (empty for host events)
		@param description Human-readable event description
		@param details Event-specific details (optional)
	**/
	public function new(eventType:EventType, ?timestamp:Float, vmName:String = "", description:String = "", ?details:Map<String, String>) {
		this.eventType = eventType;
		this.timestamp = timestamp != null ? timestamp : (haxe.Timer.stamp() * 1000);
		this.vmName = vmName;
		this.description = description != null ? description : eventType.description();
		this.details = details != null ? details : new Map<String, String>();
	}

	/**
		Get the event category.
	**/
	public function getCategory():String {
		return eventType.category();
	}

	/**
		Check if this is a critical event.
	**/
	public function isCritical():Bool {
		return eventType.isCritical();
	}

	/**
		Get the age of this event in milliseconds.
	**/
	public function getAgeMs():Float {
		var now = haxe.Timer.stamp() * 1000;
		return now - timestamp;
	}

	/**
		Get a formatted timestamp string (ISO 8601 format).
	**/
	public function getFormattedTimestamp():String {
		// Convert milliseconds to seconds for Date
		var seconds:Float = timestamp / 1000.0;
		var date = Date.fromTime(seconds * 1000);
		return DateTools.format(date, "%Y-%m-%d %H:%M:%S");
	}

	/**
		Get detail value by key.
		
		@param key The detail key to retrieve
		@param defaultValue Value to return if key not found
		@return The detail value or defaultValue if not found
	**/
	public function getDetail(key:String, defaultValue:String = ""):String {
		return details.exists(key) ? details.get(key) : defaultValue;
	}

	/**
		Check if a detail exists.
	**/
	public function hasDetail(key:String):Bool {
		return details.exists(key);
	}

	/**
		Get formatted event summary.
	**/
	public function toString():String {
		var source = vmName.length > 0 ? 'VM: $vmName' : "Host";
		return '[${getFormattedTimestamp()}] [$source] ${eventType}: $description';
	}

	/**
		Get detailed event information including all details.
	**/
	public function toDetailedString():String {
		var buf = new StringBuf();
		buf.add(toString());

		var keyCount = 0;
		for (_ in details.keys()) keyCount++;
		
		if (keyCount > 0) {
			buf.add("\n  Details:");
			for (key in details.keys()) {
				buf.add('\n    - $key: ${details.get(key)}');
			}
		}

		return buf.toString();
	}

	/**
		Compare two events by timestamp (for sorting).
	**/
	public static function compareByTime(a:HostEvent, b:HostEvent):Int {
		if (a.timestamp < b.timestamp) return -1;
		if (a.timestamp > b.timestamp) return 1;
		return 0;
	}

	/**
		Compare two events by type (for grouping).
	**/
	public static function compareByType(a:HostEvent, b:HostEvent):Int {
		var aType = a.eventType.toString();
		var bType = b.eventType.toString();
		if (aType < bType) return -1;
		if (aType > bType) return 1;
		return 0;
	}
}
