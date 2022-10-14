### Variables ###

# Performance Settings
$PrintFrequency = 100000
$SleepTime = $null

# Physics Settings
$Gravity = -9.81 # meters/second^2

# Initial State
$Position = [System.Numerics.Vector2]::new(0, 1e4) # meters
$Velocity = [System.Numerics.Vector2]::new(1, 0)
$Acceleration = [System.Numerics.Vector2]::new(0, 0)
$Force = [System.Numerics.Vector2]::new(0, 0) # Unused for now
$Mass = 1 # Kilograms

# Monitoring Variables
$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$DeltaTime = 0
$LastTime = 0
$Time = 0
$TotalIterations = 0


### Functions ###

# Delta Time
function Get-DeltaTime {
    
}

# Main Loop
while ($true) {
    # Get time since last iteration
    $LastTime = $Time
    $Time = $Stopwatch.ElapsedTicks * 0.0000001
    $DeltaTime = $Time - $LastTime

    ### Physics ###

    # Calculate Acceleration
    # TODO: Make every object have gravity
    #$Acceleration = $Force / $Mass
    $Acceleration.X = 0
    $Acceleration.Y = $Gravity

    # Calculate Velocity
    $Velocity += $Acceleration * $DeltaTime

    # Calculate Position
    $Position += $Velocity * $DeltaTime
    if($Position.Y -lt 0) {
        $Position.Y = 0
        $Velocity.Y = 0
    }

    ### Output ###

    if(($TotalIterations % $PrintFrequency) -eq 0) {
        Clear-Host
        Write-Host "Position: $Position"
        Write-Host "Velocity: $Velocity"
        Write-Host "Acceleration: $Acceleration"
        Write-Host "Force: $Force"
        Write-Host "Mass: $Mass"
        Write-Host "DeltaTime: $Time - $LastTime = $DeltaTime"
        Write-Host "TotalTicks: $($Stopwatch.ElapsedTicks)"
        Write-Host "TotalMilliseconds: $($Stopwatch.ElapsedMilliseconds)"
        Write-Host "TotalIterations: $TotalIterations"
        Write-Host "TimePerIteration: $($Stopwatch.ElapsedMilliseconds / $TotalIterations)"
        Write-Host ""
    }
    $TotalIterations++

    ### Sleep ###
    if($SleepTime){Start-Sleep -Milliseconds $SleepTime}
}