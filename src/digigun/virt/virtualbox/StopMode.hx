package digigun.virt.virtualbox;

/**
    Enumeration of VM shutdown modes available in VirtualBox.
    
    Different stop modes provide varying levels of control and data safety:
    - Graceful: Friendly shutdown allowing OS to clean up
    - Force: Immediate hard shutdown (may cause data loss)
    - Save: Save VM state to disk before stopping
    - PowerDown: Hard power-off without saving
**/
enum abstract StopMode(String) {
    /// Graceful shutdown - OS gets signal to shut down cleanly
    var Graceful = "graceful";
    
    /// Force shutdown - immediate hard stop
    var Force = "force";
    
    /// Save state to disk - VM can be resumed from exact state
    var SaveState = "savestate";
    
    /// Hard power-off - immediate stop without saving
    var PowerDown = "powerdown";
    
    @:to public function toString():String {
        return this;
    }
}
