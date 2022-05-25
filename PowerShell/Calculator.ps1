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

    for ($i = 0; ($i -lt $a.length) -or ($i -lt $b.length); $i++) {
        # Verbose 
        <#
        $Vans = [int][char]::GetNumericValue($a[$i]) + [int][char]::GetNumericValue($b[$i])
        $Va = [int][char]::GetNumericValue($a[$i])
        $Vb = [int][char]::GetNumericValue($b[$i])
        Write-Host "$Va + $Vb = $Vans"
        #>

        # Adds Values by converting char to int, then converts the result to a string, then back to a char array
        $d += ([int][char]::GetNumericValue($a[$i]) + [int][char]::GetNumericValue($b[$i])).ToString() -split ''
    }
    [array]::Reverse($d)
    return -join $d
}
$out = Add "1234" "12"
Write-Host $out