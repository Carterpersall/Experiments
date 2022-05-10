while(!$done){
    $ipBase = Read-Host "Enter the Beginning of the IP Range(Ex:192.168.0.)"
    if($null -eq $ipBase){Write-Host "You must enter a value"}
    if($ipBase.Substring($ipBase.Length - 2,$ipBase.Length - 1 -ne ".")){
        Write-Host "You must enter a value with a period at the end"
    }else{
        $done = $true
    }
}
$done = $null

while(!$done){
    $rangeB = Read-Host "Enter the Beginning of the Range of IPs to check(0 - 255)"
    if($null -eq $rangeB){Write-Host "You must enter a value"}
    if($rangeB -lt 0 -or $rangeB -gt 255){
        Write-Host "Invalid Value"
    }else{
        $done = $true
    }
}
$done = $null

while(!$done){
    $rangeE = Read-Host "Enter the End of the Range of IPs to check(0 - 255)"
    if($null -eq $rangeE){Write-Host "You must enter a value"}
    if($rangeB -lt 0 -or $rangeB -gt 255){
        Write-Host "Invalid Value"
    }else{
        $done = $true
    }
}
$done = $null

$range = $rangeB..$rangeE

$printResolved = Read-Host "Print Resolved IPs?(y/n)"
if ($printResolved -eq "y") {$printResolved = $true}else{$printResolved = $false}

$range | ForEach-Object {
    #Merge the given IP beginning with the current point in the range
    $ip = "$ipBase$_"
    #Create a progress bar
    Write-Progress -Activity "Queuing IP Address Scans" -Status "Queuing IP Address: $ip" -PercentComplete ([Math]::Truncate($_ * 100/$range.Count))
    #Queue the IP addresses to be scanned into separate threads
    Start-Job -InputObject "$ip" -ScriptBlock {
        Get-WmiObject Win32_PingStatus -Filter "Address='$input' and Timeout=200 and ResolveAddressNames='true' and StatusCode=0" | Select-Object ProtocolAddress*
    }
}

do{
    $num = 0
    Get-Job | ForEach-Object{
        if($_.State -eq 'Completed'){$num++}
    }
    Write-Progress -Activity "IP Address Scan Progress" -Status "IP Addresses Scanned: $num" -PercentComplete ([Math]::Truncate($num * 100/$range.Count))
    Start-Sleep -s 1
}until($num -eq $range.Count)

Write-Host "Found Addresses:"
if ($printResolved) {
    Get-Job | Receive-Job | Select-Object ProtocolAddress*
}else{
    $temp = Get-Job | Receive-Job | Select-Object ProtocolAddress | Out-String
    $temp = $temp -replace "ProtocolAddress" -replace "-"
    $temp.Substring(6,$temp.Length-17)
}

Get-Job | Remove-Job