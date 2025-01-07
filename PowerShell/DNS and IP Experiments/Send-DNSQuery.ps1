<#
.SYNOPSIS
    Sends a DNS query for Variable record types
.DESCRIPTION
    Currently only sends the UDP packet for the query.
    Was created for PowerShell 2 to help with directing a query to a custom DNS server.
.NOTES
    Author:  Carter Persall
.EXAMPLE
    Send-DNSQuery "resolve1.opendns.com" "myip.opendns.com" "A"
.LINK
    https://github.com/OneLogicalMyth/PowerShell-DNSQuery
#>
function Send-DNSQuery {

    # Source: https://github.com/OneLogicalMyth/PowerShell-DNSQuery/blob/master/Send-DNSQuery.ps1
    param($DNSServer="resolver1.opendns.com",$DomainName="myip.opendns.com", $DNSQueryType="A")

    # Check if values are present else return error
    if(-not $DNSServer)
    {
        Write-Error 'No DNS server was given, can not continue!'
        return $null
    }
    if(-not $DomainName)
    {
        Write-Error 'No domain name was given, can not continue!'
        return $null
    }
    if(-not $DNSQueryType)
    {
        Write-Error 'No type given for query, can not continue!'
        return $null
    }

    # Define port and target IP address
    $Port    = 53
    $Address = [system.net.IPAddress]::Parse( [System.Net.Dns]::GetHostAddresses($DNSServer).IPAddressToString )

    # Create IP Endpoint
    $End = New-Object System.Net.IPEndPoint $Address , $port

    # Create Socket
    $Saddrf   = [System.Net.Sockets.AddressFamily]::InterNetwork
    $Stype    = [System.Net.Sockets.SocketType]::Dgram
    $Ptype    = [System.Net.Sockets.ProtocolType]::UDP
    $Sock     = New-Object System.Net.Sockets.Socket $saddrf , $stype , $ptype
    # Set TTL (Time to Live), which is the number of hops the packet can make before it is discarded and an error is returned
    $Sock.TTL = 26

    # Connect to socket
    $sock.Connect( $end )

    # Create encoder
    $Enc = [System.Text.Encoding]::ASCII

    # Byte headers
    $header_begin = @(
                    #id
                    [byte]0x11, [byte]0x12,
                    #flags
                    [byte]0x01, [byte]0x00,
                    #quest
                    [byte]0x00, [byte]0x01,
                    #ansRR
                    [byte]0x00, [byte]0x00,
                    #autRR
                    [byte]0x00, [byte]0x00,
                    #addRR
                    [byte]0x00, [byte]0x00
    )
    # 0x00 0x01 = A
    # 0x00 0x02 = NS
    # 0x00 0x05 = CNAME
    # 0x00 0x06 = SOA
    # 0x00 0x10 = TXT
    # 0x00 0x0c = PTR
    # 0x00 0x0f = MX
    # 0x00 0x1c = AAAA
    if ($DNSQueryType -eq 'A') {
        $type = [byte]0x00, [byte]0x01
    }
    if ($DNSQueryType -eq 'NS') {
        $type = [byte]0x00, [byte]0x02
    }
    if ($DNSQueryType -eq 'CNAME') {
        $type = [byte]0x00, [byte]0x05
    }
    if ($DNSQueryType -eq 'SOA') {
        $type = [byte]0x00, [byte]0x06
    }
    if ($DNSQueryType -eq 'TXT') {
        $type = [byte]0x00, [byte]0x10
    }
    if ($DNSQueryType -eq 'PTR') {
        $type = [byte]0x00, [byte]0x0c
    }
    if ($DNSQueryType -eq 'MX') {
        $type = [byte]0x00, [byte]0x0f
    }
    if ($DNSQueryType -eq 'AAAA') {
        $type = [byte]0x00, [byte]0x1c
    }
    if ($DNSQueryType -eq 'ALL') {
        $type = [byte]0x00, [byte]0xff
    }

    #Internet Class for Query
    $class  = [byte]0x00, [byte]0x01

    # We now explode on the full stops and replace them with length as a byte
    $sendBuffer = $header_begin
    Foreach($Part in $DomainName.Split('.'))
    {
        $sendBuffer = $sendBuffer + ([byte]$Part.length) + $Enc.GetBytes( $Part )
    }

    # Add the class and type to the end of the buffer
    $sendBuffer = $sendBuffer + [byte]0x00 + $type + $class

    # Send the buffer
    $bytesSent = 0
    while ($bytesSent -lt $sendBuffer.Length)
    {
        $bytesSent += $Sock.Send( $sendBuffer , $bytesSent , $sendBuffer.Length - $bytesSent , 0 )
    }

    # Receive the response
    $buffer = New-Object Byte[] 4096
    $bytes  = $Sock.Receive( $buffer )

    # Close the socket
    $Sock.Close()

    # Trim the response
    $buffer = $buffer[0..$($bytes-1)]

    # Print the buffer
    Write-Verbose "Response: "
    Write-Verbose ($buffer -join ' ')


    # Parse the response
    # Source: https://levelup.gitconnected.com/dns-response-in-java-a6298e3cc7d9

    # Process the header
    #  0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    # +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    # |                      ID                       |
    # +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    # |QR|   Opcode  |AA|TC|RD|RA|   Z    |   RCODE   |
    # +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    # |                    QDCOUNT                    |
    # +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    # |                    ANCOUNT                    |
    # +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    # |                    NSCOUNT                    |
    # +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    # |                    ARCOUNT                    |
    # +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

    # Read the packet ID
    $ID = ($buffer[0] * 256) + $buffer[1] # ToUInt16 doesn't work sometimes for whatever reason

    # Read the flags
    # Byte 1
    # x... ....: 0 = Query, 1 = Response
    # .xxx x...: 0 = Standard Query
    # .... .x..: 0 = Server is not an authority for domain, 1 = Server is an authority for domain
    # .... ..x.: 0 = Full reply, 1 = Reply is truncated
    # .... ...x: 0 = Recursion not desired, 1 = Recursion desired
    $Flags = $buffer[2]
    $QR = $Flags -shr 7 # 1 = Response, 0 = Query
    $Opcode = ($Flags -band 0b01111000) -shr 3
    $AA = ($Flags -band 0b00000100) -shr 2 # 1 = Authoritative Answer
    $TC = ($Flags -band 0b00000010) -shr 1 # 1 = Truncated
    $RD = $Flags -band 0b00000001 # 1 = Recursion Desired

    # Byte 2
    # x... ....: 0 = Recursion not available, 1 = Recursion available
    # .x.. ....: Reserved for future use
    # ..x. ....: 0 = Answer not authenticated, 1 = Answer authenticated
    # ...x ....: 0 = Non-Authenticated data, 1 = Authenticated data
    # .... x...: 0 = No error, 1 = Format error
    # .... .x..: 0 = No error, 1 = Server failure
    # .... ..x.: 0 = No error, 1 = Name Error
    # .... ...x: 0 = No error, 1 = Not Implemented
    $Flags = $buffer[3]
    $RA = $Flags -shr 7
    $Z = ($Flags -band 0b01110000) -shr 6
    $RCODE = $Flags -band 0b00001111

    # Read the counts
    $QDCOUNT = ($buffer[4] * 256) + $buffer[5]
    $ANCOUNT = ($buffer[6] * 256) + $buffer[7]
    $NSCOUNT = ($buffer[8] * 256) + $buffer[9]
    $ARCOUNT = ($buffer[10] * 256) + $buffer[11]


    # Parse the question
    #  0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    # +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    # |                                               |
    # /                     QNAME                     /
    # /                                               /
    # +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    # |                     QTYPE                     |
    # +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    # |                     QCLASS                    |
    # +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

    # QNAME
    # Byte 1: Length of first label
    # Byte 2..n: First label
    # Byte n: Length of next label
    # Ends if length is 0
    $QNAME = ""
    $labelLen = $buffer[12]
    $pos = 13
    while($labelLen -ne 0)
    {
        $QNAME += $Enc.GetString( $buffer , $pos , $labelLen ) + "."
        $pos += $labelLen
        $labelLen = $buffer[$pos]
        $pos++
    }
    $QNAME = $QNAME.Substring(0,$QNAME.Length-1) # Remove trailing dot

    # QTYPE
    $QTYPE = ($buffer[$pos] * 256) + $buffer[$pos + 1]
    $pos += 2

    # QCLASS
    $QCLASS = ($buffer[$pos] * 256) + $buffer[$pos + 1]
    $pos += 2


    # Print the header and question values
    Write-Verbose "ID: $ID"
    Write-Verbose "QR: $QR"
    Write-Verbose "Opcode: $Opcode"
    Write-Verbose "AA: $AA"
    Write-Verbose "TC: $TC"
    Write-Verbose "RD: $RD"
    Write-Verbose "RA: $RA"
    Write-Verbose "Z: $Z"
    Write-Verbose "RCODE:"
    if ($RCODE -eq 0) { Write-Verbose "  No error" }
    if ($RCODE -band 0b00001000) { Write-Verbose "  Format error" }
    if ($RCODE -band 0b00000100) { Write-Verbose "  Server failure" }
    if ($RCODE -band 0b00000010) { Write-Verbose "  Name Error" }
    Write-Verbose "QDCOUNT: $QDCOUNT"
    Write-Verbose "ANCOUNT: $ANCOUNT"
    Write-Verbose "NSCOUNT: $NSCOUNT"
    Write-Verbose "ARCOUNT: $ARCOUNT"
    Write-Verbose "QNAME: $QNAME"
    Write-Verbose "QTYPE: $QTYPE"
    Write-Verbose "QCLASS: $QCLASS"


    # Parse the answers
    #  0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    # +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    # |                                               |
    # /                                               /
    # /                      NAME                     /
    # |                                               |
    # +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    # |                      TYPE                     |
    # +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    # |                     CLASS                     |
    # +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    # |                      TTL                      |
    # |                                               |
    # +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    # |                   RDLENGTH                    |
    # +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--|
    # /                     RDATA                     /
    # /                                               /
    # +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

    # xx.. ....: 00 = Label
    $firstTwoBits = $buffer[$pos] -shr 6
    $pos++

    $label = [System.Collections.ArrayList]::new()
    $domainToIP = [System.Collections.Generic.Dictionary[string,string]]::new()

    for ($i = 0; $i -lt $ANCOUNT; $i++)
    {
        if ($firstTwoBits -eq 3) {
            [byte]$currentByte = $buffer[$pos]
            $pos++
            $stop = $false
            [byte[]]$newArray = New-Object byte[] ($buffer.Length - $currentByte)
            $buffer[$currentByte..$buffer.Length].CopyTo($newArray, 0)
            $RDATA = [System.Collections.ArrayList]::new()
            $DOMAINS = [System.Collections.ArrayList]::new()
            $newpos = 0
            while (-not $stop) {
                $currentByte = $newArray[$newpos]
                if ($currentByte -ne 0) {
                    $label += $Enc.GetString($newArray, $newpos + 1, $currentByte)
                    $newpos += $currentByte + 1
                } else {
                    $stop = $true
                    $TYPE = ($buffer[$pos] * 256) + $buffer[$pos + 1]
                    $pos += 2
                    $CLASS = ($buffer[$pos] * 256) + $buffer[$pos + 1]
                    $pos += 2
                    $TTL = [System.BitConverter]::ToUInt32($buffer, $pos + 1)
                    $pos += 4
                    $RDLENGTH = ($buffer[$pos] * 256) + $buffer[$pos + 1]
                    $pos += 2
                    for ($j = 0; $j -lt $RDLENGTH; $j++) {
                        $RDATA += ($buffer[$pos] -band 0b11111111)
                        $pos++
                    }

                    Write-Verbose "TYPE: $TYPE"
                    Write-Verbose "CLASS: $CLASS"
                    Write-Verbose "TTL: $TTL"
                    Write-Verbose "RDLENGTH: $RDLENGTH"
                }

                $DOMAINS += $label
                $label = [System.Collections.ArrayList]::new()
            }

            # Convert  RDATA to an IP address
            if ($RDATA.length -gt 4) {
                # RDATA is a string
                $ipFinal = $Enc.GetString($RDATA, 0, $RDATA.length)
            } else {
                # RDATA is an IP address
                $ipFinal = $RDATA -join "."
            }

            # Merge the domain parts
            $domainFinal = ($DOMAINS | Where-Object { $_ -ne "" }) -join "."

            # Add the domain and returned IP to the dictionary
            $domainToIP.Add($domainFinal, $ipFinal)
        } elseif ($firstTwoBits -eq 0) {
            Write-Verbose "It's a Label"
        }

        $firstTwoBits = $buffer[$pos] -shr 6
        $pos++
    }

    $domainToIP
}

Send-DNSQuery -DNSServer "ns1.google.com" -DomainName "o-o.myaddr.l.google.com" -DNSQueryType "ALL"