#Requires -RunAsAdministrator

param(
    [switch]$work
)

<#
.SYNOPSIS
    Configures common Windows machine settings.
.DESCRIPTION
    - Turns off Widgets on the taskbar
    - Shows file extensions in Explorer
    - Disables recommendations in the Start menu
    - Disables tips in the Start menu
    - Sets taskbar alignment to left
    - Sets Windows theme to dark mode
    - Adds the script's directory to the user Path
    - Installs Apps via winget
    - Enables WSL (Windows Subsystem for Linux)
#>

function Install-WingetApp
{
    param(
        [string]$Id,
        [string]$Name
    )
    Write-Host "  Installing $Name..." -ForegroundColor Cyan
    $installed = winget list --id $Id --accept-source-agreements 2>&1 | Select-String $Id
    if ($installed)
    {
        Write-Host "    $Name is already installed." -ForegroundColor Green
    }
    else
    {
        winget install --id $Id --exact --accept-package-agreements --accept-source-agreements
        Write-Host "    $Name installed." -ForegroundColor Green
    }
}

Write-Host "Applying Windows settings..." -ForegroundColor Cyan

# Add the current working directory to the user Path environment variable
$scriptDir = $PSScriptRoot
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -split ";" -notcontains $scriptDir)
{
    Write-Host "  Adding $scriptDir to user Path..."
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$scriptDir", "User")
    Write-Host "    Added to Path." -ForegroundColor Green
}
else
{
    Write-Host "  $scriptDir is already in user Path." -ForegroundColor Green
}

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

# Set Windows theme to dark mode
Write-Host "  Setting Windows theme to dark mode..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWord
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWord

# Install Apps via winget
Install-WingetApp -Id "Git.Git" -Name "Git"
Install-WingetApp -Id "OpenJS.NodeJS" -Name "Node.js"
Install-WingetApp -Id "Microsoft.VisualStudioCode" -Name "Visual Studio Code"
Install-WingetApp -Id "GitHub.Copilot" -Name "GitHub Copilot"
Install-WingetApp -Id "Microsoft.PowerToys" -Name "PowerToys"
Install-WingetApp -Id "Microsoft.Office" -Name "Microsoft Office"
if ($work) 
{
    Install-WingetApp -Id "SlackTechnologies.Slack" -Name "Slack"
}
else
{
    Install-WingetApp -Id "Adobe.CreativeCloud" -Name "Adobe Creative Cloud"
    Install-WingetApp -Id "OpenWhisperSystems.Signal" -Name "Signal"
    Install-WingetApp -Id "Valve.Steam" -Name "Steam"
    Install-WingetApp -Id "Discord.Discord" -Name "Discord"
    Install-WingetApp -Id "EpicGames.EpicGamesLauncher" -Name "Epic Games Launcher"
    Install-WingetApp -Id "Blizzard.BattleNet" -Name "Battle.net"
}

if ($work) 
{
    # Enable WSL
    Write-Host "  Enabling Windows Subsystem for Linux..." -ForegroundColor Cyan
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    if ($wslFeature.State -ne "Enabled")
    {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
        $restartRequired = $true
        Write-Host "    WSL enabled. A restart will be required." -ForegroundColor Yellow
    }
    else
    {
        Write-Host "    WSL is already enabled." -ForegroundColor Green
    }

    Install-WingetApp -Id "Ubuntu.Ubuntu" -Name "Ubuntu"
    Install-WingetApp -Id "Docker.DockerDesktop" -Name "Docker Desktop"
}

# Restart Explorer to apply changes
Write-Host "Restarting Explorer to apply changes..." -ForegroundColor Yellow
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process explorer

Write-Host "All settings applied successfully." -ForegroundColor Green

if ($restartRequired)
{
    Write-Host "A system restart is required to finish enabling WSL." -ForegroundColor Yellow
    $response = Read-Host "Restart now? (y/N)"
    if ($response -eq 'y')
    {
        Restart-Computer -Force
    }
}