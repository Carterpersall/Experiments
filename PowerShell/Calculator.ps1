#Prompts

$in = Read-Host -Prompt "Enter the first number"
$in2 = Read-Host -Prompt "Enter the second number"
$op = Read-Host -Prompt "Enter the operator(+,-,*,/,^)"

#Functions

function Add{
    param($a, $b) # Inputs

    # Converts inputs to char arrays and reserses them to make addition easier
    $a = $a.toCharArray()
    [Array]::Reverse($a)
    $b = $b.toCharArray()
    [Array]::Reverse($b)

    # Fills smaller array's null values with 0
    if ($b.Length -lt $a.Length) {
        for ($i = -1; $i -lt ($a.Length - $b.Length); $i++) {
            $b += [Char]'0'
        }
    }else{
        for ($i = -1; $i -lt ($b.Length - $a.Length); $i++) {
            $a += [Char]'0'
        }
    }

    $carry = 0

    for ($i = 0; ($i -lt $a.length) -or ($i -lt $b.length); $i++) {
        <#
        # Verbose 
        $Vans = [int][char]::GetNumericValue($a[$i]) + [int][char]::GetNumericValue($b[$i]) + $carry
        $Va = [int][char]::GetNumericValue($a[$i])
        $Vb = [int][char]::GetNumericValue($b[$i])
        Write-Host "$Va + $Vb + $carry = $Vans"
        #>
        # Adds Values by converting char to int, then converts the result to a string, then back to a char array
        $char = ([int][char]::GetNumericValue($a[$i]) + [int][char]::GetNumericValue($b[$i]) + $carry).ToString() -split ''

        if ($char.length -eq '4'){
            $carry = 1
            $doneChar = $char[2]
        }else{
            $carry = 0
            $doneChar = $char
        }
        $out += $doneChar
    }
    
    [array]::Reverse($out)
    $return = $out.Split('',[System.StringSplitOptions]::RemoveEmptyEntries)
    return -join $return
}

#Formatting and Outputs

if($op -eq "+"){
    $result = Add $in $in2
}

Write-Host $result