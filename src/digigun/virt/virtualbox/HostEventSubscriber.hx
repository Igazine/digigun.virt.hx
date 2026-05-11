package digigun.virt.virtualbox;

#if cpp
import cpp.RawPointer;
#end

/**
	HostEventSubscriber manages event subscriptions and routes events to callbacks.
	
	This class handles the lifecycle of event subscriptions, from registration
	to event polling and callback invocation.
**/
class HostEventSubscriber {
	/**
		The event type this subscriber is listening for.
	**/
	public final eventType:EventType;

	/**
		Unique subscription identifier (for C layer tracking).
	**/
	private var subscriptionId:Int;

	/**
		VirtualBox context pointer.
	**/
	#if cpp
	private var vboxContext:RawPointer<cpp.Void>;
	#else
	private var vboxContext:Dynamic;
	#end

	/**
		List of registered event listeners/callbacks.
	**/
	private var listeners:Array<EventListener>;

	/**
		Flag indicating if this subscription is active.
	**/
	private var isActive:Bool;

	/**
		Creates a new event subscriber for the given event type.
		
		@param eventType The type of events to subscribe to
		@param vboxContext VirtualBox context pointer from VirtualBox.open()
	**/
	#if cpp
	public function new(eventType:EventType, vboxContext:RawPointer<cpp.Void>) {
		this.eventType = eventType;
		this.vboxContext = vboxContext;
		this.listeners = [];
		this.subscriptionId = 0;
		this.isActive = false;
	}
	#else
	public function new(eventType:EventType, vboxContext:Dynamic) {
		this.eventType = eventType;
		this.vboxContext = vboxContext;
		this.listeners = [];
		this.subscriptionId = 0;
		this.isActive = false;
	}
	#end

	/**
		Register a native VirtualBox event listener.
		Returns true on success, false on failure.
	**/
	#if cpp
	private function registerNative():Bool {
		if (isActive) {
			return false;
		}

		var nativeSub = untyped __cpp__("hx_vbox_register_event_listener(vboxContext, {0})", eventType.toString());
		if (nativeSub == null) {
			return false;
		}

		var sub = cpp.Pointer.fromRaw(nativeSub);
		if (sub.ref.success == 0) {
			untyped __cpp__("hx_vbox_event_subscription_free(nativeSub)");
			return false;
		}

		subscriptionId = sub.ref.subscriptionId;
		isActive = true;
		untyped __cpp__("hx_vbox_event_subscription_free(nativeSub)");
		return true;
	}
	#else
	private function registerNative():Bool {
		return false;
	}
	#end

	/**
		Unregister from native VirtualBox event listener.
		Returns true on success, false on failure.
	**/
	#if cpp
	private function unregisterNative():Bool {
		if (!isActive || subscriptionId == 0) {
			return false;
		}

		var result = untyped __cpp__("hx_vbox_unregister_event_listener(vboxContext, {0})", subscriptionId);
		if (result != 0) {
			return false;
		}

		isActive = false;
		subscriptionId = 0;
		return true;
	}
	#else
	private function unregisterNative():Bool {
		return false;
	}
	#end

	/**
		Poll for a single event from the native queue.
		Returns the event or null if none available.
	**/
	#if cpp
	private function pollNativeEvent():HostEvent {
		if (!isActive || subscriptionId == 0) {
			return null;
		}

		var nativeEvent = untyped __cpp__("hx_vbox_poll_event(vboxContext, {0})", subscriptionId);
		if (nativeEvent == null) {
			return null;
		}

		var eventPtr = cpp.Pointer.fromRaw(nativeEvent);
		if (eventPtr.ref.success == 0) {
			untyped __cpp__("hx_vbox_event_free(nativeEvent)");
			return null;
		}

		var eventType = eventPtr.ref.eventType;
		var vmName = eventPtr.ref.vmName;
		var description = eventPtr.ref.description;

		var event = new HostEvent(
			eventType.toString(),
			eventPtr.ref.timestamp,
			vmName.toString(),
			description.toString()
		);

		untyped __cpp__("hx_vbox_event_free(nativeEvent)");
		return event;
	}
	#else
	private function pollNativeEvent():HostEvent {
		return null;
	}
	#end

	/**
		Register a listener callback for this subscription.
		Multiple listeners can be registered.
	**/
	public function addListener(listener:EventListener):Void {
		if (listener == null) {
			return;
		}
		listeners.push(listener);
	}

	/**
		Remove a listener callback from this subscription.
	**/
	public function removeListener(listener:EventListener):Bool {
		return listeners.remove(listener);
	}

	/**
		Remove all registered listeners.
	**/
	public function clearListeners():Void {
		listeners = [];
	}

	/**
		Get the number of registered listeners.
	**/
	public function getListenerCount():Int {
		return listeners.length;
	}

	/**
		Start the event subscription.
		Returns true on success, false on failure.
	**/
	public function start():Bool {
		if (isActive) {
			return true;
		}
		return registerNative();
	}

	/**
		Stop the event subscription.
		Returns true on success, false on failure.
	**/
	public function stop():Bool {
		return unregisterNative();
	}

	/**
		Check if the subscription is currently active.
	**/
	public function getIsActive():Bool {
		return isActive;
	}

	/**
		Poll for a single event and dispatch it to all registered listeners.
		Returns true if an event was received and dispatched.
	**/
	public function pollAndDispatch():Bool {
		var event = pollNativeEvent();
		if (event == null) {
			return false;
		}

		for (listener in listeners) {
			listener.handle(event);
		}

		return true;
	}

	/**
		Poll for all available events and dispatch them to all listeners.
		Returns the number of events dispatched.
	**/
	public function pollAllAndDispatch():Int {
		var count = 0;
		while (pollAndDispatch()) {
			count++;
		}
		return count;
	}

	/**
		Cleanup: stop the subscription and clear all listeners.
	**/
	public function dispose():Void {
		stop();
		clearListeners();
		vboxContext = null;
	}
}
