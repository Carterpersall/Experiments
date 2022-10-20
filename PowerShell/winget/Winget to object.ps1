# Based on script at https://gist.github.com/alkampfergit/19f89c1a93cc1e7b9ec9bf501f2b9134

# Winget uses UTF8 encoding, so the console default has to be set to it for artifacting not to occur in the output
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Run Winget command and cast to an array of strings
$Lines = [String[]](winget upgrade)

# Find the header line
$header = ($lines[0..5] -replace " ").IndexOf("NameIdVersionAvailableSource")

# Find Indexes of the Categories
$idStart = $lines[$header].IndexOf("Id")
$versionStart = $lines[$header].IndexOf("Version")
$availableStart = $lines[$header].IndexOf("Available")
$sourceStart = $lines[$header].IndexOf("Source")

if($lines[$lines.Length - 1] -match '(\d\d?\d?\d? package\(s\) have version numbers that cannot be determined\. Use "--include-unknown" to see all results\.)'){
    # Remove the header line and the last line
    $lines = $lines[($header + 1)..($lines.Length - 2)]
}else{
    # Remove the header line
    $lines = $lines[($header + 1)..($lines.Length - 1)]
}

# Create object to be populated and inserted into the array
class Software {
    [String]$Name
    [String]$Id
    [String]$Version
    [String]$AvailableVersion
}

# Create arraylist to hold the objects
[System.Collections.ArrayList]$Output = @()

# Iterate through the valid lines
foreach ($line in $lines) {
    if ($line.Length -gt ($availableStart + 1) -and -not $line.StartsWith('-')) {
        $software = [Software]::new()
        $software.Name             = $line.Substring(0, $idStart).Trim()
        $software.Id               = $line.Substring($idStart, $versionStart - $idStart).Trim()
        $software.Version          = $line.Substring($versionStart, $availableStart - $versionStart).Trim()
        $software.AvailableVersion = $line.Substring($availableStart, $sourceStart - $availableStart).Trim()

        [void]($Output.Add($software))
    }
}

# Return the arraylist
$Output