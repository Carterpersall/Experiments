### Variables ###

param(
    # Number of times to execute the scriptblock
    [int]$Iterations = 10,
    # Whether to preheat the cache
    [switch]$Preheat,
    # Number of times to execute the scriptblock before timing
    [int]$PreheatIterations = 2,
    # Scriptblock to execute
    [scriptblock]$ScriptBlock = {},
    # Unit of time to use
    [String]$Unit = "Seconds",
    # Use graphs
    [switch]$Graph
)

# Array of all times
[System.Collections.ArrayList]$AllTimes = @()

# Array of average time history
[System.Collections.ArrayList]$AverageTimes = @()

# Total execution time of the scriptblock
$TotalTime = 0

# Current iteration
$CurrentIteration = 0


### Import ###

# Graph Maker
if ($Graph) {Import-Module .\Graphical}


### Execution ###

if ($Preheat) {
    # Preheat the cache
    Write-Host "Preheating the script"
    (1..$PreheatIterations).ForEach{
        [void](pwsh -noprofile -command $ScriptBlock *>&1)
    }
}


Write-Host "Getting speed of scriptblock $Iterations times"

(1..$Iterations).foreach{
    (pwsh -NoProfile -Command {
        # Get the scriptblock
        param($ScriptBlock)
        
        # For some reason, PowerShell converts the scriptblock to a string, so we need to convert it back
        $ScriptBlock = [scriptblock]::Create($ScriptBlock)

        (Measure-Command $ScriptBlock *>&1).TotalSeconds
        
        # Alternative method (Returning wrong values for some reason)
        # Start the timer
        <#
        $Time = [System.Diagnostics.Stopwatch]::StartNew()

        # Execute the scriptblock
        [void](. $ScriptBlock *>&1)

        # Return the Elapsed time
        $Time.Elapsed.TotalSeconds
        #>
    } -Args $ScriptBlock).foreach{
        $CurrentIteration++
        [void]($AllTimes.Add($_))
        $TotalTime += $_
        Write-Progress -Activity "Execution Progress" -Status "Iteration $CurrentIteration" -PercentComplete ($CurrentIteration / $Iterations * 100) -Id 1
        $AverageTime = $TotalTime / $CurrentIteration
        [void]($AverageTimes.Add($AverageTime * 10000000)) # In ticks
        if ($Graph) {Show-Graph -Datapoints $AverageTimes -XAxisTitle "Iteration" -YAxisTitle "Time (Ticks)" -GraphTitle "Average Time" -XAxisStep 10 -YAxisStep 100 -WarningAction SilentlyContinue}
        Write-Progress -Activity "Average Time: $([int]($AverageTime * 1e4) / 1e4)" -Status "Previous Time: $_" -PercentComplete $($AverageTime / ($AllTimes | Sort-Object -Descending)[0] * 100) -Id 2
    }
}


### Post-Proccessing ###

$AverageTime = $TotalTime / $Iterations


### Output ###

Write-Host "Average time: $AverageTime"