package digigun.virt.virtualbox;

/**
 * Physical or virtual USB device information.
 * 
 * Represents a USB device available on the host system or attached to a VM.
 * USB devices can be passed through to VMs using USB filters or direct attachment.
 * 
 * **Thread Safety:** Immutable - safe to share across threads.
 * 
 * Example:
 * ```haxe
 * var devices = vbox.getUSBDevices();
 * for (device in devices) {
 *     trace('${device.name} (${device.vendorId}:${device.productId})');
 * }
 * ```
 */
final class USBDevice {
	/**
	 * USB vendor ID (e.g., 0x1234).
	 * Uniquely identifies manufacturer with productId.
	 * Common: 0x046D = Logitech, 0x0951 = Kingston, 0x0955 = NVIDIA.
	 */
	public final vendorId:Int;

	/**
	 * USB product ID (e.g., 0x5678).
	 * Uniquely identifies product within a vendor.
	 */
	public final productId:Int;

	/**
	 * Device name/description (e.g., "Logitech USB Mouse").
	 * User-friendly name for the device.
	 */
	public final name:String;

	/**
	 * Device serial number (e.g., "123456789ABC").
	 * Unique per device instance (if device supports it).
	 * May be empty for devices without serial numbers.
	 */
	public final serialNumber:Null<String>;

	/**
	 * Device address (e.g., "1" or "2-1" for hub port).
	 * Platform-specific: "/dev/bus/usb/001/002" on Linux, device number on Windows.
	 */
	public final address:String;

	/**
	 * USB port/bus number (e.g., 1 for USB 1.1, 2 for USB 2.0).
	 * In VirtualBox context, usually refers to the port the device is on.
	 */
	public final port:Int;

	/**
	 * Whether device is currently available (not claimed by another VM).
	 * If false, device is already attached to a VM or in use.
	 */
	public final isAvailable:Bool;

	/**
	 * USB device version (e.g., 0x0200 for USB 2.0, 0x0100 for USB 1.0).
	 * Packed as BCD: upper byte = major, lower byte = minor.
	 */
	public final usbVersion:Int;

	/**
	 * Device class code (e.g., 0xFF for vendor-specific, 0x03 for HID).
	 * Identifies device type/purpose.
	 * Common: 0x00 = Device, 0x01 = Audio, 0x02 = CDC, 0x03 = HID, 0x07 = Printer, 0x09 = Hub, 0xFF = Vendor.
	 */
	public final classCode:Int;

	/**
	 * Device subclass code (refines classCode).
	 */
	public final subclassCode:Int;

	/**
	 * Device protocol (refines subclassCode).
	 */
	public final protocolCode:Int;

	/**
	 * Unique internal device identifier (UUID or similar).
	 * Used for attaching/detaching devices.
	 */
	public final deviceId:String;

	/**
	 * Creates a new USBDevice.
	 * 
	 * @param vendorId USB vendor ID (0x0000-0xFFFF)
	 * @param productId USB product ID (0x0000-0xFFFF)
	 * @param name Device name
	 * @param serialNumber Device serial number (optional)
	 * @param address Device address
	 * @param port Port number
	 * @param isAvailable Device available for attachment
	 * @param usbVersion USB version (e.g., 0x0200)
	 * @param classCode Device class code
	 * @param subclassCode Device subclass code
	 * @param protocolCode Device protocol code
	 * @param deviceId Internal device identifier
	 */
	public function new(
		vendorId:Int,
		productId:Int,
		name:String,
		?serialNumber:String,
		address:String = "0",
		port:Int = 0,
		isAvailable:Bool = true,
		usbVersion:Int = 0x0200,
		classCode:Int = 0xFF,
		subclassCode:Int = 0,
		protocolCode:Int = 0,
		deviceId:String = ""
	) {
		this.vendorId = vendorId;
		this.productId = productId;
		this.name = name;
		this.serialNumber = serialNumber;
		this.address = address;
		this.port = port;
		this.isAvailable = isAvailable;
		this.usbVersion = usbVersion;
		this.classCode = classCode;
		this.subclassCode = subclassCode;
		this.protocolCode = protocolCode;
		this.deviceId = deviceId;
	}

