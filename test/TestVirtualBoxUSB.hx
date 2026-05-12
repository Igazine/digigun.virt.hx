package;

import digigun.virt.virtualbox.USBDevice;
import digigun.virt.virtualbox.USBFilter;

/**
	Comprehensive test suite for USB management operations.
**/
class TestVirtualBoxUSB {
	static function testUSBDeviceCreation() {
		trace("testUSBDeviceCreation: Testing USB device creation");

		var device = new USBDevice(0x046D, 0xC039, "Logitech USB Mouse");
		assert(device.vendorId == 0x046D, "Vendor ID should match");
		assert(device.productId == 0xC039, "Product ID should match");
		assert(device.name == "Logitech USB Mouse", "Name should match");
		assert(device.isAvailable == true, "Device should be available by default");
		trace("  ✓ USB device: " + device.description());
	}

	static function testUSBDeviceHexIds() {
		trace("testUSBDeviceHexIds: Testing hex ID formatting");

		var device = new USBDevice(0x046D, 0xC039, "Logitech Mouse");
		assert(device.getVendorIdHex() == "046D", "Vendor ID hex should be 046D");
		assert(device.getProductIdHex() == "C039", "Product ID hex should be C039");
		var usbId = device.getUSBDeviceId();
		assert(usbId == "046D:C039", "USB ID should be 046D:C039");
		trace("  ✓ USB ID: " + usbId);
	}

	static function testUSBDeviceVersion() {
		trace("testUSBDeviceVersion: Testing USB version detection");

		var usb10 = new USBDevice(0x1234, 0x5678, "Old Device", null, "0", 0, true, 0x0100);
		assert(usb10.getUSBVersion() == "USB 1.0", "Should detect USB 1.0");

		var usb20 = new USBDevice(0x1234, 0x5678, "Mouse", null, "0", 0, true, 0x0200);
		assert(usb20.getUSBVersion() == "USB 2.0", "Should detect USB 2.0");

		var usb30 = new USBDevice(0x1234, 0x5678, "Drive", null, "0", 0, true, 0x0300);
		assert(usb30.getUSBVersion() == "USB 3.0", "Should detect USB 3.0");

		trace("  ✓ USB version detection works");
	}

	static function testUSBDeviceClass() {
		trace("testUSBDeviceClass: Testing device class detection");

		// HID (Keyboard/Mouse)
		var hid = new USBDevice(0x1234, 0x5678, "Keyboard", null, "0", 0, true, 0x0200, 0x03);
		assert(hid.isHID() == true, "Should be HID");
		assert(hid.getClassName().indexOf("Human Interface") >= 0, "Should describe as HID");

		// Mass Storage (USB Drive)
		var storage = new USBDevice(0x1234, 0x5678, "USB Drive", null, "0", 0, true, 0x0200, 0x08);
		assert(storage.isMassStorage() == true, "Should be mass storage");

		// Audio
		var audio = new USBDevice(0x1234, 0x5678, "Headset", null, "0", 0, true, 0x0200, 0x01);
		assert(audio.isAudio() == true, "Should be audio");

		// Printer
		var printer = new USBDevice(0x1234, 0x5678, "Printer", null, "0", 0, true, 0x0200, 0x07);
		assert(printer.isPrinter() == true, "Should be printer");

		trace("  ✓ Device class detection works");
	}

	static function testUSBFilterCreation() {
		trace("testUSBFilterCreation: Testing USB filter creation");

		var filter = new USBFilter("Logitech Filter", "046D", "C039");
		assert(filter.name == "Logitech Filter", "Name should match");
		assert(filter.vendorIdPattern == "046D", "Vendor pattern should match");
		assert(filter.productIdPattern == "C039", "Product pattern should match");
		assert(filter.enabled == true, "Filter should be enabled by default");
		trace("  ✓ USB filter: " + filter.name);
	}

	static function testUSBFilterSpecificity() {
		trace("testUSBFilterSpecificity: Testing filter specificity");

		// Catch-all filter
		var catchAll = new USBFilter("Catch All");
		assert(catchAll.isSpecific() == false, "Catch-all should not be specific");
		assert(catchAll.getSpecificity() == 0, "Specificity should be 0");

		// Vendor-only filter
		var vendor = new USBFilter("Vendor Only", "046D", null);
		assert(vendor.isSpecific() == true, "Vendor filter should be specific");
		assert(vendor.getSpecificity() == 1, "Specificity should be 1");

		// Vendor + Product
		var specific = new USBFilter("Specific", "046D", "C039");
		assert(specific.getSpecificity() == 2, "Specificity should be 2");

		trace("  ✓ Filter specificity calculation works");
	}

