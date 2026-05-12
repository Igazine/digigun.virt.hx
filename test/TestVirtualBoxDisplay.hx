package;

import digigun.virt.virtualbox.RemoteDisplayInfo;
import digigun.virt.virtualbox.DisplayFrameBuffer;

/**
	Comprehensive test suite for display management operations.
**/
class TestVirtualBoxDisplay {
	static function testRemoteDisplayInfoRDP() {
		trace("testRemoteDisplayInfoRDP: Testing RDP configuration");

		var display = new RemoteDisplayInfo(
			true,    // rdpEnabled
			3389,    // rdpPort
			false    // vncEnabled
		);

		assert(display.rdpEnabled == true, "RDP should be enabled");
		assert(display.rdpPort == 3389, "RDP port should be 3389");
		assert(display.vncEnabled == false, "VNC should be disabled");
		assert(display.isRemoteDisplayAvailable() == true, "Remote display should be available");
		trace("  ✓ RDP: " + display.description());
	}

	static function testRemoteDisplayInfoVNC() {
		trace("testRemoteDisplayInfoVNC: Testing VNC configuration");

		var display = new RemoteDisplayInfo(
			false,                   // rdpEnabled
			null,                    // rdpPort
			true,                    // vncEnabled
			5900,                    // vncPort
			"127.0.0.1"              // vncAddress
		);

		assert(display.vncEnabled == true, "VNC should be enabled");
		assert(display.vncPort == 5900, "VNC port should be 5900");
		assert(display.vncAddress == "127.0.0.1", "VNC address should be 127.0.0.1");
		assert(display.isRemoteDisplayAvailable() == true, "Remote display should be available");
		trace("  ✓ VNC: " + display.description());
	}

	static function testRemoteDisplayInfoDualDisplay() {
		trace("testRemoteDisplayInfoDualDisplay: Testing both RDP and VNC");

		var display = new RemoteDisplayInfo(
			true,        // rdpEnabled
			3389,        // rdpPort
			true,        // vncEnabled
			5900,        // vncPort
			"localhost"  // vncAddress
		);

		assert(display.rdpEnabled == true, "RDP should be enabled");
		assert(display.vncEnabled == true, "VNC should be enabled");
		assert(display.isRemoteDisplayAvailable() == true, "Remote display should be available");
		var desc = display.description();
		assert(desc.indexOf("RDP") >= 0, "Description should mention RDP");
		assert(desc.indexOf("VNC") >= 0, "Description should mention VNC");
		trace("  ✓ Dual display: " + display.description());
	}

	static function testRemoteDisplayInfoNoDisplay() {
		trace("testRemoteDisplayInfoNoDisplay: Testing no display configured");

		var display = new RemoteDisplayInfo(false);

		assert(display.rdpEnabled == false, "RDP should be disabled");
		assert(display.vncEnabled == false, "VNC should be disabled");
		assert(display.isRemoteDisplayAvailable() == false, "Remote display should not be available");
		var desc = display.description();
		assert(desc.indexOf("No remote display") >= 0, "Description should indicate no display");
		trace("  ✓ No display: " + display.description());
	}

	static function testRemoteDisplayResolution() {
		trace("testRemoteDisplayResolution: Testing resolution information");

		var display = new RemoteDisplayInfo(
			true,
			3389,
			true,
			5900,
			"localhost",
			1920,  // displayWidth
			1080   // displayHeight
		);

		assert(display.displayWidth == 1920, "Width should be 1920");
		assert(display.displayHeight == 1080, "Height should be 1080");
		var resolution = display.getResolution();
		assert(resolution == "1920x1080", "Resolution should be 1920x1080");
		trace("  ✓ Resolution: " + resolution);
	}

	static function testRemoteDisplayColorFormat() {
		trace("testRemoteDisplayColorFormat: Testing color format");

		var display = new RemoteDisplayInfo(
			true,
			3389,
			false,
			null,
			null,
			1024,  // displayWidth
			768,   // displayHeight
			32     // displayBitDepth (RGBA)
		);

		var format = display.getColorFormat();
		assert(format.indexOf("32") >= 0, "Format should mention 32-bit");
		assert(format.indexOf("RGBA") >= 0, "Format should mention RGBA");
		trace("  ✓ Color format: " + format);
	}

