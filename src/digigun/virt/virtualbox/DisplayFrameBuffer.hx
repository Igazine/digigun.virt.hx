package digigun.virt.virtualbox;

/**
 * Frame buffer information for direct pixel access to VM display.
 * 
 * Provides handles and metadata for accessing raw pixel data from a VM's display
 * for custom rendering, screenshot capture, or integration with UI frameworks.
 * 
 * **Note:** Pixel data access patterns vary by platform and VirtualBox configuration.
 * Some operations may require the VM to be running and have 3D acceleration enabled.
 * 
 * **Thread Safety:** Reference to shared buffer - do not modify. The underlying
 * buffer may change if VM suspends or resumes.
 * 
 * Example:
 * ```haxe
 * var vm = vbox.findMachine("myvm");
 * var framebuffer = vbox.getDisplayFrameBuffer(vm);
 * trace('Frame buffer width: ${framebuffer.width}');
 * trace('Frame buffer height: ${framebuffer.height}');
 * // Use pixelDataPtr with FFI to access raw pixel memory
 * ```
 */
final class DisplayFrameBuffer {
	/**
	 * Display index (usually 0 for primary display, 1+ for additional monitors).
	 */
	public final displayIndex:Int;

	/**
	 * Frame buffer width in pixels.
	 * 0 if frame buffer is not available or not initialized.
	 */
	public final width:Int;

	/**
	 * Frame buffer height in pixels.
	 * 0 if frame buffer is not available or not initialized.
	 */
	public final height:Int;

	/**
	 * Bits per pixel (8, 16, 24, 32).
	 * Determines how color data is stored in pixel buffer.
	 */
	public final bitsPerPixel:Int;

	/**
	 * Bytes per scan line (row) in pixel buffer.
	 * May include padding for alignment optimization.
	 * Not always equal to width * (bitsPerPixel / 8).
	 */
	public final bytesPerLine:Int;

	/**
	 * Pixel color format (e.g., "BGRA" on Windows, "RGBA" on macOS/Linux).
	 * Determines color channel ordering in pixel data.
	 */
	public final pixelFormat:String;

	/**
	 * Opaque handle to the raw pixel data buffer.
	 * Type varies by platform:
	 * - Windows: Pointer to DIB (Device Independent Bitmap)
	 * - X11: Pointer to XImage or similar
	 * - Cocoa: Pointer to CGImage or similar
	 * 
	 * Used with FFI layer for direct pixel access. Not meant for Haxe manipulation.
	 */
	public final pixelDataPtr:String;  // Stored as hex string representation

	/**
	 * Total size of pixel buffer in bytes.
	 * Equal to height * bytesPerLine (or close to it).
	 */
	public final bufferSize:Int;

	/**
	 * Whether the frame buffer is currently valid and accessible.
	 * False if VM is not running, display is disabled, or buffer is unavailable.
	 */
	public final isValid:Bool;

	/**
	 * Whether the frame buffer uses hardware acceleration (3D).
	 * If true, pixel access may be limited or synchronized with GPU.
	 */
	public final usesHardwareAcceleration:Bool;

	/**
	 * Whether the guest OS is currently updating the display.
	 * If false, pixel data is stable and can be safely captured.
	 */
	public final isUpdating:Bool;

	/**
	 * Vertical synchronization status (vsync).
	 * If true, frame updates are synchronized with display refresh.
	 */
	public final vSyncEnabled:Bool;

	/**
	 * Pixel update timestamp (milliseconds since VM start).
	 * Used to detect if frame buffer has been updated since last check.
	 */
	public final lastUpdateTime:Int;

