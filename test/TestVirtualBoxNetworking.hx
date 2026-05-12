package;

import digigun.virt.virtualbox.NetworkAdapterType;
import digigun.virt.virtualbox.NetworkAttachmentType;
import digigun.virt.virtualbox.NetworkAdapter;
import digigun.virt.virtualbox.VirtualNetwork;

/**
	Comprehensive test suite for network management operations.
**/
class TestVirtualBoxNetworking {
	static function testNetworkAdapterTypeEnum() {
		trace("testNetworkAdapterTypeEnum: Testing NetworkAdapterType enum");

		// Test adapter types
		var am79c970a:String = cast Am79C970A;
		assert(am79c970a == "Am79C970A", "Am79C970A should cast to string");
		assert(Am79C970A.description().length > 0, "Am79C970A should have description");
		trace("  ✓ Am79C970A: " + Am79C970A.description());

		var i82540em:String = cast I82540EM;
		assert(i82540em == "I82540EM", "I82540EM should cast to string");
		assert(I82540EM.description().indexOf("Intel") >= 0, "I82540EM description should mention Intel");
		trace("  ✓ I82540EM: " + I82540EM.description());

		var virtio:String = cast Virtio;
		assert(virtio == "Virtio", "Virtio should cast to string");
		assert(Virtio.isParavirtualized() == true, "Virtio should be paravirtualized");
		trace("  ✓ Virtio: " + Virtio.description() + " (paravirtualized)");

		assert(I82540EM.isParavirtualized() == false, "I82540EM should not be paravirtualized");
	}

	static function testNetworkAttachmentTypeEnum() {
		trace("testNetworkAttachmentTypeEnum: Testing NetworkAttachmentType enum");

		// Test attachment types
		var nat:String = cast NAT;
		assert(nat == "NAT", "NAT should cast to string");
		assert(NAT.hasExternalAccess() == true, "NAT should have external access");
		assert(NAT.requiresNetworkName() == false, "NAT should not require network name");
		trace("  ✓ NAT: " + NAT.description());

		var bridged:String = cast Bridged;
		assert(bridged == "Bridged", "Bridged should cast to string");
		assert(Bridged.hasExternalAccess() == true, "Bridged should have external access");
		assert(Bridged.requiresNetworkName() == true, "Bridged should require network name");
		trace("  ✓ Bridged: " + Bridged.description());

		var internal:String = cast Internal;
		assert(internal == "Internal", "Internal should cast to string");
		assert(Internal.hasExternalAccess() == false, "Internal should not have external access");
		trace("  ✓ Internal: " + Internal.description());

		var notAttached:String = cast NotAttached;
		assert(notAttached == "NotAttached", "NotAttached should cast to string");
		assert(NotAttached.hasExternalAccess() == false, "NotAttached should not have external access");
		trace("  ✓ Not Attached: " + NotAttached.description());
	}

	static function testNetworkAdapterCreation() {
		trace("testNetworkAdapterCreation: Testing NetworkAdapter creation");

		// Test valid adapter
		var adapter = new NetworkAdapter(0, cast I82540EM, cast NAT, null, "080027B91234");
		assert(adapter.slot == 0, "Slot should be 0");
		assert(adapter.enabled == true, "Should be enabled by default");
		assert(adapter.cableConnected == true, "Cable should be connected by default");
		assert(adapter.isValid() == true, "Adapter should be valid");
		assert(adapter.hasExternalAccess() == true, "NAT should provide external access");
		trace("  ✓ Created valid NAT adapter on slot 0: " + adapter.description());

		// Test bridged adapter with network name
		var bridgedAdapter = new NetworkAdapter(1, cast I82545EM, cast Bridged, "en0", "080027B91235", true, true);
		assert(bridgedAdapter.networkName == "en0", "Network name should be 'en0'");
		assert(bridgedAdapter.isValid() == true, "Bridged adapter with network name should be valid");
		trace("  ✓ Created Bridged adapter on en0: " + bridgedAdapter.description());

		// Test disabled adapter
		var disabledAdapter = new NetworkAdapter(2, cast Virtio, cast HostOnly, "vboxnet0", null, false, false);
		assert(disabledAdapter.enabled == false, "Should be disabled");
		assert(disabledAdapter.cableConnected == false, "Cable should be disconnected");
		assert(disabledAdapter.hasExternalAccess() == false, "Disabled adapter should not have access");
		trace("  ✓ Created disabled adapter: " + disabledAdapter.description());
	}

	static function testNetworkAdapterValidation() {
		trace("testNetworkAdapterValidation: Testing NetworkAdapter validation");

		// Valid NAT adapter (no network name needed)
		var validNat = new NetworkAdapter(0, cast I82540EM, cast NAT);
		assert(validNat.isValid() == true, "NAT without network name should be valid");
		trace("  ✓ NAT adapter validation passed");

		// Valid Bridged adapter (network name required)
		var validBridged = new NetworkAdapter(1, cast I82545EM, cast Bridged, "en0");
		assert(validBridged.isValid() == true, "Bridged with network name should be valid");
		trace("  ✓ Bridged adapter validation passed");

		// Invalid Bridged adapter (missing network name)
		var invalidBridged = new NetworkAdapter(1, cast I82545EM, cast Bridged, null);
		assert(invalidBridged.isValid() == false, "Bridged without network name should be invalid");
		trace("  ✓ Bridged adapter validation correctly detected missing network name");
	}

