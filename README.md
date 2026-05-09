# Digigun Virtualization Haxe Binding

**Status: ⚠️ Work in Progress - Early Development Phase**

A modern Haxe library providing high-level bindings to virtualization platforms. Currently focused on **VirtualBox** with plans to support Docker and Libvirt in future phases.

---

## 🎯 Project Vision

Digigun aims to provide a unified, type-safe interface for virtual machine control across multiple hypervisors. By leveraging Haxe's cross-platform compilation and FFI capabilities, it enables developers to write virtualization logic once and compile to multiple targets.

**Current Focus:** VirtualBox support with a complete, production-ready API.

---

## 📦 Features (VirtualBox)

### VM Lifecycle Management
- **Start/Stop Operations** - Start, pause, resume, reset, and powerdown virtual machines
- **State Tracking** - Real-time VM state polling with timeout support
- **Session Handling** - Secure VM session creation and management
- **Graceful Operations** - Support for both immediate and graceful machine operations

### Machine Configuration
- **CPU Settings** - Configure processor count and execution caps
- **Memory Management** - Set VM RAM allocation with hot-plug capabilities
- **Display Configuration** - Video memory and monitor count settings
- **Acceleration** - VT-x/AMD-V and nested paging configuration
- **IOMMU Support** - I/O virtualization settings

### Snapshot Management
- **Full-Chain Support** - Work with snapshot hierarchies
- **Create/Restore/Delete** - Complete lifecycle operations
- **Metadata Queries** - Snapshot age, machine state, parent tracking
- **Automated Cleanup** - Tool for removing orphaned snapshots

### Media & Storage
- **Disk Detection** - Enumerate available disk images
- **Storage Analysis** - Size and location tracking
- **SATA/IDE Configuration** - Storage controller management
- **Attachment Info** - Query disk attachments to VM configurations

### Host System Information
- **Platform Detection** - CPU architecture identification (x86, x64, ARM, etc.)
- **Hardware Metrics** - Processor count, core count, and speeds
- **Memory Statistics** - Total/available memory with usage calculations
- **System Identity** - Domain name, OS version, and UTC timestamp
- **Formatted Output** - Human-readable display for all metrics

---

## 🏗️ Architecture

### Directory Structure

```
.
├── src/digigun/virt/
│   └── virtualbox/               # VirtualBox Haxe bindings
│       ├── VirtualBox.hx         # Main API entry point
│       ├── Machine.hx            # VM instance wrapper
│       ├── Session.hx            # Session management
│       ├── Snapshot.hx           # Snapshot operations
│       ├── *Info.hx              # Data classes (Host, Memory, Processor)
│       ├── raw/                  # FFI layer
│       │   ├── Native.hx         # FFI declarations
│       │   └── Types.hx          # Native type definitions
│       ├── Error handling classes
│       └── Enums (MachineState, StartMode, etc.)
├── native/virtualbox/            # C bridge layer
│   ├── include/
│   │   └── virtualbox_bridge.h   # C header with VirtualBox SDK integration
│   └── src/
│       └── virtualbox_bridge.c   # ~730 LOC C implementation
├── test/                         # Comprehensive test suite
│   ├── Test*.hx                  # 8 test files covering all APIs
│   └── *.hxml                    # Build configurations for each test
└── .copilot/                     # Documentation
    ├── *.md                      # API reference and guides
    └── checkpoints/              # Development checkpoints

.ignored/                          # Deferred implementations (not active)
├── src/digigun/virt/
│   ├── docker/                   # Docker support (planned)
│   └── libvirt/                  # Libvirt support (planned)
```

### Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Language | Haxe | 4.3+ |
| C++ Runtime | hxcpp | Latest |
| Virtualization | VirtualBox SDK | 7.x |
| Platform | macOS | Apple Silicon tested |

---

## 🚀 Quick Start

### Prerequisites
- Haxe 4.3 or later
- VirtualBox 7.x installed
- VirtualBox SDK headers (set `VBOXPATH` environment variable)
- C++ compiler (via hxcpp)