	static function testDisplayFrameBufferValid() {
		trace("testDisplayFrameBufferValid: Testing valid frame buffer");

		var fb = new DisplayFrameBuffer(
			0,           // displayIndex
			1920,        // width
			1080,        // height
			32,          // bitsPerPixel
			7680,        // bytesPerLine (1920 * 4)
			"RGBA",      // pixelFormat
			"0x12345678",// pixelDataPtr
			8294400,     // bufferSize
			true         // isValid
		);

		assert(fb.displayIndex == 0, "Display index should be 0");
		assert(fb.width == 1920, "Width should be 1920");
		assert(fb.height == 1080, "Height should be 1080");
		assert(fb.isValid == true, "Frame buffer should be valid");
		trace("  ✓ Valid frame buffer: " + fb.description());
	}

	static function testDisplayFrameBufferResolution() {
		trace("testDisplayFrameBufferResolution: Testing resolution parsing");

		var fb = new DisplayFrameBuffer(
			0,
			2560,        // width
			1440,        // height
			24,          // bitsPerPixel
			7680,        // bytesPerLine
			"RGB"        // pixelFormat
		);

		var resolution = fb.getResolution();
		assert(resolution == "2560x1440", "Resolution should be 2560x1440");
		var colorFormat = fb.getColorFormatDescription();
		assert(colorFormat.indexOf("24") >= 0, "Color format should mention 24-bit");
		trace("  ✓ Resolution: " + resolution + ", Format: " + colorFormat);
	}

	static function testDisplayFrameBufferUnavailable() {
		trace("testDisplayFrameBufferUnavailable: Testing unavailable frame buffer");

		var fb = new DisplayFrameBuffer();

		assert(fb.isValid == false, "Frame buffer should not be valid");
		assert(fb.width == 0, "Width should be 0");
		assert(fb.height == 0, "Height should be 0");
		var resolution = fb.getResolution();
		assert(resolution == "Unavailable", "Resolution should be Unavailable");
		trace("  ✓ Unavailable frame buffer: " + fb.description());
	}

	static function testDisplayFrameBufferColorFormats() {
		trace("testDisplayFrameBufferColorFormats: Testing different color formats");

		// 8-bit paletted
		var fb8 = new DisplayFrameBuffer(0, 640, 480, 8);
		assert(fb8.getColorFormatDescription().indexOf("8-bit") >= 0, "Should show 8-bit");

		// 16-bit RGB565
		var fb16 = new DisplayFrameBuffer(0, 640, 480, 16);
		assert(fb16.getColorFormatDescription().indexOf("16-bit") >= 0, "Should show 16-bit");

		// 24-bit RGB
		var fb24 = new DisplayFrameBuffer(0, 640, 480, 24);
		assert(fb24.getColorFormatDescription().indexOf("24-bit") >= 0, "Should show 24-bit");

		// 32-bit RGBA
		var fb32 = new DisplayFrameBuffer(0, 640, 480, 32);
		assert(fb32.getColorFormatDescription().indexOf("32-bit") >= 0, "Should show 32-bit");

		trace("  ✓ All color formats supported");
	}

	static function testDisplayFrameBufferSize() {
		trace("testDisplayFrameBufferSize: Testing buffer size calculation");

		var fb = new DisplayFrameBuffer(
			0,
			1920,        // width
			1080,        // height
			32,          // bitsPerPixel (4 bytes per pixel)
			7680,        // bytesPerLine (1920 * 4)
			"RGBA",
			"0x0",
			8294400      // 1920 * 1080 * 4
		);

		var expectedSize = fb.calculateExpectedSize();
		assert(expectedSize == 8294400, "Expected size should be 8294400");
		assert(fb.isSizeValid() == true, "Size should be valid");
		trace("  ✓ Buffer size: " + fb.bufferSize + " bytes, calculated: " + expectedSize);
	}

