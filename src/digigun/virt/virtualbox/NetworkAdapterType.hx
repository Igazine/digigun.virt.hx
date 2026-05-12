package digigun.virt.virtualbox;

/**
	Enumeration of virtual network adapter hardware types.
	
	Specifies the emulated network adapter model presented to the guest OS.
**/
@:enum abstract NetworkAdapterType(String) {
	/**
		Intel PRO/1000 MT Desktop Adapter (82540EM).
		Most compatible, widely supported by guest OS.
	**/
	var Am79C970A = "Am79C970A";

	/**
		AMD PCNet-PCI II (79C970A).
		Legacy adapter, good compatibility with older guest OS.
	**/
	var Am79C973 = "Am79C973";

	/**
		Intel PRO/1000 MT Server Adapter (82545EM).
		Server-class adapter with better performance.
	**/
	var I82540EM = "I82540EM";

	/**
		Intel PRO/1000 Server Adapter (82545EM Copper).
		Similar to I82540EM with copper (ethernet) connection.
	**/
	var I82545EM = "I82545EM";

	/**
		Intel PRO/1000 T Server Adapter.
		Twisted-pair (TP) connection variant.
	**/
	var I82543GC = "I82543GC";

	/**
		Virtio Network Adapter.
		Paravirtualized adapter for high-performance guests (Linux, modern Windows).
	**/
	var Virtio = "Virtio";

	/**
		Get human-readable description of adapter type.
	**/
	public function description():String {
		var typeStr = Std.string(this);
		return switch (typeStr) {
			case "Am79C970A": "AMD PCNet-PCI (79C970A) - Legacy, compatible";
			case "Am79C973": "AMD PCNet-PCI II (79C973) - Legacy, older compatibility";
			case "I82540EM": "Intel PRO/1000 MT Desktop (82540EM) - Most compatible";
			case "I82545EM": "Intel PRO/1000 MT Server (82545EM) - Server class";
			case "I82543GC": "Intel PRO/1000 T Server (82543GC) - TP connection";
			case "Virtio": "Virtio Network Adapter - High performance paravirtualized";
			case _: "Unknown network adapter type";
		};
	}

	/**
		Check if adapter type is paravirtualized (high performance).
	**/
	public function isParavirtualized():Bool {
		var typeStr = Std.string(this);
		return typeStr == "Virtio";
	}
}
