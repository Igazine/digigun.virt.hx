package digigun.virt.virtualbox;

/**
	Callback interface for tracking machine clone progress.
	
	Optional interface for monitoring long-running clone operations.
	Implement this interface and pass to cloneMachine() to receive progress updates.
**/
typedef CloneProgressCallback = {
	/**
		Called when clone operation starts.
		
		@param targetName Name of the target VM being cloned to
		@param mode Clone mode being used
	**/
	function onCloneStart(targetName:String, mode:MachineCloneMode):Void;

	/**
		Called periodically during clone operation with progress update.
		
		@param percentComplete Current completion percentage (0-100)
		@param currentOperation Description of current operation being performed
	**/
	function onCloneProgress(percentComplete:Int, currentOperation:String):Void;

	/**
		Called when clone operation completes successfully.
		
		@param targetName Name of the newly created clone VM
		@param clonedMachineUuid UUID of the cloned machine
	**/
	function onCloneComplete(targetName:String, clonedMachineUuid:String):Void;

	/**
		Called if clone operation fails.
		
		@param targetName Name of target VM (partially created if clone failed mid-operation)
		@param errorCode VirtualBox error code
		@param errorMessage Human-readable error description
	**/
	function onCloneError(targetName:String, errorCode:Int, errorMessage:String):Void;
};
