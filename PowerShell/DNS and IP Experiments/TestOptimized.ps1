$DNSServer="resolver1.opendns.com"

$client = [System.Net.Sockets.UdpClient]::new("resolver1.opendns.com", 53)

$Enc = [System.Text.Encoding]::ASCII

# Create the buffer to send
[byte[]]$sendBuffer = (
    # ID
    0x11, 0x12,
    # Flags
    0x01, 0x00,
    # Quest
    0x00, 0x01,
    # ansRR
    0x00, 0x00,
    # autRR
    0x00, 0x00,
    # addRR
    0x00, 0x00,
    # 4myip7opendns3com0
    0x04, 0x6D, 0x79, 0x69, 0x70, 0x07, 0x6F, 0x70, 0x65, 0x6E, 0x64, 0x6E, 0x73, 0x03, 0x63, 0x6F, 0x6D,
    0x00,
    # 0x00 0x01 = A
    0x00, 0x01,
    # Internet Class for Query
    0x00, 0x01
)

$client.Send($sendBuffer, $sendBuffer.Length) | Out-Null

$recieveTask = $client.ReceiveAsync()

# Get Local IP
$localIP = $client.Client.LocalEndPoint.Address.IPAddressToString

# Wait for the server to respond
if (-not $recieveTask.Wait(100)) {
    throw "The server did not respond in time"
    return
}

$buffer = $recieveTask.Result.Buffer

$client.Close()

# Assume the last 4 bytes are the IP address
# Assumption only works if there is only one answer and the answer is not a string
$IP = $buffer[-4..-1]


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

# Read the flags
# Byte 1
# x... ....: 0 = Query, 1 = Response
# .xxx x...: 0 = Standard Query
# .... .x..: 0 = Server is not an authority for domain, 1 = Server is an authority for domain
# .... ..x.: 0 = Full reply, 1 = Reply is truncated
# .... ...x: 0 = Recursion not desired, 1 = Recursion desired
# Byte 2
# x... ....: 0 = Recursion not available, 1 = Recursion available
# .x.. ....: Reserved for future use
# ..x. ....: 0 = Answer not authenticated, 1 = Answer authenticated
# ...x ....: 0 = Non-Authenticated data, 1 = Authenticated data
# .... x...: 0 = No error, 1 = Format error
# .... .x..: 0 = No error, 1 = Server failure
# .... ..x.: 0 = No error, 1 = Name Error
# .... ...x: 0 = No error, 1 = Not Implemented
#$Flags = $buffer[3]
#$RA = $Flags -shr 7
#$Z = ($Flags -band 0b01110000) -shr 6
#$RCODE = $Flags -band 0b00001111

# Read the answer count
$ANCOUNT = ($buffer[6] * 256) + $buffer[7]

# Verify that there is at least one answer
if ($ANCOUNT -eq 0) {
    throw "No Answers were returned by the server"
    return
}


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

# QNAME: The domain name that was queried
# Byte 1: Length of first label
# Byte 2..n: First label
# Byte n: Length of next label
# Ends if length is 0
$labelLen = $buffer[12]
$pos = 13
while($labelLen -ne 0)
{
    $pos += $labelLen
    $labelLen = $buffer[$pos]
    $pos++
}

# QTYPE and QCLASS
$pos += 4


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

$IPs = for ($i = 0; $i -lt $ANCOUNT; $i++) {
    if ($firstTwoBits -eq 3) {
        # Skip Name, Type, Class, and TTL
        $pos += 9

        # RDLENGTH: Length of RDATA
        $RDLENGTH = ($buffer[$pos] * 256) + $buffer[$pos + 1]
        $pos += 2

        # RDATA: The data returned by the query
        $RDATA = for ($j = 0; $j -lt $RDLENGTH; $j++) {
            ($buffer[$pos] -band 0xFF) # 0b11111111
            $pos++
        }

        # Convert RDATA to an IP address
        if ($RDATA.length -gt 4) {
            # RDATA is a string
            $ipFinal = $Enc.GetString($RDATA, 0, $RDATA.length)
        } else {
            # RDATA is an IP address
            $ipFinal = $RDATA -join "."
        }

        # Return the IP address
        $ipFinal
    }

    $firstTwoBits = $buffer[$pos] -shr 6
    $pos++
}

$localIP, $IPs