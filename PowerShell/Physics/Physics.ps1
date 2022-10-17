### Import ###

Install-Package -Name MathNet.Numerics -Destination .\MathNet.Numerics\ -Force -SkipDependencies
Install-Package -Name MathNet.Numerics.MKL.Win-x64 -Destination .\MathNet.Numerics.MKL.Win-x64\ -Force -SkipDependencies
#Install-Package -Name MathNet.Numerics.Data.Text -Destination .\MathNet.Numerics.Data.Text\ -Force -SkipDependencies
#Install-Package -Name MathNet.Numerics.Data.Matlab -Destination .\MathNet.Numerics.Data.Matlab\ -Force -SkipDependencies


### Initialize ###

# Load the Math.NET Numerics DLL (nearly always required):
Add-Type -Path '.\MathNet.Numerics\MathNet.Numerics.*.*.*\lib\net6.0\MathNet.Numerics.dll'

# Load the MathNet.Numerics.Data.Text DLL (optional):
#Add-Type -Path '.\MathNet.Numerics\lib\net6.0\MathNet.Numerics.Data.Text.dll'

# [M]: Create an accelerator shortcut [M] for use of Math.NET matrices:
#[psobject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::Add('M','MathNet.Numerics.LinearAlgebra.Matrix[Double]')

# [V]: Create an accelerator shortcut [V] for use of Math.NET vectors:
#[psobject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::Add('V','MathNet.Numerics.LinearAlgebra.Vector[Double]')

# [STAT]: Create an accelerator shortcut [STAT] for use of MathNet statistics:
#[psobject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::Add('STAT','MathNet.Numerics.Statistics.Statistics')

# [FUNC]: Create an accelerator shortcut [FUNC] for use of MathNet special functions:
#[psobject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::Add('FUNC','MathNet.Numerics.SpecialFunctions')

# Enable the use of Intel MKL for linear algebra:
[MathNet.Numerics.Control]::UseNativeMKL("Auto")

# Confirm the switch from "Managed" to "Intel MKL":
[MathNet.Numerics.Control]::LinearAlgebraProvider

# If you want to switch back to the default, slower, managed .NET code:
#[MathNet.Numerics.Control]::UseManaged()


### Variables ###

# Performance Settings
$PrintFrequency = 100000
$SleepTime = $null
$TimeStep = 1 # 1 = Real Time

# Physics Settings
# Mass of (currently) stagnant central body
$Mass = 5.972e24 # Kilograms
$GravityLocation = [MathNet.Numerics.LinearAlgebra.Vector[double]]::Build.Dense(@(0, 0))
$GravityRadius = 6.4e6 # Meters
$G = 6.674e-11 # (Newtons * Meters^2) / Kilograms^2

# Initial State
$Position = [MathNet.Numerics.LinearAlgebra.Vector[double]]::Build.Dense(@(0, 6.401e6)) # meters
$Velocity = [MathNet.Numerics.LinearAlgebra.Vector[double]]::Build.Dense(@(0, 0))
$Acceleration = [MathNet.Numerics.LinearAlgebra.Vector[double]]::Build.Dense(@(0, 0))
$Force = [MathNet.Numerics.LinearAlgebra.Vector[double]]::Build.Dense(@(0, 0))

# Monitoring Variables
$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$DeltaTime = 0
$LastTime = 0
$Time = 0
$TotalIterations = 0


### Functions ###

# Main Loop
while ($true) {
    # Get time since last iteration
    $LastTime = $Time
    $Time = $Stopwatch.ElapsedTicks * 1e-7
    $DeltaTime = ($Time - $LastTime) * $TimeStep


    ### Physics ###

    # Calculate Acceleration
    # TODO: Make every object have gravity
    $radius = [MathNet.Numerics.Distance]::MSE($Position, $GravityLocation)
    if($radius -gt $GravityRadius) {
        # Calculate gravitational force
        $Acceleration = -$G * ($Mass * ($Position.Subtract($GravityLocation))) / [Math]::Pow([Math]::Abs($radius), 3) # meters / second^2
    }else {
        # Impacted the central body
        $Acceleration = [MathNet.Numerics.LinearAlgebra.Vector[double]]::Build.Dense(@(0, 0))
        $Velocity = [MathNet.Numerics.LinearAlgebra.Vector[double]]::Build.Dense(@(0, 0))
    }

    # Calculate Velocity
    $Velocity += $Acceleration * $DeltaTime

    # Calculate Position
    $Position += $Velocity * $DeltaTime# * 30
    $TotalIterations++


    ### Output ###

    if(($TotalIterations % $PrintFrequency) -eq 1) {
        Clear-Host
        Write-Host "Position: $Position"
        Write-Host "Velocity: $Velocity"
        Write-Host "Acceleration: $Acceleration"
        Write-Host "Force: $Force"
        Write-Host "Mass: $Mass"
        Write-Host "DeltaTime: ($Time - $LastTime) * $TimeStep = $DeltaTime"
        Write-Host "TotalTicks: $($Stopwatch.ElapsedTicks)"
        Write-Host "TotalMilliseconds: $($Stopwatch.ElapsedMilliseconds)"
        Write-Host "TotalIterations: $TotalIterations"
        Write-Host "TimePerIteration: $($Stopwatch.ElapsedMilliseconds / $TotalIterations)"
        Write-Host ""
    }

    ### Sleep ###
    if($SleepTime){Start-Sleep -Milliseconds $SleepTime}
}