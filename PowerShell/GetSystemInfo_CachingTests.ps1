# Source: https://www.reddit.com/r/PowerShell/comments/4eus64/direct_device_access_using_reflection_and_the/

# Define the Assembly, Module, and Type Builders
$DynamicType = [System.Reflection.Emit.AssemblyBuilder]::DefineDynamicAssembly(
    # Assembly Name
    ([System.Reflection.AssemblyName]::new("DynamicAssembly")),
    # The dynamic assembly can be executed and saved
    [Reflection.Emit.AssemblyBuilderAccess]::RunAndCollect
).DefineDynamicModule("DynamicModule").DefineType("Device", [Reflection.TypeAttributes]::Public)

# Define GetSystemInfo method
($DynamicType.DefineMethod(
    # Method Name
    "GetSystemInfo",
    # Method Attributes
    ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static),
    # Calling Convention
    [Reflection.CallingConventions]::Standard,
    # Return Type
    [Void],
    # Method Parameters
    @([System.IntPtr])
)).SetCustomAttribute(
    #(Invoke-DefineMethodAttributes -Library "kernel32.dll" -EntryPoint "GetSystemInfo")
    (New-Object Reflection.Emit.CustomAttributeBuilder(
        [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String])),
        @("kernel32.dll"),
        @(
            [Runtime.InteropServices.DllImportAttribute].GetField("EntryPoint"),
            [Runtime.InteropServices.DllImportAttribute].GetField("PreserveSig"),
            [Runtime.InteropServices.DllImportAttribute].GetField("SetLastError"),
            [Runtime.InteropServices.DllImportAttribute].GetField("CallingConvention"),
            [Runtime.InteropServices.DllImportAttribute].GetField("CharSet")
        ),
        @(
            "GetSystemInfo",
            $true,
            $true,
            [Runtime.InteropServices.CallingConvention]::Winapi,
            [Runtime.InteropServices.CharSet]::Unicode
        )
    ))
)

# Allocate buffer in memory
# The SYSTEM_INFO structure is 48 bytes in size
$Buffer = [Runtime.InteropServices.Marshal]::AllocHGlobal(48)

# Create and Invoke GetSystemInfo method
($DynamicType.CreateType())::GetSystemInfo($Buffer)

# Save the assembly to disk
$DynamicType.Assembly.Save("DynamicAssembly.dll")

$SystemInfo = [Byte[]]::new(48)
[System.Runtime.InteropServices.Marshal]::Copy($Buffer, $SystemInfo, 0, 48)
@{
    # https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/ns-sysinfoapi-system_info
    # wProcessorArchitecture: The processor architecture of the installed operating system
    wProcessorArchitecture = [BitConverter]::ToUInt16($SystemInfo, 0)
    # wReserved: This member is reserved for future use
    wReserved = [BitConverter]::ToUInt16($SystemInfo, 2)
    # dwPageSize: The page size and the granularity of page protection and commitment
    dwPageSize = [BitConverter]::ToUInt32($SystemInfo, 4)
    # lpMinimumApplicationAddress: A pointer to the lowest memory address accessible to applications and DLLs
    lpMinimumApplicationAddress = [BitConverter]::ToInt64($SystemInfo, 8)
    # lpMaximumApplicationAddress: A pointer to the highest memory address accessible to applications and DLLs
    lpMaximumApplicationAddress = [BitConverter]::ToInt64($SystemInfo, 16)
    # dwActiveProcessorMask: A mask representing the set of processors configured into the system
    dwActiveProcessorMask = [BitConverter]::ToInt64($SystemInfo, 24)
    # dwNumberOfProcessors: The number of logical processors in the current group (Maximum 64)
    dwNumberOfProcessors = [BitConverter]::ToUInt32($SystemInfo, 32)
    # dwProcessorType: The type of processor in the system, obsolete
    dwProcessorType = [BitConverter]::ToUInt32($SystemInfo, 36)
    # dwAllocationGranularity: The granularity for the starting address at which virtual memory can be allocated
    dwAllocationGranularity = [BitConverter]::ToUInt32($SystemInfo, 40)
    # wProcessorLevel: The architecture-dependent processor level
    wProcessorLevel = [BitConverter]::ToUInt16($SystemInfo, 44)
    # wProcessorRevision: The architecture-dependent processor revision
    wProcessorRevision = [BitConverter]::ToUInt16($SystemInfo, 46)
}