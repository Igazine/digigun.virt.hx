package digigun.virt.virtualbox;

/**
    Complete host system information from VirtualBox.
    
    Contains all relevant system information exposed by VirtualBox's IHost interface,
    including processor, memory, OS, and architecture details.
**/
class HostInfo {
    /**
        Platform architecture (x86, x64, ARM, etc.).
    **/
    public var architecture:PlatformArchitecture;
    
    /**
        Domain name of the host.
    **/
    public var domainName:String;
    
    /**
        Total number of processors.
    **/
    public var processorCount:Int;
    
    /**
        Number of online (active) processors.
    **/
    public var processorOnlineCount:Int;
    
    /**
        Total number of processor cores.
    **/
    public var processorCoreCount:Int;
    
    /**
        Number of online processor cores.
    **/
    public var processorOnlineCoreCount:Int;
    
    /**
        Memory information (total, available, usage).
    **/
    public var memory:MemoryInfo;
    
    /**
        Host operating system name (e.g., "macOS", "Linux", "Windows").
    **/
    public var operatingSystem:String;
    
    /**
        Operating system version string.
    **/
    public var osVersion:String;
    
    /**
        UTC system time (Unix timestamp in seconds).
    **/
    public var utcTime:Int;
    
    /**
        Create host information object.
        
        @param architecture Platform architecture
        @param domainName Domain name
        @param processorCount Total processors
        @param processorOnlineCount Online processors
        @param processorCoreCount Total cores
        @param processorOnlineCoreCount Online cores
        @param memory Memory information
        @param operatingSystem OS name
        @param osVersion OS version
        @param utcTime System UTC time
    **/
    public function new(
        architecture:PlatformArchitecture,
        domainName:String,
        processorCount:Int,
        processorOnlineCount:Int,
        processorCoreCount:Int,
        processorOnlineCoreCount:Int,
        memory:MemoryInfo,
        operatingSystem:String,
        osVersion:String,
        utcTime:Int
    ) {
        this.architecture = architecture;
        this.domainName = domainName;
        this.processorCount = processorCount;
        this.processorOnlineCount = processorOnlineCount;
        this.processorCoreCount = processorCoreCount;
        this.processorOnlineCoreCount = processorOnlineCoreCount;
        this.memory = memory;
        this.operatingSystem = operatingSystem;
        this.osVersion = osVersion;
        this.utcTime = utcTime;
    }
    
    /**
        Get system summary as human-readable string.
        
        @return String with key system details
    **/
    public function getSummary():String {
        return 'Host: $domainName ($operatingSystem $osVersion) - $architecture - ${processorOnlineCount}/${processorCount} CPUs - ${memory.getUsageString()}';
    }
    
    /**
        Get processor summary.
        
        @return String like "8 Cores (8 online) / 4 Processors (4 online)"
    **/
    public function getProcessorSummary():String {
        return '${processorOnlineCoreCount}/${processorCoreCount} Cores - ${processorOnlineCount}/${processorCount} Processors';
    }
    
    public function toString():String {
        return 'HostInfo {arch: $architecture, os: $operatingSystem $osVersion, cpu: $processorOnlineCount/$processorCount, memory: ${memory.formatMemorySize(memory.totalMemoryMB)}}';
    }
}

/**
    Typedef for C interop layer.
    
    Matches the C struct HxVBoxHostInfo used in the native bridge.
**/
typedef HostInfoData = {
    architecture:String,
    domainName:String,
    processorCount:Int,
    processorOnlineCount:Int,
    processorCoreCount:Int,
    processorOnlineCoreCount:Int,
    memorySize:Int,
    memoryAvailable:Int,
    operatingSystem:String,
    osVersion:String,
    utcTime:Int
}
