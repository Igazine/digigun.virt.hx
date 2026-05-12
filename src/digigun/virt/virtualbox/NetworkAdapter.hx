package digigun.virt.virtualbox;

/**
	Immutable representation of a network adapter configuration.
	
	Describes a single network adapter in a virtual machine, including
	its hardware type, attachment mode, and current status.
**/
final class NetworkAdapter {
	/**
		Adapter slot number (0-based, typically 0-3).
	**/
	public final slot:Int;

	/**
		Network adapter hardware type (Intel PRO, AMD PCNet, Virtio, etc).
	**/
	public final adapterType:NetworkAdapterType;

	/**
		How adapter is connected (NAT, Bridged, Host-only, Internal, etc).
	**/
	public final attachmentType:NetworkAttachmentType;

	/**
		Network name for attachment (bridge name, internal network name, etc).
		Null if attachment doesn't require a network name.
	**/
	public final networkName:Null<String>;

	/**
		MAC address of adapter (e.g., "080027B91234").
		Null if not set or not readable.
	**/
	public final macAddress:Null<String>;

	/**
		Whether adapter is currently enabled.
	**/
	public final enabled:Bool;

	/**
		Whether adapter uses cable connected (link status).
	**/
	public final cableConnected:Bool;

	/**
		Create new network adapter representation.
		
		@param slot Adapter slot (0-3)
		@param adapterType Hardware type
		@param attachmentType Connection mode
		@param networkName Network name (if required by attachment type)
		@param macAddress MAC address (optional)
		@param enabled Whether adapter is enabled
		@param cableConnected Whether cable is connected
	**/
	public function new(
		slot:Int,
		adapterType:NetworkAdapterType,
		attachmentType:NetworkAttachmentType,
		networkName:Null<String> = null,
		macAddress:Null<String> = null,
		enabled:Bool = true,
		cableConnected:Bool = true
	) {
		if (slot < 0 || slot > 3) {
			throw new haxe.Exception("Adapter slot must be 0-3, got: " + slot);
		}
		this.slot = slot;
		this.adapterType = adapterType;
		this.attachmentType = attachmentType;
		this.networkName = networkName;
		this.macAddress = macAddress;
		this.enabled = enabled;
		this.cableConnected = cableConnected;
	}

	/**
		Get human-readable description of this adapter.
	**/
	public function description():String {
		var desc = 'Adapter $slot: ${adapterType.description()}';
		desc += ' (${attachmentType.description()})';
		if (networkName != null && networkName.length > 0) {
			desc += ' -> $networkName';
		}
		if (macAddress != null && macAddress.length > 0) {
			desc += ' [$macAddress]';
		}
		desc += enabled ? ' [enabled]' : ' [disabled]';
		if (!cableConnected) {
			desc += ' [cable disconnected]';
		}
		return desc;
	}

	/**
		Check if adapter is properly configured.
	**/
	public function isValid():Bool {
		// If attachment requires network name, it must be present
		if (attachmentType.requiresNetworkName() && (networkName == null || networkName.length == 0)) {
			return false;
		}
		// If not attached, no network name needed
		var attachStr:String = cast attachmentType;
		if (attachStr == "NotAttached" && networkName != null) {
			return false;
		}
		return true;
	}

	/**
		Check if adapter has external network access.
	**/
	public function hasExternalAccess():Bool {
		return enabled && attachmentType.hasExternalAccess();
	}
}
