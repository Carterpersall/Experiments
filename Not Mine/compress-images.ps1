param([string]$path = ".\", [int]$minSize = 0, [switch]$jpg, [switch]$png, [switch]$gif, [switch]$verbose, [switch]$report)

function Get-Size
{
    param([string]$pth)
    "{0:n2}" -f ((gci -path $pth -recurse | measure-object -property length -sum).sum /1mb) + " mb"
}

function Get-Size-Kb
{
    param([string]$pth)
    "{0:n2}" -f ((gci -path $pth -recurse | measure-object -property length -sum).sum /1kb) + " kb"
}

function Compress-Images([string]$type) {
    $params = switch ($type) {
        "jpg" { "-compress jpeg -quality 82" }
        "gif" { "-fuzz 10% -layers Optimize" }
        "png" { "-depth 24 -define png:compression-filter=2 -define png:compression-level=9 -define png:compression-strategy=1" }
    }

    if ($report) {
        echo ""
        echo "Listing $type files that would be included for compression with params: $params"
    } else {
        echo ""
        echo "Compressing $type files with parameters: $params"
    }
    
    Get-ChildItem $path -Recurse -Include "*.$type" | 
        Where-Object {
            $_.Length/1kb -gt $minSize
        } | 
        Sort-Object -Descending length |
        ForEach-Object {
            $file = $_.FullName
        
            if ($report) {
                $fSize = Get-Size-Kb($file)
                echo "$file - $fSize"
            } else {
                if ($verbose) {
                    echo "Compressing $file"
                    $fileStartSize = Get-Size-Kb($file)
                }
        
                # compress image
                if ($report -eq $False) {
                    iex "magick $file $params $file"
                }

                if ($verbose) {
                    $fileEndSize = Get-Size-Kb($file)
                    echo "Reduced from $fileStartSize to $fileEndSize"
                }
            }
        }
}

# begin compression process
$startSize = Get-Size $path
echo "Compressing images greater than $minSize kb in $path"
echo "---"

# determine whether to compress specific image types or all
$compressAll = $false
if (-NOT $jpg -AND -NOT $png -AND -NOT $gif) {
    $compressAll = $true
}

# compress, or skip, each image type as directed
if ($jpg -OR $compressAll) {
    Compress-Images "jpg"
}
if ($gif -OR $compressAll) {
    Compress-Images "gif"
}
if ($png -OR $compressAll) {
    Compress-Images "png"
}

# echo completion and stats
$endSize = Get-Size $path
echo ""
echo "DONE"
echo "Starting sizes: $startSize" 
echo "Ending sizes: $endSize"