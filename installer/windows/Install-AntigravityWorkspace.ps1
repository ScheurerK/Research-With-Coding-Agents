[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$MarkplaneExe = "$env:LOCALAPPDATA\Programs\Markplane\markplane.exe",
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message"
}

function Read-JsonObject {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return [pscustomobject]@{} }
    $text = [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($false))
    if ([string]::IsNullOrWhiteSpace($text)) { return [pscustomobject]@{} }
    return ($text | ConvertFrom-Json)
}

function Write-JsonObject {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Value
    )
    $directory = Split-Path -Parent $Path
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    $temp = Join-Path $directory ([System.IO.Path]::GetRandomFileName())
    [System.IO.File]::WriteAllText($temp, (($Value | ConvertTo-Json -Depth 100) + "`n"), [System.Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temp -Destination $Path -Force
}

function Ensure-Property {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        $Value = $null
    )
    if ($null -eq $Object.PSObject.Properties[$Name]) {
        Add-Member -InputObject $Object -NotePropertyName $Name -NotePropertyValue $Value -Force
    }
    return $Object.PSObject.Properties[$Name].Value
}

function Backup-Once {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }
    $backup = "$Path.markplane.bak"
    if (-not (Test-Path -LiteralPath $backup)) {
        Copy-Item -LiteralPath $Path -Destination $backup
    }
}

$resolvedProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
$markplaneDir = Join-Path $resolvedProjectRoot ".markplane"
if (-not (Test-Path -LiteralPath $markplaneDir -PathType Container)) {
    throw "Project is not initialized for Markplane: $resolvedProjectRoot does not contain .markplane"
}

$agentsDir = Join-Path $resolvedProjectRoot ".agents"
$mcpPath = Join-Path $agentsDir "mcp_config.json"

Backup-Once -Path $mcpPath
$settings = Read-JsonObject -Path $mcpPath
$servers = Ensure-Property -Object $settings -Name "mcpServers" -Value ([pscustomobject]@{})

if ($servers.PSObject.Properties["markplane"]) {
    $servers.PSObject.Properties.Remove("markplane")
}

if (-not $Uninstall) {
    $resolvedMarkplaneExe = (Resolve-Path -LiteralPath $MarkplaneExe -ErrorAction Stop).Path
    Add-Member -InputObject $servers -NotePropertyName "markplane" -NotePropertyValue ([pscustomobject]@{
        command = $resolvedMarkplaneExe
        args = @("mcp", "--project", $resolvedProjectRoot)
        cwd = $resolvedProjectRoot
    }) -Force
    Write-JsonObject -Path $mcpPath -Value $settings
    Write-Step "Configured workspace Antigravity Markplane MCP in $mcpPath"
} else {
    Write-JsonObject -Path $mcpPath -Value $settings
    Write-Step "Removed workspace Antigravity Markplane MCP from $mcpPath"
}

$global:LASTEXITCODE = 0
