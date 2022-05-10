while(!$done){
    $ipBase = Read-Host "Enter the Beginning of the IP Range(Ex:192.168.0. or 10.38.)"
    if(($null -ne $ipBase) -and ($ipBase.Substring($ipBase.Length - 1, 1) -ne ".")){
        Write-Host "You must enter a value with a period at the end"
    }else{
        $done = $true
    }
}
$done = $null

function getRange{
    while(!$done){
        $rangeBeg = [int](Read-Host "Enter the Beginning of the Range of IPs to check(0 - 255)")

        if($null -eq $rangeBeg){Write-Host "You must enter a value"}

        if(($rangeBeg -lt 0) -or ($rangeBeg -gt 255)){
            Write-Host "Invalid Value"
        }else{
            $done = $true
        }
    }
    $done = $null
    
    while(!$done){
        $rangeEnd = [int](Read-Host "Enter the End of the Range of IPs to check(0 - 255)")

        if($null -eq $rangeEnd){Write-Host "You must enter a value"}

        if(($rangeEnd -lt 0) -or ($rangeEnd -gt 255) -or ($rangeEnd -lt $rangeBeg)){
            Write-Host "Invalid Value"
        }else{
            $done = $true
        }
    }
    $done = $null

    return $rangeBeg..$rangeEnd
}

Write-Host "First Range(192.168.0.X):"

$rangeOne = getRange

if(($ipBase.ToCharArray() | Where-Object {$_ -eq '.'} | Measure-Object).Count -lt 3){
    Write-Host "Second Range(192.168.X.0):"

    $rangeTwo = getRange
}

if(($ipBase.ToCharArray() | Where-Object {$_ -eq '.'} | Measure-Object).Count -lt 2){
    Write-Host "Third Range(192.X.0.0):"

    $rangeThree = getRange
}

if($null -eq $ipBase){
    Write-Host "Fourth Range(X.0.0.0):"

    $rangeFour = getRange
}

$printResolved = Read-Host "Print Resolved IPs?(y/n)"
if ($printResolved -eq "y"){$printResolved = $true}else{$printResolved = $false}

if($rangeFour){
    $rangeCount = $rangeOne.Count * $rangeTwo.Count * $rangeThree.Count * $rangeFour.Count
}elseif($rangeThree){
    $rangeCount = $rangeOne.Count * $rangeTwo.Count * $rangeThree.Count
}elseif($rangeTwo){
    $rangeCount = $rangeOne.Count * $rangeTwo.Count
}else{
    $rangeCount = $rangeOne.Count
}


if ($null -ne $rangeFour){
    foreach ($numOne in $rangeOne){
        foreach ($numTwo in $rangeTwo){
            foreach ($numThree in $rangeThree){
                foreach ($numFour in $rangeFour){
                    #Merge the given IP base with the current point in the range
                    $ip = $numFour + "." + $numThree + "." + $numTwo + "." + $numOne

                    #Create a progress bar
                    Write-Progress -Activity "Queuing IP Address Scans" -Status "Queuing IP Address: $ip" -PercentComplete ([Math]::Truncate(($numFour * $numThree * $numTwo * $numOne) * 100/$rangeCount))

                    #Queue the IP addresses to be scanned into separate threads
                    Start-Job -InputObject "$ip" -ScriptBlock {
                        Get-WmiObject Win32_PingStatus -Filter "Address='$input' and Timeout=200 and ResolveAddressNames='true' and StatusCode=0" | Select-Object ProtocolAddress*
                    } | Out-Null
                }
            }
        }
    }
}elseif($null -ne $rangeThree){
    foreach ($numOne in $rangeOne){
        foreach ($numTwo in $rangeTwo){
            foreach ($numThree in $rangeThree){
                #Merge the given IP base with the current point in the range
                $ip = $ipBase + $numThree + "." + $numTwo + "." + $numOne

                #Create a progress bar
                Write-Progress -Activity "Queuing IP Address Scans" -Status "Queuing IP Address: $ip" -PercentComplete ([Math]::Truncate(($numOne) * 100/$rangeOne.Count))

                #Queue the IP addresses to be scanned into separate threads
                Start-Job -InputObject "$ip" -ScriptBlock {
                    Get-WmiObject Win32_PingStatus -Filter "Address='$input' and Timeout=200 and ResolveAddressNames='true' and StatusCode=0" | Select-Object ProtocolAddress*
                } | Out-Null
            }
        }
    }
}elseif($null -ne $rangeTwo){
    foreach ($numOne in $rangeOne){
        foreach ($numTwo in $rangeTwo){
            #Merge the given IP base with the current point in the range
            $ip = $ipBase + $numTwo + "." + $numOne

            #Create a progress bar
            Write-Progress -Activity "Queuing IP Address Scans" -Status "Queuing IP Address: $ip" -PercentComplete ([Math]::Truncate(($numOne) * 100/$rangeOne.Count))

            #Queue the IP addresses to be scanned into separate threads
            Start-Job -InputObject "$ip" -ScriptBlock {
                Get-WmiObject Win32_PingStatus -Filter "Address='$input' and Timeout=200 and ResolveAddressNames='true' and StatusCode=0" | Select-Object ProtocolAddress*
            } | Out-Null
        }
    }
}else{
    foreach ($numOne in $rangeOne){
        #Merge the given IP base with the current point in the range
        $ip = $ipBase + $numOne

        #Create a progress bar
        Write-Progress -Activity "Queuing IP Address Scans" -Status "Queuing IP Address: $ip" -PercentComplete ([Math]::Truncate(($numOne) * 100/$rangeOne.Count))

        #Queue the IP addresses to be scanned into separate threads
        Start-Job -InputObject "$ip" -ScriptBlock {
            Get-WmiObject Win32_PingStatus -Filter "Address='$input' and Timeout=200 and ResolveAddressNames='true' and StatusCode=0" | Select-Object ProtocolAddress*
        } | Out-Null
    }
}


do{
    $num = 0
    Get-Job | ForEach-Object{
        if($_.State -eq 'Completed'){$num++}
    }

    #Show Scan Completion Progress
    Write-Progress -Activity "IP Address Scan Progress" -Status "IP Addresses Scanned: $num" -PercentComplete ([Math]::Truncate(($numOne) * 100/$rangeOne.Count))

    Start-Sleep -s 1
}until($num -eq $rangeCount) #Won't stop until all scans are complete


#Output the results
Write-Host "Found Addresses:"
if ($printResolved){
    Get-Job | Receive-Job | Select-Object ProtocolAddress*
}else{
    $output = Get-Job | Receive-Job | Select-Object ProtocolAddress | Out-String
    $output = $output -replace "ProtocolAddress" -replace "-"
    $output
}

#Remove Completed Jobs
Get-Job | Remove-Job