package digigun.virt.virtualbox;

/**
    Error thrown when state polling timeout is exceeded.
**/
class StatePollerError extends haxe.Exception {
    /**
        Additional context about the state transition failure.
    **/
    public var context:{targetState:MachineState, currentState:MachineState, elapsedMs:Int};
    
    /**
        Create a new StatePollerError.
        
        @param message Error description
        @param context State transition context
    **/
    public function new(message:String, context:{targetState:MachineState, currentState:MachineState, elapsedMs:Int}) {
        super(message);
        this.context = context;
    }
    
    public function getContext():{targetState:MachineState, currentState:MachineState, elapsedMs:Int} {
        return context;
    }
}
