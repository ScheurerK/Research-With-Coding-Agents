[CmdletBinding()]
param(
    [string]$InstallDir = "$env:LOCALAPPDATA\Programs\Markplane",
    [switch]$NoPathUpdate,
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message"
}

function Get-ScriptDirectory {
    if ($PSScriptRoot) {
        return $PSScriptRoot
    }

    return (Get-Location).Path
}

function Add-PathEntry {
    param([string]$Directory)

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $parts = @($userPath -split ";" | Where-Object { $_ })

    $alreadyPresent = $false
    foreach ($part in $parts) {
        if ($part.TrimEnd("\") -ieq $Directory.TrimEnd("\")) {
            $alreadyPresent = $true
            break
        }
    }

    if (-not $alreadyPresent) {
        [Environment]::SetEnvironmentVariable("Path", (($parts + $Directory) -join ";"), "User")
        Write-Step "Added install directory to the user PATH"
    } else {
        Write-Step "User PATH already contains install directory"
    }

    if (($env:Path -split ";" | Where-Object { $_.TrimEnd("\") -ieq $Directory.TrimEnd("\") }).Count -eq 0) {
        $env:Path = "$Directory;$env:Path"
    }
}

function Remove-PathEntry {
    param([string]$Directory)

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $parts = @($userPath -split ";" | Where-Object { $_ })
    $filtered = @()

    foreach ($part in $parts) {
        if ($part.TrimEnd("\") -ine $Directory.TrimEnd("\")) {
            $filtered += $part
        }
    }

    if ($filtered.Count -ne $parts.Count) {
        [Environment]::SetEnvironmentVariable("Path", ($filtered -join ";"), "User")
        Write-Step "Removed install directory from the user PATH"
    } else {
        Write-Step "User PATH did not contain install directory"
    }
}

if ($Uninstall) {
    Write-Step "Removing Markplane agent-neutral installation"

    if (-not $NoPathUpdate) {
        Remove-PathEntry -Directory $InstallDir
    }

    Write-Host ""
    Write-Host "Markplane PATH integration removed."
    Write-Host "Agent MCP configuration files are not removed automatically."
    exit 0
}

$scriptDir = Get-ScriptDirectory
$sourceExe = Join-Path $scriptDir "markplane.exe"

if (-not (Test-Path -LiteralPath $sourceExe -PathType Leaf)) {
    throw "markplane.exe was not found next to this script: $sourceExe"
}

Write-Step "Installing Markplane from $sourceExe"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

$targetExe = Join-Path $InstallDir "markplane.exe"
$sourceResolved = (Resolve-Path -LiteralPath $sourceExe).Path
$targetResolved = $null
if (Test-Path -LiteralPath $targetExe -PathType Leaf) {
    $targetResolved = (Resolve-Path -LiteralPath $targetExe).Path
}

if ($targetResolved -and ($sourceResolved -ieq $targetResolved)) {
    Write-Step "markplane.exe is already in $InstallDir"
} else {
    Copy-Item -LiteralPath $sourceExe -Destination $targetExe -Force
    Write-Step "Copied markplane.exe to $targetExe"
}

if (-not $NoPathUpdate) {
    Add-PathEntry -Directory $InstallDir
}

Write-Step "Verifying Markplane"
& $targetExe --version

Write-Host ""
Write-Host "Installation complete."
Write-Host "Open a new terminal before relying on 'markplane' from PATH."
Write-Host "See the installed agent-config-templates folder for MCP configuration snippets."
