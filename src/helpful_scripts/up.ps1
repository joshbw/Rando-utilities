<#
.SYNOPSIS
    Navigate up one or more directory levels.
.DESCRIPTION
    Moves the current location up the specified number of parent directories.
    If no argument is given, moves up one level.
.PARAMETER Levels
    The number of directory levels to move up. Defaults to 1.
.EXAMPLE
    up        # go up one directory
    up 3      # go up three directories
#>
param(
    [int]$Levels = 1
)

if ($Levels -le 0) { return }

$path = Get-Location
for ($i = 0; $i -lt $Levels; $i++) {
    $path = Split-Path $path -Parent
    if (-not $path) { break }
}

Set-Location $path