	/**
	 * Gets vendor ID as hex string (e.g., "046D").
	 */
	public function getVendorIdHex():String {
		return StringTools.hex(vendorId, 4);
	}

	/**
	 * Gets product ID as hex string (e.g., "C039").
	 */
	public function getProductIdHex():String {
		return StringTools.hex(productId, 4);
	}

	/**
	 * Gets USB device ID in standard format (e.g., "046D:C039").
	 */
	public function getUSBDeviceId():String {
		return getVendorIdHex() + ":" + getProductIdHex();
	}

	/**
	 * Gets human-readable description of the device.
	 * 
	 * @return String like "Logitech USB Mouse (046D:C039)"
	 */
	public function description():String {
		var id = getUSBDeviceId();
		if (serialNumber != null && serialNumber.length > 0) {
			return '${name} (${id}) [${serialNumber}]';
		}
		return '${name} (${id})';
	}

	/**
	 * Gets USB version as human-readable string.
	 * 
	 * @return String like "USB 2.0" or "Unknown"
	 */
	public function getUSBVersion():String {
		return switch (usbVersion) {
			case 0x0100: "USB 1.0";
			case 0x0110: "USB 1.1";
			case 0x0200: "USB 2.0";
			case 0x0210: "USB 2.0 High-Speed";
			case 0x0300: "USB 3.0";
			case 0x0310: "USB 3.1";
			case 0x0320: "USB 3.2";
			case v: "USB " + (v >> 8) + "." + (v & 0xFF);
		};
	}

	/**
	 * Gets device class name.
	 * 
	 * @return String like "Human Interface Device", "Vendor-Specific", etc.
	 */
	public function getClassName():String {
		return switch (classCode) {
			case 0x00: "Device";
			case 0x01: "Audio";
			case 0x02: "CDC";
			case 0x03: "Human Interface Device (HID)";
			case 0x05: "Physical Interface Device";
			case 0x06: "Image";
			case 0x07: "Printer";
			case 0x08: "Mass Storage";
			case 0x09: "Hub";
			case 0x0A: "CDC-Data";
			case 0x0B: "Smart Card";
			case 0x0D: "Content Security";
			case 0x0E: "Video";
			case 0x0F: "Personal Healthcare";
			case 0x10: "Audio/Video";
			case 0x11: "Billboard";
			case 0xDC: "Diagnostic Device";
			case 0xE0: "Wireless Controller";
			case 0xEF: "Miscellaneous";
			case 0xFE: "Application-Specific";
			case 0xFF: "Vendor-Specific";
			case c: "Unknown (0x" + StringTools.hex(c, 2) + ")";
		};
	}

	/**
	 * Checks if device is a human interface device (keyboard, mouse, etc).
	 */
	public function isHID():Bool {
		return classCode == 0x03;
	}

	/**
	 * Checks if device is a mass storage device (USB drive, external HDD, etc).
	 */
	public function isMassStorage():Bool {
		return classCode == 0x08;
	}

	/**
	 * Checks if device is a hub.
	 */
	public function isHub():Bool {
		return classCode == 0x09;
	}

	/**
	 * Checks if device is an audio device.
	 */
	public function isAudio():Bool {
		return classCode == 0x01;
	}

	/**
	 * Checks if device is a printer.
	 */
	public function isPrinter():Bool {
		return classCode == 0x07;
	}

	/**
	 * Checks if device class is vendor-specific.
	 */
	public function isVendorSpecific():Bool {
		return classCode == 0xFF;
	}

	/**
	 * Gets debug string representation.
	 */
	public function toString():String {
		return 'USBDevice{${description()}, ${getUSBVersion()}, ${getClassName()}}';
	}
}