	static function testUSBFilterMatching() {
		trace("testUSBFilterMatching: Testing filter matching");

		var device = new USBDevice(0x046D, 0xC039, "Logitech Mouse");
		
		// Exact vendor + product match
		var filter = new USBFilter("Exact", "046D", "C039");
		assert(filter.matches(device) == true, "Should match exact vendor:product");

		// Vendor only match
		var vendorFilter = new USBFilter("Vendor", "046D", null);
		assert(vendorFilter.matches(device) == true, "Should match vendor only");

		// Non-matching product
		var wrongProduct = new USBFilter("Wrong", "046D", "FFFF");
		assert(wrongProduct.matches(device) == false, "Should not match wrong product");

		trace("  ✓ Filter matching works");
	}

	static function testUSBFilterWildcards() {
		trace("testUSBFilterWildcards: Testing wildcard patterns");

		// Filter with wildcard serial
		var filter = new USBFilter("Wildcard", null, null, "ABC*");
		assert(filter.hasWildcards() == true, "Should have wildcards");
		assert(filter.getSpecificity() == 1, "Wildcard serial should count as constraint");

		// Filter without wildcards
		var exact = new USBFilter("Exact", "046D", "C039");
		assert(exact.hasWildcards() == false, "Should not have wildcards");

		trace("  ✓ Wildcard detection works");
	}

	static function testUSBDeviceAvailability() {
		trace("testUSBDeviceAvailability: Testing device availability");

		var available = new USBDevice(0x046D, 0xC039, "Mouse", null, "0", 0, true);
		assert(available.isAvailable == true, "Device should be available");

		var unavailable = new USBDevice(0x046D, 0xC039, "Mouse", null, "0", 0, false);
		assert(unavailable.isAvailable == false, "Device should be unavailable");

		trace("  ✓ Device availability tracking works");
	}

	static function testUSBDeviceSerial() {
		trace("testUSBDeviceSerial: Testing serial number handling");

		// Device with serial
		var withSerial = new USBDevice(0x1234, 0x5678, "Device", "SN123456");
		assert(withSerial.serialNumber == "SN123456", "Serial should be stored");
		var desc = withSerial.description();
		assert(desc.indexOf("SN123456") >= 0, "Serial should appear in description");

		// Device without serial
		var noSerial = new USBDevice(0x1234, 0x5678, "Device");
		assert(noSerial.serialNumber == null, "Serial should be null");

		trace("  ✓ Serial number handling works");
	}

	static function testUSBFilterRecommendation() {
		trace("testUSBFilterRecommendation: Testing filter specificity recommendation");

		var catchAll = new USBFilter("All");
		assert(catchAll.getRecommendedSpecificity().indexOf("Too loose") >= 0, "Should warn catch-all");

		var vendor = new USBFilter("Vendor", "046D", null);
		assert(vendor.getRecommendedSpecificity().indexOf("Loose") >= 0, "Should recommend vendor");

		var tight = new USBFilter("Tight", "046D", "C039", "SN123");
		assert(tight.getRecommendedSpecificity().indexOf("Tight") >= 0, "Should recommend tight");

		trace("  ✓ Filter recommendations work");
	}

	static function assert(condition:Bool, message:String) {
		if (!condition) {
			throw new haxe.Exception("Assertion failed: " + message);
		}
	}

	static function main() {
		trace("=== VirtualBox USB Management Test Suite ===\n");

		try {
			testUSBDeviceCreation();
			trace("");
			testUSBDeviceHexIds();
			trace("");
			testUSBDeviceVersion();
			trace("");
			testUSBDeviceClass();
			trace("");
			testUSBFilterCreation();
			trace("");
			testUSBFilterSpecificity();
			trace("");
			testUSBFilterMatching();
			trace("");
			testUSBFilterWildcards();
			trace("");
			testUSBDeviceAvailability();
			trace("");
			testUSBDeviceSerial();
			trace("");
			testUSBFilterRecommendation();

			trace("\n=== All tests passed! ===");
		} catch (e:Dynamic) {
			trace("\n❌ Test failed: " + Std.string(e));
			throw e;
		}
	}
}
