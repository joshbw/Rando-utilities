<#
.SYNOPSIS
    Create a directory and immediately change into it.
.PARAMETER Path
    The directory to create and navigate to.
.EXAMPLE
    mdcd mynewfolder
#>
param(
    [Parameter(Mandatory)]
    [string]$Path
)

New-Item -ItemType Directory -Path $Path -Force | Out-Null
Set-Location $Path
