
[CmdletBinding()]

param(
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$ID,
    [Parameter()]
    [switch]$Exact,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$Source
)

BEGIN {
    $__PARAMETERMAP = @{
        ID = @{ OriginalName = '--id='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
        Exact = @{ OriginalName = '--exact'; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [switch]; NoGap = $False }
        Source = @{ OriginalName = '--source='; OriginalPosition = '0'; Position = '2147483647'; ParameterType = [string]; NoGap = $True }
    }

    $__outputHandlers = @{
        Default = @{
            StreamOutput = $False
            Handler = {
                param ($output)
                $language = (Get-UICulture).Name

                $languageData = $(
                    $hash = @{}

                    $(try {
                        # We have to trim the leading BOM for .NET's XML parser to correctly read Microsoft's own files - go figure
                        ([xml](((Invoke-WebRequest -Uri "https://raw.githubusercontent.com/microsoft/winget-cli/master/Localization/Resources/$language/winget.resw" -ErrorAction Stop ).Content -replace "\uFEFF", ""))).root.data
                    } catch {
                        # Fall back to English if a locale file doesn't exist
                        (
                            ('SearchName','Name'),
                            ('SearchID','Id'),
                            ('SearchVersion','Version'),
                            ('AvailableHeader','Available'),
                            ('SearchSource','Source'),
                            ('ShowVersion','Version'),
                            ('GetManifestResultVersionNotFound','No version found matching:'),
                            ('InstallerFailedWithCode','Installer failed with exit code:'),
                            ('UninstallFailedWithCode','Uninstall failed with exit code:'),
                            ('AvailableUpgrades','upgrades available.')
                        ) | ForEach-Object {[pscustomobject]@{name = $_[0]; value = $_[1]}}
                    }) | ForEach-Object {
                        # Convert the array into a hashtable
                        $hash[$_.name] = $_.value
                    }
                
                    $hash
                )
                
                $nameHeader = $output -Match "^$($languageData.SearchName)"
                
                if ($nameHeader) {
                
                    $headerLine = $output.IndexOf(($nameHeader | Select-Object -First 1))
                
                    if ($headerLine -ne -1) {
                        $idIndex = $output[$headerLine].IndexOf(($languageData.SearchID))
                        $versionIndex = $output[$headerLine].IndexOf(($languageData.SearchVersion))
                        $availableIndex = $output[$headerLine].IndexOf(($languageData.AvailableHeader))
                        $sourceIndex = $output[$headerLine].IndexOf(($languageData.SearchSource))
                    
                        # Stop gathering version data at the 'Available' column if it exists, if not continue on to the 'Source' column (if it exists)
                        $versionEndIndex = $(
                            if ($availableIndex -ne -1) {
                                $availableIndex
                            } else {
                                $sourceIndex
                            }
                        )
                        
                        # Only attempt to parse output if it contains a 'version' column
                        if ($versionIndex -ne -1) {
                            # The -replace cleans up errant characters that come from WinGet's poor treatment of truncated columnar output
                            ($output | Select-String -Pattern $languageData.AvailableUpgrades,'--include-unknown' -NotMatch) -replace '[^i\p{IsBasicLatin}]',' ' | Select-Object -Skip ($headerLine+2) | ForEach-Object {
                                Remove-Variable -Name 'package' -ErrorAction SilentlyContinue
                            
                                $package = [ordered]@{
                                    ID = $_.SubString($idIndex,$versionIndex-$idIndex).Trim()
                                }
                            
                                if ($package) {
                                    # I'm so sorry, blame WinGet
                                    # If neither the 'Available' or 'Source' column exist, gather version data to the end of the string
                                    $package.Version = $(
                                        if ($versionEndIndex -ne -1) {
                                            $_.SubString($versionIndex,$versionEndIndex-$versionIndex)
                                        } else {
                                            $_.SubString($versionIndex)
                                        }
                                    ).Trim() -replace '[^\.\d]'
                                    
                                    # Only attempt to add 'Available Version' data if the column exists
                                    if ($availableIndex -ne -1) {
                                        $package.Available = $(
                                            if ($sourceIndex -ne -1) {
                                                $_.SubString($availableIndex,$sourceIndex-$availableIndex)
                                            } else {
                                                $_.SubString($availableIndex)
                                            }
                                        ).Trim() -replace '[^\.\d]'
                                    }
                                
                                    # If the 'Source' column was included in the output, include it in our output, too
                                    if (($sourceIndex -ne -1) -And ($_.Length -ge $sourceIndex)) {
                                        $package.Source = $_.SubString($sourceIndex).Trim() -split ' ' | Select-Object -Last 1
                                    }
                                
                                    [pscustomobject]$package
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
PROCESS {
    $__commandArgs = @(
        "list"
        "--accept-source-agreements"
    )
    $__boundparms = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $PSBoundParameters[$_.Name]}).ForEach({$PSBoundParameters[$_.Name] = [switch]::new($false)})
    if ($PSBoundParameters["Debug"]){wait-debugger}
    foreach ($paramName in $PSBoundParameters.Keys|Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $PSBoundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ( $value -is [switch] ) { $__commandArgs += if ( $value.IsPresent ) { $param.OriginalName } else { $param.DefaultMissingValue } }
            elseif ( $param.NoGap ) { $__commandArgs += "{0}""{1}""" -f $param.OriginalName, $value }
            else { $__commandArgs += $param.OriginalName; $__commandArgs += $value |Foreach-Object {$_}}
        }
    }
    $__commandArgs = $__commandArgs|Where-Object {$_}
    if ($PSBoundParameters["Debug"]){wait-debugger}
    if ( $PSBoundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message WinGet
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("WinGet")) {
        if ( $__handlerInfo.StreamOutput ) {
            & "WinGet" $__commandArgs | & $__handler
        }
        else {
            $result = & "WinGet" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
Get a list of installed WinGet packages

.PARAMETER ID
Package ID


.PARAMETER Exact
Search by exact package name


.PARAMETER Source
Package Source



#>

