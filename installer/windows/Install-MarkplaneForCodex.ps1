[CmdletBinding()]
param(
    [string]$InstallDir = "$env:LOCALAPPDATA\Programs\ResearchWithCodingAgents",
    [string]$AgentsExtensionPath,
    [switch]$SkipCodexMcp,
    [switch]$SkipCodexHooks,
    [switch]$SkipAgents,
    [switch]$NoPathUpdate,
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message"
}

function Normalize-PathForToml {
    param([string]$Path)
    return ($Path -replace "\\", "/")
}

function Get-ScriptDirectory {
    if ($PSScriptRoot) {
        return $PSScriptRoot
    }

    return (Get-Location).Path
}

function Resolve-AgentsExtensionFile {
    param(
        [string]$ScriptDir,
        [string]$ExplicitPath
    )

    if ($ExplicitPath) {
        $resolved = Resolve-Path -LiteralPath $ExplicitPath -ErrorAction Stop
        return $resolved.Path
    }

    $preferredNames = @(
        "markplane-agents-extension.txt",
        "agents-markplane-extension.txt",
        "AGENTS.markplane.txt",
        "AGENTS.md.txt"
    )

    foreach ($name in $preferredNames) {
        $candidate = Join-Path $ScriptDir $name
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    $txtFiles = @(Get-ChildItem -LiteralPath $ScriptDir -Filter "*.txt" -File)
    if ($txtFiles.Count -eq 1) {
        return $txtFiles[0].FullName
    }

    if ($txtFiles.Count -gt 1) {
        $names = ($txtFiles | ForEach-Object { $_.Name }) -join ", "
        throw "Multiple .txt files found next to this script ($names). Re-run with -AgentsExtensionPath <file>."
    }

    throw "No AGENTS extension .txt file found next to this script. Expected e.g. markplane-agents-extension.txt, or pass -AgentsExtensionPath <file>."
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
        $newPath = (($parts + $Directory) -join ";")
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Step "Added install directory to the user PATH"
    } else {
        Write-Step "User PATH already contains install directory"
    }

    $processParts = @($env:Path -split ";" | Where-Object { $_ })
    $processHasPath = $false
    foreach ($part in $processParts) {
        if ($part.TrimEnd("\") -ieq $Directory.TrimEnd("\")) {
            $processHasPath = $true
            break
        }
    }

    if (-not $processHasPath) {
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

function Update-CodexMcpConfig {
    param([string]$MarkplaneExe)

    $codexDir = Join-Path $env:USERPROFILE ".codex"
    $configPath = Join-Path $codexDir "config.toml"
    New-Item -ItemType Directory -Force -Path $codexDir | Out-Null

    $existing = ""
    if (Test-Path -LiteralPath $configPath -PathType Leaf) {
        $existing = Get-Content -Raw -LiteralPath $configPath
    }

    $command = Normalize-PathForToml $MarkplaneExe
    $block = @"
[mcp_servers.markplane]
enabled = true
command = "$command"
args = ["mcp"]
startup_timeout_sec = 10
tool_timeout_sec = 60
"@

    $pattern = "(?ms)^\[mcp_servers\.markplane(?:\.[^\]]+)?\]\r?\n.*?(?=^\[(?!mcp_servers\.markplane(?:\.|\]))[^\r\n]+\]|\z)"
    if ([regex]::IsMatch($existing, $pattern)) {
        $updated = [regex]::Replace($existing, $pattern, ($block.TrimEnd() + [Environment]::NewLine))
    } else {
        $separator = ""
        if ($existing.Trim().Length -gt 0) {
            $separator = [Environment]::NewLine + [Environment]::NewLine
        }
        $updated = $existing.TrimEnd() + $separator + $block.TrimEnd() + [Environment]::NewLine
    }

    Set-Content -LiteralPath $configPath -Value $updated -Encoding UTF8
    Write-Step "Configured Codex MCP server in $configPath"
}

function Remove-CodexMcpConfig {
    $configPath = Join-Path (Join-Path $env:USERPROFILE ".codex") "config.toml"
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        Write-Step "Codex config.toml not found; skipping MCP cleanup"
        return
    }

    $existing = Get-Content -Raw -LiteralPath $configPath
    $pattern = "(?ms)^\[mcp_servers\.markplane(?:\.[^\]]+)?\]\r?\n.*?(?=^\[(?!mcp_servers\.markplane(?:\.|\]))[^\r\n]+\]|\z)"
    $updated = [regex]::Replace($existing, $pattern, "").TrimEnd() + [Environment]::NewLine
    Set-Content -LiteralPath $configPath -Value $updated -Encoding UTF8
    Write-Step "Removed Markplane MCP block from $configPath"
}

function Update-CodexAgentsFile {
    param([string]$ExtensionPath)

    $codexDir = Join-Path $env:USERPROFILE ".codex"
    $agentsPath = Join-Path $codexDir "AGENTS.md"
    New-Item -ItemType Directory -Force -Path $codexDir | Out-Null

    $extension = (Get-Content -Raw -LiteralPath $ExtensionPath).Trim()
    if (-not $extension) {
        throw "The AGENTS extension file is empty: $ExtensionPath"
    }

    $startMarker = "<!-- BEGIN MARKPLANE CODEX INSTRUCTIONS -->"
    $endMarker = "<!-- END MARKPLANE CODEX INSTRUCTIONS -->"
    $managedBlock = @"
$startMarker
$extension
$endMarker
"@

    $existing = ""
    if (Test-Path -LiteralPath $agentsPath -PathType Leaf) {
        $existing = Get-Content -Raw -LiteralPath $agentsPath
    }

    $pattern = "(?ms)$([regex]::Escape($startMarker)).*?$([regex]::Escape($endMarker))"
    if ([regex]::IsMatch($existing, $pattern)) {
        $updated = [regex]::Replace($existing, $pattern, $managedBlock.TrimEnd())
    } else {
        $separator = ""
        if ($existing.Trim().Length -gt 0) {
            $separator = [Environment]::NewLine + [Environment]::NewLine
        }
        $updated = $existing.TrimEnd() + $separator + $managedBlock.TrimEnd() + [Environment]::NewLine
    }

    Set-Content -LiteralPath $agentsPath -Value $updated -Encoding UTF8
    Write-Step "Installed Markplane AGENTS instructions in $agentsPath"
}

function Remove-CodexAgentsBlock {
    $agentsPath = Join-Path (Join-Path $env:USERPROFILE ".codex") "AGENTS.md"
    if (-not (Test-Path -LiteralPath $agentsPath -PathType Leaf)) {
        Write-Step "Codex AGENTS.md not found; skipping AGENTS cleanup"
        return
    }

    $startMarker = "<!-- BEGIN MARKPLANE CODEX INSTRUCTIONS -->"
    $endMarker = "<!-- END MARKPLANE CODEX INSTRUCTIONS -->"
    $existing = Get-Content -Raw -LiteralPath $agentsPath
    $pattern = "(?ms)$([regex]::Escape($startMarker)).*?$([regex]::Escape($endMarker))"
    $updated = [regex]::Replace($existing, $pattern, "").TrimEnd() + [Environment]::NewLine
    Set-Content -LiteralPath $agentsPath -Value $updated -Encoding UTF8
    Write-Step "Removed Markplane AGENTS instructions from $agentsPath"
}

$scriptDir = Get-ScriptDirectory
$sourceExe = Join-Path $scriptDir "markplane.exe"

if ($Uninstall) {
    Write-Step "Removing Markplane Codex integration"

    if (-not $NoPathUpdate) {
        Remove-PathEntry -Directory $InstallDir
    }

    if (-not $SkipCodexMcp) {
        Remove-CodexMcpConfig
    }

    if (-not $SkipCodexHooks) {
        $codexHooksInstaller = Join-Path $scriptDir "Install-CodexHooks.ps1"
        if (Test-Path -LiteralPath $codexHooksInstaller -PathType Leaf) {
            & $codexHooksInstaller -Uninstall -InstallDir $InstallDir
        } else {
            Write-Warning "Codex hook installer not found; skipping Codex hook cleanup: $codexHooksInstaller"
        }
    }

    if (-not $SkipAgents) {
        Remove-CodexAgentsBlock
    }

    Write-Host ""
    Write-Host "Markplane Codex integration removed."
    Write-Host "The installer will remove installed files next."
    exit 0
}

if (-not (Test-Path -LiteralPath $sourceExe -PathType Leaf)) {
    throw "markplane.exe was not found next to this script: $sourceExe"
}

Write-Step "Installing Markplane from $sourceExe"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

$targetExe = Join-Path $InstallDir "markplane.exe"
if ((Resolve-Path -LiteralPath $sourceExe).Path -ieq (Resolve-Path -LiteralPath $targetExe -ErrorAction SilentlyContinue).Path) {
    Write-Step "markplane.exe is already in $InstallDir"
} else {
    Copy-Item -LiteralPath $sourceExe -Destination $targetExe -Force
    Write-Step "Copied markplane.exe to $targetExe"
}

if (-not $NoPathUpdate) {
    Add-PathEntry -Directory $InstallDir
}

if (-not $SkipCodexMcp) {
    Update-CodexMcpConfig -MarkplaneExe $targetExe
}

if (-not $SkipCodexHooks) {
    $codexHooksInstaller = Join-Path $scriptDir "Install-CodexHooks.ps1"
    if (Test-Path -LiteralPath $codexHooksInstaller -PathType Leaf) {
        & $codexHooksInstaller -InstallDir $InstallDir
    } else {
        Write-Warning "Codex hook installer not found; skipping Codex hook installation: $codexHooksInstaller"
    }
}

if (-not $SkipAgents) {
    $agentsFile = Resolve-AgentsExtensionFile -ScriptDir $scriptDir -ExplicitPath $AgentsExtensionPath
    Write-Step "Using AGENTS extension file $agentsFile"
    Update-CodexAgentsFile -ExtensionPath $agentsFile
}

Write-Step "Verifying Markplane"
& $targetExe --version

Write-Host ""
Write-Host "Installation complete."
Write-Host "Open a new terminal before relying on 'markplane' from PATH."
Write-Host "Check Codex MCP in a new Codex session with /mcp. Codex may ask you to trust the Markplane hooks on first use."
