#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Configures common Windows machine settings.
.DESCRIPTION
    - Turns off Widgets on the taskbar
    - Shows file extensions in Explorer
    - Disables recommendations in the Start menu
    - Disables tips in the Start menu
    - Sets taskbar alignment to left
    - Installs Git via winget
    - Enables WSL (Windows Subsystem for Linux)
#>

Write-Host "Applying Windows settings..." -ForegroundColor Cyan

# Turn off Widgets on the taskbar
Write-Host "  Disabling Widgets on taskbar..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Type DWord

# Show file extensions in Explorer
Write-Host "  Enabling file extensions in Explorer..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord

# Disable recommendations in Start menu
Write-Host "  Disabling recommendations in Start menu..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_IrisRecommendations" -Value 0 -Type DWord

# Disable tips in Start menu (Start menu tips and app suggestions)
Write-Host "  Disabling tips in Start menu..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Value 0 -Type DWord
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SoftLandingEnabled" -Value 0 -Type DWord

# Set taskbar alignment to left (0 = Left, 1 = Center)
Write-Host "  Setting taskbar alignment to left..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0 -Type DWord

# Install Git via winget
Write-Host "  Installing Git..." -ForegroundColor Cyan
$gitInstalled = winget list --id Git.Git --accept-source-agreements 2>&1 | Select-String "Git.Git"
if ($gitInstalled) {
    Write-Host "    Git is already installed." -ForegroundColor Green
} else {
    winget install --id Git.Git --exact --accept-package-agreements --accept-source-agreements
    Write-Host "    Git installed." -ForegroundColor Green
}

winget install OpenJS.NodeJS  --exact --accept-package-agreements --accept-source-agreements
winget install Microsoft.VisualStudioCode --exact --accept-package-agreements --accept-source-agreements
winget install GitHub.Copilot --exact --accept-package-agreements --accept-source-agreements
winget install Microsoft.PowerToys --exact --accept-package-agreements --accept-source-agreements
winget install Microsoft.Office --exact --accept-package-agreements --accept-source-agreements
winget install Adobe.CreativeCloud --exact --accept-package-agreements --accept-source-agreements
winget install OpenWhisperSystems.Signal --exact --accept-package-agreements --accept-source-agreements


# Enable WSL
Write-Host "  Enabling Windows Subsystem for Linux..." -ForegroundColor Cyan
$wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
if ($wslFeature.State -ne "Enabled") {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
    $restartRequired = $true
    Write-Host "    WSL enabled. A restart will be required." -ForegroundColor Yellow
} else {
    Write-Host "    WSL is already enabled." -ForegroundColor Green
}

winget install Ubuntu.Ubuntu --exact --accept-package-agreements --accept-source-agreements
winget install Docker.DockerDesktop --exact --accept-package-agreements --accept-source-agreements


# Restart Explorer to apply changes
Write-Host "Restarting Explorer to apply changes..." -ForegroundColor Yellow
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process explorer

Write-Host "All settings applied successfully." -ForegroundColor Green

if ($restartRequired) {
    Write-Host "A system restart is required to finish enabling WSL." -ForegroundColor Yellow
    $response = Read-Host "Restart now? (y/N)"
    if ($response -eq 'y') {
        Restart-Computer -Force
    }
}

