package digigun.virt.virtualbox;

/**
    Helper for polling VM state changes with configurable timeouts and intervals.
    
    Provides robust state waiting without busy-spinning or forcing sleeps.
    Useful for waiting for specific state transitions during VM lifecycle operations.
**/
class StatePoller {
    private var targetState:MachineState;
    private var maxWaitMs:Int;
    private var pollIntervalMs:Int;
    private var startTimeMs:Int;
    
    /**
        Create a new StatePoller.
        
        @param targetState The state to wait for
        @param maxWaitMs Maximum milliseconds to wait (default 30000 = 30 seconds)
        @param pollIntervalMs Poll interval in milliseconds (default 500)
    **/
    public function new(targetState:MachineState, maxWaitMs:Int = 30000, pollIntervalMs:Int = 500) {
        this.targetState = targetState;
        this.maxWaitMs = maxWaitMs;
        this.pollIntervalMs = pollIntervalMs;
        this.startTimeMs = getTimeMs();
    }
    
    /**
        Check if the target state has been reached.
        
        @param currentState Current machine state
        @return true if target reached, false if still waiting
        @throws StatePollerError if timeout exceeded
    **/
    public function checkState(currentState:MachineState):Bool {
        if (currentState == targetState) {
            return true;
        }
        
        var elapsedMs = getTimeMs() - startTimeMs;
        if (elapsedMs > maxWaitMs) {
            throw new StatePollerError(
                'State transition timeout: waited ${elapsedMs}ms for ${targetState} but got ${currentState}',
                {targetState: targetState, currentState: currentState, elapsedMs: elapsedMs}
            );
        }
        
        return false;
    }
    
    /**
        Get remaining wait time before timeout.
        
        @return Milliseconds remaining (0 if expired)
    **/
    public function getRemainingMs():Int {
        var elapsedMs = getTimeMs() - startTimeMs;
        var remainingMs = maxWaitMs - elapsedMs;
        return remainingMs > 0 ? remainingMs : 0;
    }
    
    /**
        Get elapsed wait time since creation.
        
        @return Milliseconds elapsed
    **/
    public function getElapsedMs():Int {
        return getTimeMs() - startTimeMs;
    }
    
    /**
        Check if timeout has been exceeded.
        
        @return true if timeout exceeded, false otherwise
    **/
    public function hasTimedOut():Bool {
        return getRemainingMs() == 0;
    }
    
    /**
        Get the poll interval.
        
        @return Poll interval in milliseconds
    **/
    public function getPollIntervalMs():Int {
        return pollIntervalMs;
    }
    
    /**
        Get target state being waited for.
        
        @return MachineState being polled
    **/
    public function getTargetState():MachineState {
        return targetState;
    }
    
    private static function getTimeMs():Int {
        return Std.int(haxe.Timer.stamp() * 1000);
    }
    
    public function toString():String {
        return 'StatePoller {target: $targetState, elapsed: ${getElapsedMs()}ms, remaining: ${getRemainingMs()}ms}';
    }
}