	/**
	 * Creates a new DisplayFrameBuffer.
	 * 
	 * @param displayIndex Display number (0 = primary)
	 * @param width Frame buffer width
	 * @param height Frame buffer height
	 * @param bitsPerPixel Bits per pixel (8/16/24/32)
	 * @param bytesPerLine Bytes per scan line
	 * @param pixelFormat Color format (BGRA, RGBA, etc)
	 * @param pixelDataPtr Opaque pointer to pixel data (as hex string)
	 * @param bufferSize Total buffer size in bytes
	 * @param isValid Whether buffer is currently valid
	 * @param usesHardwareAcceleration Uses GPU acceleration
	 * @param isUpdating Currently updating
	 * @param vSyncEnabled VSync enabled
	 * @param lastUpdateTime Last update timestamp
	 */
	public function new(
		displayIndex:Int = 0,
		width:Int = 0,
		height:Int = 0,
		bitsPerPixel:Int = 32,
		bytesPerLine:Int = 0,
		pixelFormat:String = "RGBA",
		pixelDataPtr:String = "0x0",
		bufferSize:Int = 0,
		isValid:Bool = false,
		usesHardwareAcceleration:Bool = false,
		isUpdating:Bool = false,
		vSyncEnabled:Bool = true,
		lastUpdateTime:Int = 0
	) {
		this.displayIndex = displayIndex;
		this.width = width;
		this.height = height;
		this.bitsPerPixel = bitsPerPixel;
		this.bytesPerLine = bytesPerLine;
		this.pixelFormat = pixelFormat;
		this.pixelDataPtr = pixelDataPtr;
		this.bufferSize = bufferSize;
		this.isValid = isValid;
		this.usesHardwareAcceleration = usesHardwareAcceleration;
		this.isUpdating = isUpdating;
		this.vSyncEnabled = vSyncEnabled;
		this.lastUpdateTime = lastUpdateTime;
	}

	/**
	 * Gets resolution as a string.
	 * 
	 * @return String like "1920x1080" or "Unavailable"
	 */
	public function getResolution():String {
		if (width == 0 || height == 0) {
			return "Unavailable";
		}
		return '${width}x${height}';
	}

	/**
	 * Calculates expected buffer size based on width, height, and bits per pixel.
	 * Useful for validation.
	 * 
	 * @return Expected size in bytes
	 */
	public function calculateExpectedSize():Int {
		if (width == 0 || height == 0) {
			return 0;
		}
		var bytesPerPixel = Std.int(bitsPerPixel / 8);
		return width * bytesPerPixel * height;
	}

	/**
	 * Checks if buffer size matches expected size.
	 * 
	 * @return True if bufferSize equals calculated size
	 */
	public function isSizeValid():Bool {
		return bufferSize == calculateExpectedSize();
	}

	/**
	 * Gets color format description.
	 * 
	 * @return String like "32-bit RGBA"
	 */
	public function getColorFormatDescription():String {
		return '${bitsPerPixel}-bit ${pixelFormat}';
	}

	/**
	 * Gets human-readable description of frame buffer status.
	 * 
	 * @return Status string
	 */
	public function description():String {
		if (!isValid) {
			return "Frame buffer unavailable (VM not running or display disabled)";
		}
		
		var parts = [
			'${getResolution()}',
			'${bitsPerPixel}-bit ${pixelFormat}',
			'${bufferSize} bytes'
		];
		
		if (usesHardwareAcceleration) {
			parts.push("GPU-accelerated");
		}
		
		if (isUpdating) {
			parts.push("updating");
		}
		
		return parts.join(", ");
	}

	/**
	 * Checks if frame buffer is ready for pixel data access.
	 * 
	 * @return True if valid, not updating, and has data
	 */
	public function isReadyForCapture():Bool {
		return isValid && !isUpdating && width > 0 && height > 0 && pixelDataPtr != "0x0";
	}

	/**
	 * Gets typical bytes per pixel based on bitsPerPixel.
	 * 
	 * @return Bytes per pixel (typically 1-4)
	 */
	public function getBytesPerPixel():Int {
		return Std.int(bitsPerPixel / 8);
	}

	/**
	 * Gets debug string representation.
	 */
	public function toString():String {
		return 'DisplayFrameBuffer{${getResolution()}, ${getColorFormatDescription()}, ${description()}}';
	}
}
