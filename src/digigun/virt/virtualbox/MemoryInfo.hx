package digigun.virt.virtualbox;

/**
    Information about host system memory.
    
    Provides memory statistics including total, available, and calculated usage.
**/
class MemoryInfo {
    /**
        Total system memory in megabytes.
    **/
    public var totalMemoryMB:Int;
    
    /**
        Available system memory in megabytes.
    **/
    public var availableMemoryMB:Int;
    
    /**
        Memory usage percentage (0-100).
        Calculated as: (total - available) / total * 100
    **/
    public var usagePercent:Float;
    
    /**
        Create memory information.
        
        @param totalMemoryMB Total system memory in MB
        @param availableMemoryMB Available system memory in MB
    **/
    public function new(totalMemoryMB:Int, availableMemoryMB:Int) {
        this.totalMemoryMB = totalMemoryMB;
        this.availableMemoryMB = availableMemoryMB;
        this.usagePercent = calculateUsagePercent();
    }
    
    /**
        Get used memory in megabytes.
        
        @return Used memory (total - available)
    **/
    public function getUsedMemoryMB():Int {
        return totalMemoryMB - availableMemoryMB;
    }
    
    /**
        Get memory usage as human-readable string (e.g., "8 GB").
        
        @param value Memory size in megabytes
        @return Formatted string with appropriate unit
    **/
    public function formatMemorySize(value:Int):String {
        if (value < 1024) {
            return '$value MB';
        } else if (value < 1024 * 1024) {
            var gb:Float = value / 1024.0;
            return '${Math.round(gb * 100) / 100} GB';
        } else {
            var tb:Float = value / (1024.0 * 1024.0);
            return '${Math.round(tb * 100) / 100} TB';
        }
    }
    
    /**
        Get usage information as human-readable string.
        
        @return String like "Used: 8 GB / 16 GB (50%)"
    **/
    public function getUsageString():String {
        var used = getUsedMemoryMB();
        return 'Used: ${formatMemorySize(used)} / ${formatMemorySize(totalMemoryMB)} (${Math.round(usagePercent)}%)';
    }
    
    private function calculateUsagePercent():Float {
        if (totalMemoryMB == 0) return 0.0;
        return (totalMemoryMB - availableMemoryMB) / totalMemoryMB * 100.0;
    }
    
    public function toString():String {
        return 'MemoryInfo {total: ${formatMemorySize(totalMemoryMB)}, available: ${formatMemorySize(availableMemoryMB)}, usage: ${Math.round(usagePercent)}%}';
    }
}
