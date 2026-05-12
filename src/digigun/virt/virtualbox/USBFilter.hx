package digigun.virt.virtualbox;

/**
 * USB device filter for automatic device attachment.
 * 
 * USB filters define rules for automatically attaching matching USB devices to VMs.
 * Filters use patterns (wildcards) for vendor ID, product ID, serial number, etc.
 * 
 * When a matching USB device is plugged into the host, VirtualBox automatically
 * attaches it to the VM if this filter is enabled.
 * 
 * **Thread Safety:** Immutable - safe to share across threads.
 * 
 * Example:
 * ```haxe
 * // Auto-attach all Logitech USB devices
 * var filter = new USBFilter("Logitech USB Filter", "046D", null);
 * vbox.createUSBFilter(vm, filter);
 * ```
 */
final class USBFilter {
	/**
	 * User-defined filter name (e.g., "Phone Charger Filter").
	 * Used to identify filters in VM settings.
	 */
	public final name:String;

	/**
	 * Vendor ID pattern (e.g., "046D" or null for any).
	 * Can be exact ID or null to match any vendor.
	 */
	public final vendorIdPattern:Null<String>;

	/**
	 * Product ID pattern (e.g., "C039" or null for any).
	 * Can be exact ID or null to match any product.
	 */
	public final productIdPattern:Null<String>;

	/**
	 * Serial number pattern (e.g., "ABC123" or null for any).
	 * Supports wildcards (* for any characters).
	 * null matches any serial number.
	 */
	public final serialNumberPattern:Null<String>;

	/**
	 * Device name pattern (e.g., "*Logitech*" or null for any).
	 * Supports wildcards (* for any characters).
	 * null matches any name.
	 */
	public final namePattern:Null<String>;

	/**
	 * Port pattern (e.g., "2" for specific port, or null for any).
	 * Usually set to null unless binding to specific physical port.
	 */
	public final portPattern:Null<String>;

	/**
	 * Device class pattern (e.g., "03" for HID, or null for any).
	 * Hex device class code.
	 */
	public final classPattern:Null<String>;

	/**
	 * Remote flag: whether to apply on remote connections.
	 * If true, applies to devices attached via network.
	 */
	public final remote:Bool;

	/**
	 * Whether this filter is enabled.
	 * Disabled filters are ignored during device attachment.
	 */
	public final enabled:Bool;

	/**
	 * Unique filter identifier (UUID or similar).
	 * Set by VirtualBox when filter is created.
	 */
	public final filterId:String;

	/**
	 * Creates a new USBFilter.
	 * 
	 * @param name Filter name
	 * @param vendorIdPattern Vendor ID pattern or null
	 * @param productIdPattern Product ID pattern or null
	 * @param serialNumberPattern Serial number pattern or null
	 * @param namePattern Device name pattern or null
	 * @param portPattern Port pattern or null
	 * @param classPattern Device class pattern or null
	 * @param remote Apply to remote devices
	 * @param enabled Filter enabled
	 * @param filterId Internal filter ID
	 */
	public function new(
		name:String,
		?vendorIdPattern:String,
		?productIdPattern:String,
		?serialNumberPattern:String,
		?namePattern:String,
		?portPattern:String,
		?classPattern:String,
		remote:Bool = false,
		enabled:Bool = true,
		filterId:String = ""
	) {
		this.name = name;
		this.vendorIdPattern = vendorIdPattern;
		this.productIdPattern = productIdPattern;
		this.serialNumberPattern = serialNumberPattern;
		this.namePattern = namePattern;
		this.portPattern = portPattern;
		this.classPattern = classPattern;
		this.remote = remote;
		this.enabled = enabled;
		this.filterId = filterId;
	}

