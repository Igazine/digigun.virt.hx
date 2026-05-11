package digigun.virt.virtualbox;

/**
	EventListener is the callback interface for handling VirtualBox events.
	
	Implement this abstract class to receive event notifications when subscribed
	to specific event types.
**/
abstract EventListener(HostEvent -> Void) {
	/**
		Create a new event listener with the given callback function.
	**/
	public function new(callback:HostEvent -> Void) {
		this = callback;
	}

	/**
		Invoke this listener with an event.
	**/
	public inline function handle(event:HostEvent):Void {
		this(event);
	}

	/**
		Convert this listener to a plain function.
	**/
	@:to public inline function toFunction():HostEvent -> Void {
		return this;
	}

	/**
		Create a new listener from a function.
	**/
	@:from public static inline function fromFunction(fn:HostEvent -> Void):EventListener {
		return new EventListener(fn);
	}

	/**
		Create a listener that filters events by type before calling the callback.
	**/
	public static function filtered(eventType:EventType, callback:HostEvent -> Void):EventListener {
		return new EventListener(function(event:HostEvent) {
			if (event.eventType == eventType) {
				callback(event);
			}
		});
	}

	/**
		Create a listener that filters events by VM name before calling the callback.
	**/
	public static function forVM(vmName:String, callback:HostEvent -> Void):EventListener {
		return new EventListener(function(event:HostEvent) {
			if (event.vmName == vmName) {
				callback(event);
			}
		});
	}

	/**
		Create a listener that filters events by category before calling the callback.
	**/
	public static function byCategory(category:String, callback:HostEvent -> Void):EventListener {
		return new EventListener(function(event:HostEvent) {
			if (event.getCategory() == category) {
				callback(event);
			}
		});
	}

	/**
		Create a listener that only handles critical events.
	**/
	public static function critical(callback:HostEvent -> Void):EventListener {
		return new EventListener(function(event:HostEvent) {
			if (event.isCritical()) {
				callback(event);
			}
		});
	}

	/**
		Combine multiple listeners into one.
	**/
	public static function combine(listeners:Array<EventListener>):EventListener {
		return new EventListener(function(event:HostEvent) {
			for (listener in listeners) {
				listener.handle(event);
			}
		});
	}
}
