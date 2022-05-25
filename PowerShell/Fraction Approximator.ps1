[Decimal]$Number = Read-Host "Enter a number"

$MaxOps = Read-Host "Enter the maximum number of operations"

$Floor = [Math]::Floor($Number)
$Ceil = [Math]::Ceiling($Number)
$FloorDen = 1
$CeilDen = 1
$operations = 0

function Simplify{
    param($Num, $Den)
    if($Num % $Den -eq 0){
        return $Num / $Den
    }

    Write-Host "Atempting to simplify $Num / $Den"
    
    $Div = 2
    if($Num -gt $Den){
        $Max = $Num / 2
    }else{
        $Max = $Den / 2
    }

    if($Max -gt 10000000){
        $Max = 10000000
    }

    while($Div -lt $Max){
        if(($Num % $Div -eq 0) -and ($Den % $Div -eq 0)){
            $MaxDiv = $Div
        }
        $Div++
    }
    if ($MaxDiv){
        $Num = $Num / $MaxDiv
        $Den = $Den / $MaxDiv
    }
    return "$Num / $Den"
}

while($operations -lt $MaxOps){
    $currentNum = $Floor + $Ceil
    $currentDen = $FloorDen + $CeilDen
    if($Number -lt [Decimal]([Decimal]$currentNum / [Decimal]$currentDen)){
        $Ceil = $currentNum
        $CeilDen = $currentDen
    }elseif($Number -gt [Decimal]([Decimal]$currentNum / [Decimal]$currentDen)){
        $Floor = $currentNum
        $FloorDen = $currentDen
    }else{
        $out = Simplify $currentNum $currentDen
        Write-Host ("The fraction $out is equal to $Number.")
        $EndEarly = $true
        break
    }
    $operations++
}

if(!$EndEarly){
    $out = Simplify $currentNum $currentDen
    Write-Host "The fraction $out is the closest approximation to $Number."
}