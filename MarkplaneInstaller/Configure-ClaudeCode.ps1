[CmdletBinding()]
param(
    [ValidateSet("user", "local", "project")]
    [string]$Scope = "user",

    [string]$MarkplaneExe
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message"
}

function Resolve-MarkplaneExecutable {
    param([string]$ExplicitPath)

    if ($ExplicitPath) {
        return (Resolve-Path -LiteralPath $ExplicitPath -ErrorAction Stop).Path
    }

    $command = Get-Command markplane -ErrorAction SilentlyContinue
    if ($command) {
        return (Resolve-Path -LiteralPath $command.Source -ErrorAction Stop).Path
    }

    $candidate = Join-Path $PSScriptRoot "markplane.exe"
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
        return (Resolve-Path -LiteralPath $candidate).Path
    }

    throw "markplane.exe was not found. Pass -MarkplaneExe <absolute-path>."
}

function Read-TextUtf8NoBom {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($false))
}

function Write-TextUtf8NoBomAtomic {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text
    )

    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }
    $temp = Join-Path $directory ([System.IO.Path]::GetRandomFileName())
    [System.IO.File]::WriteAllText($temp, $Text, [System.Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temp -Destination $Path -Force
}

function Backup-SettingsOnce {
    param([Parameter(Mandatory = $true)][string]$SettingsPath)

    if (-not (Test-Path -LiteralPath $SettingsPath -PathType Leaf)) {
        return
    }
    $backup = "$SettingsPath.markplane.bak"
    if (-not (Test-Path -LiteralPath $backup)) {
        Copy-Item -LiteralPath $SettingsPath -Destination $backup
    }
}

function Remove-LegacyMarkplaneSettingsServer {
    param([Parameter(Mandatory = $true)][string]$SettingsPath)

    if (-not (Test-Path -LiteralPath $SettingsPath -PathType Leaf)) {
        return
    }

    $settings = Read-TextUtf8NoBom -Path $SettingsPath | ConvertFrom-Json
    if ($null -eq $settings.PSObject.Properties["mcpServers"]) {
        return
    }
    if ($null -eq $settings.mcpServers.PSObject.Properties["markplane"]) {
        return
    }

    Backup-SettingsOnce -SettingsPath $SettingsPath
    $settings.mcpServers.PSObject.Properties.Remove("markplane")
    $json = $settings | ConvertTo-Json -Depth 100
    Write-TextUtf8NoBomAtomic -Path $SettingsPath -Text ($json + "`n")
    Write-Step "Removed legacy mcpServers.markplane from $SettingsPath"
}

function Invoke-ClaudeMcpRegistration {
    param(
        [Parameter(Mandatory = $true)][string]$ClaudePath,
        [Parameter(Mandatory = $true)][string]$MarkplanePath,
        [Parameter(Mandatory = $true)][string]$Scope
    )

    $version = & $ClaudePath --version 2>&1
    Write-Step "Claude Code CLI: $($version -join ' ')"

    $existing = & $ClaudePath mcp get markplane 2>&1
    $existingCode = $LASTEXITCODE
    if ($existingCode -eq 0) {
        Write-Step "Removing existing Claude Code MCP registration for markplane"
        & $ClaudePath mcp remove markplane 2>&1 | Out-Host
        if ($LASTEXITCODE -ne 0) {
            throw "Claude Code MCP removal failed with exit code $LASTEXITCODE."
        }
    }

    Write-Step "Registering Markplane MCP with Claude Code scope '$Scope'"
    & $ClaudePath mcp add --transport stdio --scope $Scope markplane -- $MarkplanePath mcp 2>&1 | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "Claude Code MCP registration failed with exit code $LASTEXITCODE."
    }
}

$claude = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claude) {
    Write-Warning "Claude Code CLI ('claude') was not found in PATH. Skipping MCP migration; Claude settings are left unchanged."
    exit 0
}

$resolvedMarkplane = Resolve-MarkplaneExecutable -ExplicitPath $MarkplaneExe
Invoke-ClaudeMcpRegistration -ClaudePath $claude.Source -MarkplanePath $resolvedMarkplane -Scope $Scope
Remove-LegacyMarkplaneSettingsServer -SettingsPath (Join-Path $HOME ".claude\settings.json")

Write-Host "Claude Code MCP server 'markplane' registered with scope '$Scope'."
Write-Host "In Claude Code, run /mcp to verify the connection."