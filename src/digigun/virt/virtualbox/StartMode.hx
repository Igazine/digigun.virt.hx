package digigun.virt.virtualbox;

/**
    Enumeration of VM startup modes available in VirtualBox.
    
    Different launch modes suit different use cases:
    - GUI: Standard windowed desktop interface
    - Headless: No UI for server/automation scenarios
    - Separate: Separate from console window (Windows-specific)
**/
enum abstract StartMode(String) {
    /// Launch VM with normal GUI window (default)
    var GUI = "gui";
    
    /// Launch VM without GUI (server/automation mode)
    var Headless = "headless";
    
    /// Launch VM in separate window (Windows only)
    var Separate = "separate";
    
    @:to public function toString():String {
        return this;
    }
}