	static function testNetworkAdapterSlotValidation() {
		trace("testNetworkAdapterSlotValidation: Testing adapter slot bounds");

		// Valid slots
		for (slot in [0, 1, 2, 3]) {
			var adapter = new NetworkAdapter(slot, cast I82540EM, cast NAT);
			assert(adapter.slot == slot, "Slot $slot should be valid");
		}
		trace("  ✓ Slots 0-3 are valid");

		// Invalid slots
		try {
			var invalidAdapter = new NetworkAdapter(-1, cast I82540EM, cast NAT);
			assert(false, "Negative slot should throw error");
		} catch (e:Dynamic) {
			trace("  ✓ Negative slot throws error");
		}

		try {
			var invalidAdapter = new NetworkAdapter(4, cast I82540EM, cast NAT);
			assert(false, "Slot 4 should throw error");
		} catch (e:Dynamic) {
			trace("  ✓ Slot 4 throws error");
		}
	}

	static function testVirtualNetworkCreation() {
		trace("testVirtualNetworkCreation: Testing VirtualNetwork creation");

		// Basic network
		var network = new VirtualNetwork("vboxnet0", "192.168.56.0/24", "192.168.56.255");
		assert(network.name == "vboxnet0", "Name should be vboxnet0");
		assert(network.networkCIDR == "192.168.56.0/24", "CIDR should match");
		assert(network.dhcpEnabled == true, "DHCP should be enabled by default");
		trace("  ✓ Created host-only network: " + network.description());

		// Network with DHCP range
		var dhcpNetwork = new VirtualNetwork(
			"vboxnet1",
			"10.0.2.0/24",
			"10.0.2.255",
			true,
			"10.0.2.15",
			"10.0.2.240",
			"Host-only"
		);
		assert(dhcpNetwork.dhcpLowerIP == "10.0.2.15", "DHCP lower bound should match");
		assert(dhcpNetwork.dhcpUpperIP == "10.0.2.240", "DHCP upper bound should match");
		assert(dhcpNetwork.isValid() == true, "Network with DHCP range should be valid");
		trace("  ✓ Created DHCP network: " + dhcpNetwork.description());

		// Network without DHCP
		var noDhcpNetwork = new VirtualNetwork("vboxnet2", "172.16.0.0/24", "172.16.0.255", false);
		assert(noDhcpNetwork.dhcpEnabled == false, "DHCP should be disabled");
		assert(noDhcpNetwork.dhcpLowerIP == null, "DHCP lower IP should be null");
		trace("  ✓ Created non-DHCP network: " + noDhcpNetwork.description());
	}

	static function testVirtualNetworkValidation() {
		trace("testVirtualNetworkValidation: Testing VirtualNetwork validation");

		// Valid network
		var validNetwork = new VirtualNetwork("test", "192.168.1.0/24", "192.168.1.255", true, "192.168.1.10", "192.168.1.20");
		assert(validNetwork.isValid() == true, "Valid network should pass validation");
		trace("  ✓ Valid network passes validation");

		// Invalid network (DHCP enabled but no bounds)
		var invalidNetwork = new VirtualNetwork("test2", "192.168.2.0/24", "192.168.2.255", true, null, null);
		assert(invalidNetwork.isValid() == false, "DHCP without bounds should be invalid");
		trace("  ✓ Invalid network correctly detected");
	}

	static function testVirtualNetworkCIDRParsing() {
		trace("testVirtualNetworkCIDRParsing: Testing CIDR parsing");

		var network = new VirtualNetwork("test", "192.168.56.0/24");
		var netAddr = network.getNetworkAddress();
		var prefixLen = network.getPrefixLength();

		assert(netAddr == "192.168.56.0", "Network address should be 192.168.56.0");
		assert(prefixLen == 24, "Prefix length should be 24");
		trace("  ✓ CIDR 192.168.56.0/24 parsed: address=$netAddr, prefix=$prefixLen");

		// Invalid CIDR
		var invalidNetwork = new VirtualNetwork("test2", "invalid-cidr");
		var invalidNetAddr = invalidNetwork.getNetworkAddress();
		assert(invalidNetAddr == "invalid-cidr", "Should return as-is if no slash");
		trace("  ✓ Invalid CIDR handled gracefully");
	}

	static function assert(condition:Bool, message:String) {
		if (!condition) {
			throw new haxe.Exception("Assertion failed: " + message);
		}
	}

	static function main() {
		trace("=== VirtualBox Network Management Test Suite ===\n");

		try {
			testNetworkAdapterTypeEnum();
			trace("");
			testNetworkAttachmentTypeEnum();
			trace("");
			testNetworkAdapterCreation();
			trace("");
			testNetworkAdapterValidation();
			trace("");
			testNetworkAdapterSlotValidation();
			trace("");
			testVirtualNetworkCreation();
			trace("");
			testVirtualNetworkValidation();
			trace("");
			testVirtualNetworkCIDRParsing();

			trace("\n=== All tests passed! ===");
		} catch (e:Dynamic) {
			trace("\n❌ Test failed: " + Std.string(e));
			throw e;
		}
	}
}
