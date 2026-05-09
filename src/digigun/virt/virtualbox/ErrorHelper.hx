package digigun.virt.virtualbox;

import cpp.Pointer;
import digigun.virt.virtualbox.raw.Native;
import digigun.virt.virtualbox.raw.Types.NativeErrorInfo;

/**
 * Internal helper utilities for consistent error handling and null checks.
 * This module consolidates error patterns to reduce duplication and ensure
 * consistent error reporting across the VirtualBox binding.
 */
class ErrorHelper {
    /**
     * Captures the last native error and returns a typed error.
     * Call this after any Native function that may have failed.
     */
    public static function captureConnectionError(?operation:String, ?param:String):ConnectionError {
        var msg = getNativeErrorMessage();
        var code = getNativeErrorCode();
        return new ConnectionError(msg, code, {operation: operation, param: param});
    }
    
    public static function captureMachineError(?operation:String, ?param:String):MachineError {
        var msg = getNativeErrorMessage();
        var code = getNativeErrorCode();
        return new MachineError(msg, code, {operation: operation, param: param});
    }
    
    public static function captureSessionError(?operation:String, ?param:String):SessionError {
        var msg = getNativeErrorMessage();
        var code = getNativeErrorCode();
        return new SessionError(msg, code, {operation: operation, param: param});
    }
    
    /**
     * Check if a native function returned null pointer (failure indicator)
     * and throw appropriate typed error.
     */
    public static function checkPointerOrThrow<T>(ptr:cpp.RawPointer<T>, operation:String, ?param:String):cpp.RawPointer<T> {
        if (ptr == null) {
            throw captureConnectionError(operation, param);
        }
        return ptr;
    }
    
    /**
     * Check if a native function returned 0 (failure indicator)
     * and throw appropriate typed error.
     */
    public static function checkReturnCodeOrThrow(code:Int, operation:String, ?param:String, ?errorType:String = "connection"):Void {
        if (code == 0) {
            switch (errorType) {
                case "machine":
                    throw captureMachineError(operation, param);
                case "session":
                    throw captureSessionError(operation, param);
                default:
                    throw captureConnectionError(operation, param);
            }
        }
    }
    
    /**
     * Safe string conversion from C char pointer.
     * Returns null for null pointers, converts empty to null if desired.
     */
    public static inline function toNullableString(value:cpp.ConstCharStar, ?nullEmpty:Bool = false):Null<String> {
        if (value == null) return null;
        var str = value.toString();
        if (nullEmpty && str == "") return null;
        return str;
    }
    
    /**
     * Validates that a string is not null or empty, throws if invalid.
     * Useful for required parameters before native calls.
     */
    public static function validateString(value:Null<String>, paramName:String, ?operation:String):String {
        if (value == null || value == "") {
            throw new MachineError('Invalid $paramName: cannot be empty', -1, {operation: operation, param: paramName});
        }
        return value;
    }
    
    /**
     * Get the last native error message, with fallback.
     */
    private static function getNativeErrorMessage():String {
        #if cpp
        var raw = Native.getLastError();
        if (raw == null) {
            return "VirtualBox operation failed without error details";
        }
        var info:NativeErrorInfo = Pointer.fromRaw(raw).value;
        var msg = toNullableString(info.message);
        return (msg != null && msg != "") ? msg : "VirtualBox operation failed";
        #else
        return "VirtualBox operation failed";
        #end
    }
    
    /**
     * Get the last native error code.
     */
    private static function getNativeErrorCode():Int {
        #if cpp
        var raw = Native.getLastError();
        if (raw == null) return -1;
        var info:NativeErrorInfo = Pointer.fromRaw(raw).value;
        return info.code;
        #else
        return -1;
        #end
    }
}
