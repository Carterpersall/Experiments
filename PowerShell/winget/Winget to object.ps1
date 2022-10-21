# Based on script at https://gist.github.com/alkampfergit/19f89c1a93cc1e7b9ec9bf501f2b9134

### Parameters ###

[CmdletBinding()]
param (
    [Parameter(ParameterSetName = "List Command")]
    [Switch]$List,
    [Parameter(ParameterSetName = "List Command")]
    [String]$Filter,

    [Parameter(ParameterSetName = "Upgrade Command")]
    [Switch]$Upgrade,
    [Parameter(ParameterSetName = "Upgrade Command")]
    [Switch]$ShowUnknown,

    [Parameter(ParameterSetName = "Search Command")]
    [String]$Search,

    [Parameter(ParameterSetName = "Show Command")]
    [String]$Show
)

# Winget uses UTF8 encoding, so the console default has to be set to it for artifacting not to occur in the output
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Run specified Winget command and cast to an array of strings
$Lines = if ($List) {
    if ($Sort) {
        (winget list --query $Sort)
    } else {
        (winget list)
    }
}elseif ($Upgrade) {
    if ($ShowUnknown) {
        (winget upgrade --include-unknown)
    }else {
        (winget upgrade)
    }
}elseif ($Search) {
    (winget search $Search)
}elseif ($Show) {
    (winget show $Show)
}

# TODO: Fix problems when index refreshes
if ($Show) {
    # If the first line with content starts with Multiple, then multiple packages were found matching the query and a search was returned
    if ($Lines[1].StartsWith("Multiple")) {
        Write-Information "Multiple packages found matching '$Show'."
        
        # Remove the first two lines, which is the empty line and the "Multiple packages found" message
        $Lines = $Lines[1..$Lines.Length]

        # Set $Show to Null so the next if-statement parses the search results
        $Show = $null
    }else {
        # Create PSObject to hold the data
        [PSObject]$Output = @{}

        # Store the package name
        $Output.Add("Name", $Lines[1].SubString(5, ($Lines[1].IndexOf("[")) - 5).Trim())

        # Store the package ID
        $Output.Add("ID", $Lines[1].SubString($Lines[1].IndexOf("[") + 1, ($Lines[1].IndexOf("]")) - ($Lines[1].IndexOf("[") + 1)).Trim())

        # Cut the first two lines off the array because the first is empty and the second has been processed
        $Lines = $Lines[2..$Lines.Length]

        # Iterate through the remaining lines
        foreach ($Line in $Lines) {
            # If the line has a colon and is not indented, it is a new property
            if ($Line.contains(":") -and !$Line.StartsWith(" ")) {
                # Split the line into two parts, the property name and the property value
                $Segments = @($Line.SubString(0, $Line.IndexOf(":")).Trim(), $Line.SubString($Line.IndexOf(":") + 1))

                # Add the property name and value to the PSObject
                $Output.Add($Segments[0], $Segments[1].Trim())
            }else {
                # If the line is indented, it is one of multiple values for the previously stored property

                # If the line has a colon, it is a property of the previously stored property
                if ($Line.Contains(":")) {
                    # If $Output[$Segments[0]] is not a PSObject, create one
                    if (!$Output[$Segments[0]]) {$Output[$Segments[0]] = @{}}

                    # Split the line into two parts, the property name and the property value
                    $Output[$Segments[0]].Add($Line.SubString(0, $Line.IndexOf(":")).Trim(), $Line.SubString($Line.IndexOf(":") + 1).Trim())
                }else {
                    # If the line does not have a colon, it is a value for the previously stored property
                    $Output[$Segments[0]] += "`n$($Line.Trim())"
                }
            }
        }
    }
}

if (!$Show) {
    # Create arraylist to hold the objects
    [System.Collections.ArrayList]$Output = @()

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

    # Iterate through the valid lines
    foreach ($line in $lines) {
        if ($line.Length -gt ($availableStart + 1) -and -not $line.StartsWith('-')) {
            $software = [Software]::new()
            $software.Name             = $line.Substring(0, $idStart).Trim()
            $software.Id               = $line.Substring($idStart,        $versionStart   - $idStart       ).Trim()
            $software.Version          = $line.Substring($versionStart,   $availableStart - $versionStart  ).Trim()
            $software.AvailableVersion = $line.Substring($availableStart, $sourceStart    - $availableStart).Trim()

            [void]($Output.Add($software))
        }
    }
}

    # Return the arraylist
    $Output