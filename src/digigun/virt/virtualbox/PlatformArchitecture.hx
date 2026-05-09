package digigun.virt.virtualbox;

/**
    Enumeration of CPU platform architectures supported by VirtualBox.
    
    Represents the underlying CPU architecture of the host system.
**/
enum abstract PlatformArchitecture(String) {
    /// x86 (32-bit) architecture
    var X86 = "x86";
    
    /// x64 (64-bit AMD64/Intel64) architecture
    var X64 = "x64";
    
    /// ARM architecture (32-bit)
    var ARM = "arm";
    
    /// ARM64 architecture (64-bit)
    var ARM64 = "arm64";
    
    /// PowerPC architecture
    var PowerPC = "ppc";
    
    /// PowerPC64 architecture
    var PowerPC64 = "ppc64";
    
    /// MIPS architecture
    var MIPS = "mips";
    
    /// SPARC architecture
    var SPARC = "sparc";
    
    @:to public function toString():String {
        return this;
    }
}
