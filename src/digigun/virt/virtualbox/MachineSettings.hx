package digigun.virt.virtualbox;

/**
 * Configuration settings for a VirtualBox machine
 * 
 * Used to specify or modify machine properties during creation or update.
 * Not all fields need to be specified - omitted fields use defaults or existing values.
 * 
 * **Memory and CPU Limits:**
 * - Memory: 4-2097152 MB (4 MB to 2 TB)
 * - CPUs: 1-32 (or system maximum)
 * 
 * **Example:**
 * ```haxe
 * var settings:MachineSettings = {
 *     memoryMB: 2048,
 *     vCpuCount: 2,
 *     osTypeId: "Ubuntu22_64"
 * };
 * ```
 */
typedef MachineSettings = {
    /**
     * Amount of RAM in megabytes (optional)
     * 
     * If omitted, defaults to 512 MB or existing value when modifying.
     */
    ?memoryMB:Int,

    /**
     * Number of virtual CPUs (optional)
     * 
     * If omitted, defaults to 1 or existing value when modifying.
     * Must be between 1 and host CPU count.
     */
    ?vCpuCount:Int,

    /**
     * Operating system type identifier (optional)
     * 
     * Examples: "Ubuntu22_64", "Windows11_64", "CentOS_64", "Other"
     * Used only during machine creation. Cannot be changed after creation.
     * If omitted during creation, defaults to "Other".
     */
    ?osTypeId:String,

    /**
     * Machine name (optional)
     * 
     * If omitted during creation, a unique name is generated.
     * Cannot be changed after creation.
     */
    ?name:String,

    /**
     * Machine description (optional)
     * 
     * Human-readable description. Can be modified at any time.
     */
    ?description:String,

    /**
     * Base folder for machine files (optional)
     * 
     * If omitted, VirtualBox uses the default machines folder.
     * Must be an absolute path.
     * Used only during machine creation.
     */
    ?baseFolder:String,
};
