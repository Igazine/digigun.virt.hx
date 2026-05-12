package digigun.virt.virtualbox;

/**
	Immutable representation of a virtual network.
	
	Describes a VirtualBox virtual network configuration including
	its type, IP addressing, and DHCP server settings.
**/
final class VirtualNetwork {
	/**
		Unique name of the virtual network.
	**/
	public final name:String;

	/**
		Network CIDR (e.g., "192.168.56.0/24").
		Null for certain network types (bridge, cloud).
	**/
	public final networkCIDR:Null<String>;

	/**
		Broadcast address (e.g., "192.168.56.255").
		Null if not applicable.
	**/
	public final broadcastAddress:Null<String>;

	/**
		Whether DHCP server is enabled on this network.
	**/
	public final dhcpEnabled:Bool;

	/**
		DHCP server lower bound IP (e.g., "192.168.56.100").
		Null if DHCP not enabled.
	**/
	public final dhcpLowerIP:Null<String>;

	/**
		DHCP server upper bound IP (e.g., "192.168.56.200").
		Null if DHCP not enabled.
	**/
	public final dhcpUpperIP:Null<String>;

	/**
		Network type (Internal, Host-only, NAT Network, etc).
	**/
	public final networkType:String;

	/**
		Create new virtual network representation.
		
		@param name Network name
		@param networkCIDR Network CIDR block (optional)
		@param broadcastAddress Broadcast address (optional)
		@param dhcpEnabled Whether DHCP is enabled
		@param dhcpLowerIP DHCP lower bound (optional)
		@param dhcpUpperIP DHCP upper bound (optional)
		@param networkType Network type (default: "Host-only")
	**/
	public function new(
		name:String,
		networkCIDR:Null<String> = null,
		broadcastAddress:Null<String> = null,
		dhcpEnabled:Bool = true,
		dhcpLowerIP:Null<String> = null,
		dhcpUpperIP:Null<String> = null,
		networkType:String = "Host-only"
	) {
		if (name.length == 0) {
			throw new haxe.Exception("Network name cannot be empty");
		}
		this.name = name;
		this.networkCIDR = networkCIDR;
		this.broadcastAddress = broadcastAddress;
		this.dhcpEnabled = dhcpEnabled;
		this.dhcpLowerIP = dhcpLowerIP;
		this.dhcpUpperIP = dhcpUpperIP;
		this.networkType = networkType;
	}

	/**
		Get human-readable description of this network.
	**/
	public function description():String {
		var desc = 'Network "$name" (${networkType})';
		if (networkCIDR != null && networkCIDR.length > 0) {
			desc += ' ${networkCIDR}';
		}
		if (dhcpEnabled) {
			desc += ' [DHCP';
			if (dhcpLowerIP != null && dhcpUpperIP != null) {
				desc += ': ${dhcpLowerIP} - ${dhcpUpperIP}';
			}
			desc += ']';
		}
		return desc;
	}

	/**
		Check if network is properly configured.
	**/
	public function isValid():Bool {
		// DHCP enabled but no bounds specified
		if (dhcpEnabled && (dhcpLowerIP == null || dhcpUpperIP == null)) {
			return false;
		}
		// DHCP disabled but bounds specified
		if (!dhcpEnabled && (dhcpLowerIP != null || dhcpUpperIP != null)) {
			return false;
		}
		return true;
	}

	/**
		Get extracted network address from CIDR.
		
		For "192.168.56.0/24", returns "192.168.56.0".
		Returns null if CIDR not set or invalid format.
	**/
	public function getNetworkAddress():Null<String> {
		if (networkCIDR == null) return null;
		var parts = networkCIDR.split("/");
		return parts.length > 0 ? parts[0] : null;
	}

	/**
		Extract prefix length from CIDR.
		
		For "192.168.56.0/24", returns 24.
		Returns null if CIDR not set or invalid format.
	**/
	public function getPrefixLength():Null<Int> {
		if (networkCIDR == null) return null;
		var parts = networkCIDR.split("/");
		if (parts.length < 2) return null;
		return Std.parseInt(parts[1]);
	}
}