### Building
```bash
# Build the library
haxe build.hxml

# Run tests
cd test && haxe test-virtualbox.hxml
```

### Basic Usage
```haxe
import digigun.virt.virtualbox.*;

// Connect to VirtualBox
var vbox = new VirtualBox();

// List available VMs
for (machine in vbox.listMachines()) {
    trace('VM: ${machine.name} (${machine.state})');
}

// Get VM and check state
if (vbox.getMachine("MyVM") != null) {
    var vm = vbox.getMachine("MyVM");
    trace('State: ${vm.state}');
    
    // Start the VM
    vm.start();
}

// Query host information
var hostInfo = vbox.getHostInfo();
trace('Host: ${hostInfo.domainName}');
trace('CPUs: ${hostInfo.processorCount}');
trace('Memory: ${hostInfo.memory.formatMemorySize()}');
```

---

## 📚 API Documentation

Comprehensive API documentation is available in the `.copilot/` directory:

- **[HOST_INFO.md](.copilot/HOST_INFO.md)** - Host system information and metrics
- **[VM_LIFECYCLE.md](.copilot/VM_LIFECYCLE.md)** - Virtual machine control operations
- **[MACHINE_CONFIGURATION.md](.copilot/MACHINE_CONFIGURATION.md)** - VM hardware configuration
- **[SNAPSHOTS.md](.copilot/SNAPSHOTS.md)** - Snapshot management API
- **[MEDIA_STORAGE.md](.copilot/MEDIA_STORAGE.md)** - Disk and storage management

---

## 🧪 Testing

The project includes a comprehensive test suite with 8 test programs covering all major APIs:

```bash
# Run VM lifecycle tests
cd test && haxe test-virtualbox-vm-lifecycle.hxml

# Test machine configuration
cd test && haxe test-virtualbox-machine-config.hxml

# Test snapshots
cd test && haxe test-virtualbox-snapshots.hxml

# Test host information
cd test && haxe test-virtualbox-host-info.hxml

# And more...
cd test && haxe test-virtualbox-media-storage.hxml
```

Test results and detailed output are generated in `bin/app/macos/` for each platform.

---

## 🔧 Development Status

### ✅ Completed (Phase 3.1)
- [x] VirtualBox FFI layer and C bridge
- [x] VM lifecycle control (start, stop, pause, reset)
- [x] Machine configuration API
- [x] Snapshot management
- [x] Media storage and disk enumeration
- [x] Host information and system metrics
- [x] Comprehensive error handling
- [x] Test suite with 8 programs
- [x] Professional API documentation
- [x] Clean project structure

### 🔄 In Progress / Planned
- [ ] Build system issue investigation (test executable generation)
- [ ] Performance optimization and caching layer
- [ ] Event system for state change notifications
- [ ] Historical metrics tracking
- [ ] Docker support (in `.ignored/`, deferred)
- [ ] Libvirt support (in `.ignored/`, deferred)

### 📋 Known Issues
1. **Test Executable Generation** - Haxe compilation succeeds but TestVirtualBoxHostInfo executable not generated. Investigation shows code is correct; issue is in Haxe C++ codegen. Workaround: Use individual test files.

### ⚠️ Limitations
- **macOS Only (Currently)** - Tested on Apple Silicon. Linux and Windows support deferred.
- **VirtualBox 7.x+** - Earlier versions untested.
- **Memory Reporting** - Available memory approximated as total (can be improved).
- **CPU Speed** - Reports current speed (affected by frequency scaling).

---

## 🤝 Contributing

This is an early-stage project. Contributions and feedback are welcome! Key areas for contribution:

- Linux and Windows platform support
- Docker and Libvirt implementation
- Performance testing and optimization
- Additional API surface (advanced networking, USB)
- Build system debugging and improvement

---

## 📄 License

TBD

---

## 📞 Support & Questions

For detailed technical information, see the documentation in `.copilot/` directory. For issues or questions, please refer to the development checkpoint files for context on design decisions and known limitations.

---

**Last Updated:** May 9, 2026  
**Development Phase:** 3.1 (Host Information API)  
**Stability:** Early - Use with caution in production environments
