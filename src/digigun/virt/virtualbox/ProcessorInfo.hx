package digigun.virt.virtualbox;

/**
    Information about a single processor/CPU core.
    
    Contains speed and count information for one CPU.
**/
class ProcessorInfo {
    /**
        CPU index (0-based).
    **/
    public var cpuId:Int;
    
    /**
        CPU speed in MHz.
    **/
    public var speedMHz:Int;
    
    /**
        Whether this CPU is online/active.
    **/
    public var online:Bool;
    
    /**
        Create processor information.
        
        @param cpuId CPU index (0-based)
        @param speedMHz CPU speed in MHz
        @param online Whether CPU is online
    **/
    public function new(cpuId:Int, speedMHz:Int, online:Bool = true) {
        this.cpuId = cpuId;
        this.speedMHz = speedMHz;
        this.online = online;
    }
    
    /**
        Get CPU speed in GHz with formatting.
        
        @return Speed as string like "2.4 GHz"
    **/
    public function getFormattedSpeed():String {
        var ghz:Float = speedMHz / 1000.0;
        return '${Math.round(ghz * 100) / 100} GHz';
    }
    
    /**
        Get processor status string.
        
        @return String like "CPU 0: 2.4 GHz (online)"
    **/
    public function getStatusString():String {
        var status = online ? "online" : "offline";
        return 'CPU $cpuId: ${getFormattedSpeed()} ($status)';
    }
    
    public function toString():String {
        return 'ProcessorInfo {id: $cpuId, speed: ${getFormattedSpeed()}, online: $online}';
    }
}
