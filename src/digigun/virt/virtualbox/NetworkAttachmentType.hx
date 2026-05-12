package digigun.virt.virtualbox;

/**
	Enumeration of network attachment types for adapters.
	
	Specifies how the guest network adapter connects to the host system or virtual networks.
**/
@:enum abstract NetworkAttachmentType(String) {
	/**
		Not Attached.
		Adapter is disabled/disconnected from any network.
	**/
	var NotAttached = "NotAttached";

	/**
		Network Address Translation (NAT).
		Guest uses host's network with automatic address translation.
		Simple setup, good for most scenarios, limited host access.
	**/
	var NAT = "NAT";

	/**
		Bridged Networking.
		Guest appears as separate host on physical network.
		Full network access, requires host network adapter.
	**/
	var Bridged = "Bridged";

	/**
		Host-only Adapter.
		Guest connects only to host, isolated from external network.
		Good for isolated VMs, host-VM communication.
	**/
	var HostOnly = "HostOnly";

	/**
		Internal Network.
		Guest connects to other VMs on same internal network.
		Isolated from host, VM-to-VM communication only.
	**/
	var Internal = "Internal";

	/**
		Generic Network Driver.
		Custom network setup with user-defined driver.
	**/
	var Generic = "Generic";

	/**
		NAT Network (shared).
		Similar to NAT but multiple VMs share same network.
	**/
	var NATNetwork = "NATNetwork";

	/**
		Cloud Network.
		Connection to cloud providers (Oracle Cloud, etc).
	**/
	var Cloud = "Cloud";

	/**
		Get human-readable description of attachment type.
	**/
	public function description():String {
		var typeStr = Std.string(this);
		return switch (typeStr) {
			case "NotAttached": "Not Attached - adapter disabled";
			case "NAT": "NAT - guest uses host network";
			case "Bridged": "Bridged - guest on physical network";
			case "HostOnly": "Host-only - isolated host-VM communication";
			case "Internal": "Internal - VM-to-VM only, host isolated";
			case "Generic": "Generic - custom network driver";
			case "NATNetwork": "NAT Network - shared NAT for multiple VMs";
			case "Cloud": "Cloud Network - cloud provider connection";
			case _: "Unknown attachment type";
		};
	}

	/**
		Check if attachment provides external network access.
	**/
	public function hasExternalAccess():Bool {
		var typeStr = Std.string(this);
		return typeStr == "Bridged" || typeStr == "NAT" || typeStr == "NATNetwork" || typeStr == "Cloud";
	}

	/**
		Check if attachment requires network name/identifier.
	**/
	public function requiresNetworkName():Bool {
		var typeStr = Std.string(this);
		return typeStr == "Bridged" || typeStr == "HostOnly" || typeStr == "Internal" || typeStr == "NATNetwork" || typeStr == "Cloud";
	}
}
