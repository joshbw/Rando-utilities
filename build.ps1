<#
.SYNOPSIS
    Builds all projects and assembles output into .dist/

.DESCRIPTION
    Builds all Rust projects in src/external/ for the current platform,
    then copies release binaries and helpful scripts into .dist/.

.PARAMETER Clean
    Remove .dist/ before building.

.EXAMPLE
    ./build.ps1
    ./build.ps1 -Clean
#>
param(
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'

$repoRoot = $PSScriptRoot
$distDir = Join-Path $repoRoot '.dist'

if ($Clean -and (Test-Path $distDir)) {
    Remove-Item -Recurse -Force $distDir
}

New-Item -ItemType Directory -Force -Path $distDir | Out-Null

# Determine binary extension for current platform
if ($IsWindows -or $env:OS -eq 'Windows_NT') {
    $binaryExt = '.exe'
} else {
    $binaryExt = ''
}

# Build all Rust projects in src/external/
$externalDir = Join-Path $repoRoot 'src' 'external'
Get-ChildItem -Path $externalDir -Directory | ForEach-Object {
    $cargoToml = Join-Path $_.FullName 'Cargo.toml'
    if (Test-Path $cargoToml) {
        Write-Host "Building $($_.Name)..." -ForegroundColor Cyan
        Push-Location $_.FullName
        try {
            cargo build --release
            if ($LASTEXITCODE -ne 0) { throw "cargo build failed for $($_.Name)" }

            $packageName = (Get-Content $cargoToml |
                Select-String '^name\s*=\s*"(.+)"' |
                Select-Object -First 1).Matches.Groups[1].Value
            $binary = Join-Path $_.FullName "target" "release" "$packageName$binaryExt"

            if (Test-Path $binary) {
                Copy-Item $binary -Destination $distDir
                Write-Host "  Copied $packageName$binaryExt to .dist/" -ForegroundColor Green
            } else {
                throw "Expected binary not found: $binary"
            }
        } finally {
            Pop-Location
        }
    }
}

# Copy helpful scripts
$scriptsDir = Join-Path $repoRoot 'src' 'helpful_scripts'
Copy-Item -Path (Join-Path $scriptsDir '*') -Destination $distDir
Write-Host "Copied helpful scripts to .dist/" -ForegroundColor Green

# Copy repo docs
Copy-Item -Path (Join-Path $repoRoot 'LICENSE') -Destination $distDir
Copy-Item -Path (Join-Path $repoRoot 'README.md') -Destination $distDir

Write-Host "`nBuild complete. Output in .dist/" -ForegroundColor Cyan
