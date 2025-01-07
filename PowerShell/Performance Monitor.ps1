## Configuration ##

$processProperties = [System.Collections.ArrayList]@(
    #'BasePriority'
    #'Container'
    #'EnableRaisingEvents'
    #'ExitCode'
    #'ExitTime'
    #'Handle'
    #'HandleCount'
    #'HasExited'
    #'Id'
    #'MachineName'
    #'MainModule'
    #'MainWindowHandle'
    #'MainWindowTitle'
    #'MaxWorkingSet'
    #'MinWorkingSet'
    #'Modules'
    #'NonpagedSystemMemorySize'
    #'NonpagedSystemMemorySize64'
    #'PagedMemorySize'
    #'PagedMemorySize64'
    #'PagedSystemMemorySize'
    #'PagedSystemMemorySize64'
    #'PeakPagedMemorySize'
    #'PeakPagedMemorySize64'
    #'PeakVirtualMemorySize'
    #'PeakVirtualMemorySize64'
    #'PeakWorkingSet'
    #'PeakWorkingSet64'
    #'PriorityBoostEnabled'
    #'PriorityClass'
    #'PrivateMemorySize'
    'PrivateMemorySize64'
    #'PrivilegedProcessorTime'
    'ProcessName'
    #'ProcessorAffinity'
    #'Responding'
    #'SafeHandle'
    #'SessionId'
    #'Site'
    #'StandardError'
    #'StandardInput'
    #'StandardOutput'
    #'StartInfo'
    #'StartTime'
    #'SynchronizingObject'
    #'Threads'
    #'TotalProcessorTime'
    #'UserProcessorTime'
    #'VirtualMemorySize'
    #'VirtualMemorySize64'
    #'WorkingSet'
    #'WorkingSet64'
    'CPU'
    'CPUUsage'
)


## Initialization ##

# Get CPU thread count
$CPUs = [System.Environment]::ProcessorCount

# Start the CPU counter
$CPUCounter = New-Object System.Diagnostics.PerformanceCounter
$CPUCounter.CategoryName = "Processor"
$CPUCounter.CounterName = "% Processor Time"
$CPUCounter.InstanceName = "_Total"

# Start the memory counter
$MemoryCounter = New-Object System.Diagnostics.PerformanceCounter
$MemoryCounter.CategoryName = "Memory"
$MemoryCounter.CounterName = "% Committed Bytes In Use"


## Functions ##

function get_cpu_usage {
    # Get the CPU usage
    $CPUCounter.NextValue()
}

function get_processes {
    # Get all running processes and assign to a variable to allow reuse
    $processes = [System.Diagnostics.Process]::GetProcesses()
    $procCount = $processes.Count
    # Get the number of logical processors in the system
    $CPUs = [System.Environment]::ProcessorCount

    $timeNow = [System.Datetime]::Now
    (0..($procCount - 1)).ForEach{
        $process = $processes[$_]

        if ($process.StartTime -gt 0) {
            # Replicate the functionality of New-Timespan
            $timespan = ($timeNow.Subtract($process.StartTime)).TotalSeconds

            # Calculate the CPU usage of the process and add to the total
            Add-Member -InputObject $process -MemberType NoteProperty -Name "CPUUsage" -Value ($process.CPU * 100 / $timespan / $CPUs)
            #$processes[$_].CPUUsage = $_.CPU * 100 / $timespan / $CPUs
        }
    }

    @($processes, $procCount)
}

function get_memory {
    # Get the memory usage
    $MemoryCounter.NextValue()
}


## Main Loop ##

while ($true) {
    # Clear the screen
    Clear-Host

    $cpu = get_cpu_usage
    $processes = get_processes
    $memory = get_memory

    # Write the CPU usage
    Write-Host "CPU Usage: $($cpu)% of $($CPUs) CPUs" -ForegroundColor Green
    Write-Host "Process Count: $($processes[1])" -ForegroundColor Green
    Write-Host "Memory Usage: $($memory)%" -ForegroundColor Green

    # Write top 10 processes
    Write-Host "Top 10 Processes:" -ForegroundColor Green
    $processes[0] | Sort-Object CPU -Descending | Select-Object -First 10 | Select-Object $processProperties | Format-Table -AutoSize

    # Wait 1 seconds before repeating
    Start-Sleep -Milliseconds 1000
}