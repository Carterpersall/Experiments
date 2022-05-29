# Functions

#Processes the Collatz Sequence and returns the number of operations
function processNum{
    param($num)
    $ops = 0
    while($num -ne 1){
        if($num % 2 -eq 0){
            $num = $num / 2
        }else{
            $num = ($num * 3) + 1
        }
        $ops++
    }
    return $ops
}

#Writes each number in the Collatz Sequence
function processNumVerbose{
    param($num)
    $ops = 0
    while($num -ne 1){
        if($num % 2 -eq 0){
            $num = $num / 2
        }else{
            $num = ($num * 3) + 1
        }
        $ops++
        Write-Host $num
    }
    return $ops
}


# Logic

$number = Read-Host "Please enter a number(auto for auto mode)"
$operations = 0

if ($number -eq "auto"){
    [int]$max = Read-Host "Please enter the end number"
    $num = 1
    $topOps = 0
    $topOpNum = 0
    [int]$reportInteval = Read-Host "Please enter the report interval"

    while($num -ne $max + 1){
        $operations = processNum $num
        if($num % $reportInteval -eq 0){
            Write-Host "Number: $num - Operations: $operations"
        }
        if($operations -gt $topOps){
            $topOps = $operations
            $topOpNum = $num
        }
        $num++
    }
    Write-Host "The longest chain is $topOpNum with $topOps operations"
}else{
    $number = [int]$number
    $operations = processNumVerbose $number
    Write-Host "It took $operations operations to reach 1 from $number."
}