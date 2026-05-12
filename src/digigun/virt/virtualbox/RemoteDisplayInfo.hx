package digigun.virt.virtualbox;

/**
 * Remote display (RDP/VNC) server information for a virtual machine.
 * 
 * Provides access to remote display ports and configuration for connecting to VMs
 * via RDP (Windows-style remote desktop) or VNC (platform-independent).
 * 
 * **Thread Safety:** Immutable - safe to share across threads.
 * 
 * Example:
 * ```haxe
 * var vm = vbox.findMachine("myvm");
 * var display = vbox.getRemoteDisplayInfo(vm);
 * trace('RDP available: ${display.rdpEnabled}');
 * trace('VNC on port: ${display.vncPort}');
 * ```
 */
final class RemoteDisplayInfo {
	/**
	 * Whether RDP (Remote Desktop Protocol) server is enabled.
	 * RDP is Microsoft's remote desktop protocol, primarily used on Windows.
	 */
	public final rdpEnabled:Bool;

	/**
	 * TCP port for RDP connections (typically 3389).
	 * Null if RDP is not enabled or not configured.
	 */
	public final rdpPort:Null<Int>;

	/**
	 * Whether VNC (Virtual Network Computing) server is enabled.
	 * VNC is platform-independent and works on macOS, Linux, Windows.
	 */
	public final vncEnabled:Bool;

	/**
	 * TCP port for VNC connections (typically 5900+).
	 * Null if VNC is not enabled or not configured.
	 */
	public final vncPort:Null<Int>;

	/**
	 * VNC server address/hostname for connection.
	 * Usually "127.0.0.1" for host-only, or VM's network IP for bridged.
	 * Null if VNC is not enabled.
	 */
	public final vncAddress:Null<String>;

	/**
	 * Current display resolution width (pixels).
	 * 0 if display info unavailable or display not initialized.
	 */
	public final displayWidth:Int;

	/**
	 * Current display resolution height (pixels).
	 * 0 if display info unavailable or display not initialized.
	 */
	public final displayHeight:Int;

	/**
	 * Current display bit depth (bits per pixel).
	 * Common values: 24 (RGB), 32 (RGBA), 16 (RGB565), 8 (paletted).
	 * 0 if unavailable.
	 */
	public final displayBitDepth:Int;

	/**
	 * Whether the guest OS can change display resolution.
	 * If true, resolution might differ from displayWidth/displayHeight.
	 */
	public final guestResizableDisplay:Bool;

	/**
	 * Unique display identifier (session-dependent).
	 * Used internally by VirtualBox for frame buffer tracking.
	 */
	public final displayId:String;

	/**
	 * Creates a new RemoteDisplayInfo.
	 * 
	 * @param rdpEnabled RDP server enabled
	 * @param rdpPort RDP port (null if disabled)
	 * @param vncEnabled VNC server enabled
	 * @param vncPort VNC port (null if disabled)
	 * @param vncAddress VNC address (null if disabled)
	 * @param displayWidth Display width in pixels (0 if unavailable)
	 * @param displayHeight Display height in pixels (0 if unavailable)
	 * @param displayBitDepth Bits per pixel (0 if unavailable)
	 * @param guestResizableDisplay Guest can resize display
	 * @param displayId Display identifier
	 */
	public function new(
		rdpEnabled:Bool,
		?rdpPort:Int,
		vncEnabled:Bool = false,
		?vncPort:Int,
		?vncAddress:String,
		displayWidth:Int = 0,
		displayHeight:Int = 0,
		displayBitDepth:Int = 0,
		guestResizableDisplay:Bool = true,
		displayId:String = "0"
	) {
		this.rdpEnabled = rdpEnabled;
		this.rdpPort = rdpPort;
		this.vncEnabled = vncEnabled;
		this.vncPort = vncPort;
		this.vncAddress = vncAddress;
		this.displayWidth = displayWidth;
		this.displayHeight = displayHeight;
		this.displayBitDepth = displayBitDepth;
		this.guestResizableDisplay = guestResizableDisplay;
		this.displayId = displayId;
	}

	/**
	 * Gets a human-readable description of available remote display services.
	 * 
	 * @return String like "RDP on port 3389, VNC on port 5900" or "No remote display"
	 */
	public function description():String {
		var parts = [];
		
		if (rdpEnabled && rdpPort != null) {
			parts.push('RDP on port ${rdpPort}');
		}
		
		if (vncEnabled && vncPort != null) {
			var addr = vncAddress != null ? vncAddress : "localhost";
			parts.push('VNC on ${addr}:${vncPort}');
		}
		
		if (parts.length == 0) {
			return "No remote display configured";
		}
		
		return parts.join(", ");
	}

	/**
	 * Checks if any remote display service is enabled.
	 * 
	 * @return True if either RDP or VNC is enabled
	 */
	public function isRemoteDisplayAvailable():Bool {
		return (rdpEnabled && rdpPort != null) || (vncEnabled && vncPort != null);
	}

	/**
	 * Gets the preferred remote display connection string.
	 * Prefers RDP if available, falls back to VNC.
	 * 
	 * @return Connection string like "localhost:3389" or "127.0.0.1:5900", or null if neither enabled
	 */
	public function getPreferredRemoteDisplay():Null<String> {
		if (rdpEnabled && rdpPort != null) {
			return 'localhost:${rdpPort}';
		}
		
		if (vncEnabled && vncPort != null) {
			var addr = vncAddress != null ? vncAddress : "localhost";
			return '${addr}:${vncPort}';
		}
		
		return null;
	}

	/**
	 * Gets display resolution as a string.
	 * 
	 * @return String like "1920x1080" or "Unknown" if unavailable
	 */
	public function getResolution():String {
		if (displayWidth == 0 || displayHeight == 0) {
			return "Unknown";
		}
		return '${displayWidth}x${displayHeight}';
	}

	/**
	 * Gets display color format description.
	 * 
	 * @return String like "32-bit RGBA", "24-bit RGB", etc.
	 */
	public function getColorFormat():String {
		return switch (displayBitDepth) {
			case 8: "8-bit (256 color)";
			case 16: "16-bit (RGB565)";
			case 24: "24-bit (RGB)";
			case 32: "32-bit (RGBA)";
			case 0: "Unknown";
			case d: '${d}-bit';
		};
	}

	/**
	 * Gets a debug string representation.
	 */
	public function toString():String {
		return 'RemoteDisplayInfo{${description()}, resolution=${getResolution()}, color=${getColorFormat()}}';
	}
}