	static function testDisplayFrameBufferReady() {
		trace("testDisplayFrameBufferReady: Testing capture readiness");

		// Valid buffer
		var validFb = new DisplayFrameBuffer(
			0,
			1920,
			1080,
			32,
			7680,
			"RGBA",
			"0x12345678",
			8294400,
			true,        // isValid
			false,       // usesHardwareAcceleration
			false        // isUpdating
		);

		assert(validFb.isReadyForCapture() == true, "Valid buffer should be ready for capture");

		// Updating buffer
		var updatingFb = new DisplayFrameBuffer(
			0,
			1920,
			1080,
			32,
			7680,
			"RGBA",
			"0x12345678",
			8294400,
			true,
			false,
			true         // isUpdating
		);

		assert(updatingFb.isReadyForCapture() == false, "Updating buffer should not be ready");

		// Invalid buffer
		var invalidFb = new DisplayFrameBuffer(0, 0, 0, 32);
		assert(invalidFb.isReadyForCapture() == false, "Invalid buffer should not be ready");

		trace("  ✓ Capture readiness checks passed");
	}

	static function testDisplayFrameBufferBytesPerPixel() {
		trace("testDisplayFrameBufferBytesPerPixel: Testing bytes per pixel calculation");

		var fb8 = new DisplayFrameBuffer(0, 640, 480, 8);
		assert(fb8.getBytesPerPixel() == 1, "8-bit should be 1 byte per pixel");

		var fb16 = new DisplayFrameBuffer(0, 640, 480, 16);
		assert(fb16.getBytesPerPixel() == 2, "16-bit should be 2 bytes per pixel");

		var fb24 = new DisplayFrameBuffer(0, 640, 480, 24);
		assert(fb24.getBytesPerPixel() == 3, "24-bit should be 3 bytes per pixel");

		var fb32 = new DisplayFrameBuffer(0, 640, 480, 32);
		assert(fb32.getBytesPerPixel() == 4, "32-bit should be 4 bytes per pixel");

		trace("  ✓ Bytes per pixel calculations correct");
	}

	static function testRemoteDisplayPreferred() {
		trace("testRemoteDisplayPreferred: Testing preferred display method");

		// Prefer RDP when both available
		var both = new RemoteDisplayInfo(true, 3389, true, 5900, "localhost");
		var preferred = both.getPreferredRemoteDisplay();
		assert(preferred != null && preferred.indexOf("3389") >= 0, "Should prefer RDP");

		// Use VNC when RDP unavailable
		var vncOnly = new RemoteDisplayInfo(false, null, true, 5900, "localhost");
		var vncPref = vncOnly.getPreferredRemoteDisplay();
		assert(vncPref != null && vncPref.indexOf("5900") >= 0, "Should use VNC");

		// Null when neither available
		var none = new RemoteDisplayInfo(false);
		var nonePref = none.getPreferredRemoteDisplay();
		assert(nonePref == null, "Should return null when no display");

		trace("  ✓ Preferred display selection works");
	}

	static function assert(condition:Bool, message:String) {
		if (!condition) {
			throw new haxe.Exception("Assertion failed: " + message);
		}
	}

	static function main() {
		trace("=== VirtualBox Display Management Test Suite ===\n");

		try {
			testRemoteDisplayInfoRDP();
			trace("");
			testRemoteDisplayInfoVNC();
			trace("");
			testRemoteDisplayInfoDualDisplay();
			trace("");
			testRemoteDisplayInfoNoDisplay();
			trace("");
			testRemoteDisplayResolution();
			trace("");
			testRemoteDisplayColorFormat();
			trace("");
			testDisplayFrameBufferValid();
			trace("");
			testDisplayFrameBufferResolution();
			trace("");
			testDisplayFrameBufferUnavailable();
			trace("");
			testDisplayFrameBufferColorFormats();
			trace("");
			testDisplayFrameBufferSize();
			trace("");
			testDisplayFrameBufferReady();
			trace("");
			testDisplayFrameBufferBytesPerPixel();
			trace("");
			testRemoteDisplayPreferred();

			trace("\n=== All tests passed! ===");
		} catch (e:Dynamic) {
			trace("\n❌ Test failed: " + Std.string(e));
			throw e;
		}
	}
}