	/**
	 * Gets human-readable description of the filter.
	 * 
	 * @return String describing what devices this filter matches
	 */
	public function description():String {
		var parts = [];
		
		if (vendorIdPattern != null) {
			parts.push('Vendor: ${vendorIdPattern}');
		}
		
		if (productIdPattern != null) {
			parts.push('Product: ${productIdPattern}');
		}
		
		if (serialNumberPattern != null) {
			parts.push('Serial: ${serialNumberPattern}');
		}
		
		if (namePattern != null) {
			parts.push('Name: ${namePattern}');
		}
		
		if (classPattern != null) {
			parts.push('Class: ${classPattern}');
		}
		
		if (parts.length == 0) {
			return "Match any USB device";
		}
		
		return parts.join(", ");
	}

	/**
	 * Checks if filter is specific (has at least one constraint).
	 * Catch-all filters (no constraints) may interfere with other filters.
	 * 
	 * @return False if filter matches any device, true if has constraints
	 */
	public function isSpecific():Bool {
		return vendorIdPattern != null 
			|| productIdPattern != null
			|| serialNumberPattern != null
			|| namePattern != null
			|| portPattern != null
			|| classPattern != null;
	}

	/**
	 * Checks how specific this filter is (number of constraints).
	 * More specific filters have higher priority.
	 * 
	 * @return Number of constraints (0-6)
	 */
	public function getSpecificity():Int {
		var count = 0;
		if (vendorIdPattern != null) count++;
		if (productIdPattern != null) count++;
		if (serialNumberPattern != null) count++;
		if (namePattern != null) count++;
		if (portPattern != null) count++;
		if (classPattern != null) count++;
		return count;
	}

	/**
	 * Checks if filter pattern uses wildcards.
	 * Wildcard patterns are less deterministic.
	 * 
	 * @return True if any pattern contains asterisks
	 */
	public function hasWildcards():Bool {
		function hasWildcard(s:Null<String>):Bool {
			return s != null && s.indexOf("*") >= 0;
		}
		
		return hasWildcard(serialNumberPattern) 
			|| hasWildcard(namePattern)
			|| hasWildcard(portPattern)
			|| hasWildcard(classPattern);
	}

	/**
	 * Checks if filter matches a specific USB device.
	 * This is a simple pattern matching check, not the full VirtualBox logic.
	 * 
	 * @param device Device to check
	 * @return True if device matches this filter's patterns
	 */
	public function matches(device:USBDevice):Bool {
		// Check vendor ID
		if (vendorIdPattern != null && vendorIdPattern != device.getVendorIdHex()) {
			return false;
		}
		
		// Check product ID
		if (productIdPattern != null && productIdPattern != device.getProductIdHex()) {
			return false;
		}
		
		// Check serial number (simple wildcard matching)
		if (serialNumberPattern != null && device.serialNumber != null) {
			if (!matchesPattern(device.serialNumber, serialNumberPattern)) {
				return false;
			}
		}
		
		// Check name (simple wildcard matching)
		if (namePattern != null) {
			if (!matchesPattern(device.name, namePattern)) {
				return false;
			}
		}
		
		return true;
	}

	/**
	 * Simple wildcard pattern matching (supports * for any characters).
	 */
	private static function matchesPattern(text:String, pattern:String):Bool {
		if (pattern.indexOf("*") < 0) {
			// No wildcards, exact match
			return text == pattern;
		}
		
		// Simple wildcard matching
		var parts = pattern.split("*");
		var pos = 0;
		
		for (i in 0...parts.length) {
			var part = parts[i];
			if (part.length == 0) continue;
			
			var idx = text.indexOf(part, pos);
			if (idx < pos) {
				return false;
			}
			pos = idx + part.length;
		}
		
		return true;
	}

	/**
	 * Gets a recommended filter specificity level (1 = loose, 3 = medium, 5+ = tight).
	 * Useful for advising users on filter design.
	 */
	public function getRecommendedSpecificity():String {
		var spec = getSpecificity();
		return switch (spec) {
			case 0: "Too loose (match any device)";
			case 1: "Loose (vendor only)";
			case 2: "Medium (vendor + product)";
			case 3...: "Tight (multiple constraints)";
		};
	}

	/**
	 * Gets debug string representation.
	 */
	public function toString():String {
		return 'USBFilter{${name}, ${description()}, specificity=${getSpecificity()}}';
	}
}
