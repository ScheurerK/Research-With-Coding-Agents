[CmdletBinding()]
param(
    [string]$SkillSourceRoot,
    [string]$AgentsHintPath,
    [switch]$SkipCodex,
    [switch]$SkipClaude,
    [switch]$SkipAgentHints,
    [switch]$SkipTelemetry,
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

function Resolve-SkillSourceRoot {
    param([string]$ExplicitRoot)

    if ($ExplicitRoot) {
        return (Resolve-Path -LiteralPath $ExplicitRoot -ErrorAction Stop).Path
    }

    $candidate = Join-Path (Get-ScriptDirectory) "skills"
    if (Test-Path -LiteralPath $candidate -PathType Container) {
        return $candidate
    }

    throw "Skill source folder not found. Pass -SkillSourceRoot <path> or place skills next to this script."
}

function Resolve-AgentsHintFile {
    param([string]$ExplicitPath)

    if ($ExplicitPath) {
        return (Resolve-Path -LiteralPath $ExplicitPath -ErrorAction Stop).Path
    }

    $candidate = Join-Path (Get-ScriptDirectory) "research-checkpoint-agents-extension.txt"
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
        return $candidate
    }

    throw "Agent hint file not found. Pass -AgentsHintPath <path> or place research-checkpoint-agents-extension.txt next to this script."
}

function Get-BundledSkillNames {
    param([string]$SourceRoot)

    if (-not (Test-Path -LiteralPath $SourceRoot -PathType Container)) {
        return @()
    }

    return @(Get-ChildItem -LiteralPath $SourceRoot -Directory | Where-Object {
        Test-Path -LiteralPath (Join-Path $_.FullName "SKILL.md") -PathType Leaf
    } | Select-Object -ExpandProperty Name | Sort-Object)
}

function Assert-UnderDirectory {
    param(
        [string]$Parent,
        [string]$Child
    )

    $parentFull = [System.IO.Path]::GetFullPath($Parent).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $childFull = [System.IO.Path]::GetFullPath($Child).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    if (-not $childFull.StartsWith($parentFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to operate outside expected directory. Parent: $parentFull Child: $childFull"
    }
}

function Install-SkillDirectory {
    param(
        [string]$SourceRoot,
        [string]$DestinationRoot,
        [string]$SkillName
    )

    $source = Join-Path $SourceRoot $SkillName
    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
        throw "Skill source not found: $source"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $source "SKILL.md") -PathType Leaf)) {
        throw "Skill source does not contain SKILL.md: $source"
    }

    New-Item -ItemType Directory -Force -Path $DestinationRoot | Out-Null
    $destination = Join-Path $DestinationRoot $SkillName
    Assert-UnderDirectory -Parent $DestinationRoot -Child $destination

    if (Test-Path -LiteralPath $destination) {
        Remove-Item -LiteralPath $destination -Recurse -Force
    }

    Copy-Item -LiteralPath $source -Destination $destination -Recurse -Force
    Write-Step "Installed $SkillName skill to $destination"
}

function Remove-SkillDirectory {
    param(
        [string]$DestinationRoot,
        [string]$SkillName
    )

    $destination = Join-Path $DestinationRoot $SkillName
    Assert-UnderDirectory -Parent $DestinationRoot -Child $destination

    if (Test-Path -LiteralPath $destination) {
        Remove-Item -LiteralPath $destination -Recurse -Force
        Write-Step "Removed $SkillName skill from $destination"
    } else {
        Write-Step "$SkillName skill was not installed in $DestinationRoot"
    }
}

function Update-ManagedBlock {
    param(
        [string]$TargetPath,
        [string]$ContentPath,
        [string]$StartMarker,
        [string]$EndMarker,
        [string]$Description
    )

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $TargetPath) | Out-Null
    $content = (Get-Content -Raw -LiteralPath $ContentPath).Trim()
    if (-not $content) {
        throw "Managed content file is empty: $ContentPath"
    }

    $managedBlock = @"
$StartMarker
$content
$EndMarker
"@

    $existing = ""
    if (Test-Path -LiteralPath $TargetPath -PathType Leaf) {
        $existing = Get-Content -Raw -LiteralPath $TargetPath
    }

    $pattern = "(?ms)$([regex]::Escape($StartMarker)).*?$([regex]::Escape($EndMarker))"
    if ([regex]::IsMatch($existing, $pattern)) {
        $updated = [regex]::Replace($existing, $pattern, $managedBlock.TrimEnd())
    } else {
        $separator = ""
        if ($existing.Trim().Length -gt 0) {
            $separator = [Environment]::NewLine + [Environment]::NewLine
        }
        $updated = $existing.TrimEnd() + $separator + $managedBlock.TrimEnd() + [Environment]::NewLine
    }

    Set-Content -LiteralPath $TargetPath -Value $updated -Encoding UTF8
    Write-Step "Installed $Description instructions in $TargetPath"
}

function Remove-ManagedBlock {
    param(
        [string]$TargetPath,
        [string]$StartMarker,
        [string]$EndMarker,
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
        Write-Step "$Description instructions not found; skipping cleanup"
        return
    }

    $existing = Get-Content -Raw -LiteralPath $TargetPath
    $pattern = "(?ms)$([regex]::Escape($StartMarker)).*?$([regex]::Escape($EndMarker))"
    $updated = [regex]::Replace($existing, $pattern, "").TrimEnd() + [Environment]::NewLine
    Set-Content -LiteralPath $TargetPath -Value $updated -Encoding UTF8
    Write-Step "Removed $Description instructions from $TargetPath"
}
function Set-SuperpowersTelemetryDisabled {
    $envPath = "HKCU:\Environment"
    New-Item -Path $envPath -Force | Out-Null
    New-ItemProperty -Path $envPath -Name "SUPERPOWERS_DISABLE_TELEMETRY" -Value "1" -PropertyType String -Force | Out-Null
    $env:SUPERPOWERS_DISABLE_TELEMETRY = "1"
    Write-Step "Disabled Superpowers optional telemetry for the current user"
}

$fallbackSkillNames = @(
    "brainstorming",
    "dispatching-parallel-agents",
    "executing-plans",
    "finishing-a-development-branch",
    "receiving-code-review",
    "requesting-code-review",
    "research-repo-governance",
    "research-checkpoint-commits",
    "subagent-driven-development",
    "systematic-debugging",
    "test-driven-development",
    "using-git-worktrees",
    "using-superpowers",
    "verification-before-completion",
    "writing-plans",
    "writing-skills"
)

$codexSkillsRoot = Join-Path (Join-Path $env:USERPROFILE ".codex") "skills"
$claudeSkillsRoot = Join-Path (Join-Path $env:USERPROFILE ".claude") "skills"
$codexAgentsPath = Join-Path (Join-Path $env:USERPROFILE ".codex") "AGENTS.md"
$claudeAgentsPath = Join-Path (Join-Path $env:USERPROFILE ".claude") "CLAUDE.md"
$codexStart = "<!-- BEGIN MARKPLANE RESEARCH CHECKPOINT SKILL -->"
$codexEnd = "<!-- END MARKPLANE RESEARCH CHECKPOINT SKILL -->"
$claudeStart = "<!-- BEGIN MARKPLANE RESEARCH CHECKPOINT SKILL -->"
$claudeEnd = "<!-- END MARKPLANE RESEARCH CHECKPOINT SKILL -->"

if ($Uninstall) {
    Write-Step "Removing Markplane bundled agent skills"
    $sourceRootForRemoval = $null
    try {
        $sourceRootForRemoval = Resolve-SkillSourceRoot -ExplicitRoot $SkillSourceRoot
    } catch {
        $sourceRootForRemoval = $null
    }

    $skillNames = if ($sourceRootForRemoval) { Get-BundledSkillNames -SourceRoot $sourceRootForRemoval } else { @() }
    if ($skillNames.Count -eq 0) {
        $skillNames = $fallbackSkillNames
    }

    foreach ($skillName in $skillNames) {
        if (-not $SkipCodex) {
            Remove-SkillDirectory -DestinationRoot $codexSkillsRoot -SkillName $skillName
        }

        if (-not $SkipClaude) {
            Remove-SkillDirectory -DestinationRoot $claudeSkillsRoot -SkillName $skillName
        }
    }

    if (-not $SkipAgentHints) {
        if (-not $SkipCodex) {
            Remove-ManagedBlock -TargetPath $codexAgentsPath -StartMarker $codexStart -EndMarker $codexEnd -Description "Codex bundled agent skill"
        }
        if (-not $SkipClaude) {
            Remove-ManagedBlock -TargetPath $claudeAgentsPath -StartMarker $claudeStart -EndMarker $claudeEnd -Description "Claude Code bundled agent skill"
        }
    }

    Write-Host ""
    Write-Host "Bundled agent skill integration removed."
    exit 0
}

$sourceRoot = Resolve-SkillSourceRoot -ExplicitRoot $SkillSourceRoot
if (-not $SkipTelemetry) {
    Set-SuperpowersTelemetryDisabled
}
$skillNames = Get-BundledSkillNames -SourceRoot $sourceRoot
if ($skillNames.Count -eq 0) {
    throw "No bundled skills with SKILL.md found in $sourceRoot"
}

foreach ($skillName in $skillNames) {
    if (-not $SkipCodex) {
        Install-SkillDirectory -SourceRoot $sourceRoot -DestinationRoot $codexSkillsRoot -SkillName $skillName
    }

    if (-not $SkipClaude) {
        Install-SkillDirectory -SourceRoot $sourceRoot -DestinationRoot $claudeSkillsRoot -SkillName $skillName
    }
}

if (-not $SkipAgentHints) {
    $hintFile = Resolve-AgentsHintFile -ExplicitPath $AgentsHintPath
    if (-not $SkipCodex) {
        Update-ManagedBlock -TargetPath $codexAgentsPath -ContentPath $hintFile -StartMarker $codexStart -EndMarker $codexEnd -Description "Codex bundled agent skill"
    }
    if (-not $SkipClaude) {
        Update-ManagedBlock -TargetPath $claudeAgentsPath -ContentPath $hintFile -StartMarker $claudeStart -EndMarker $claudeEnd -Description "Claude Code bundled agent skill"
    }
}

Write-Host ""
Write-Host "Bundled agent skill integration installed. Restart Codex and Claude Code sessions to load the skills."
Write-Host "Run Test-MarkplaneAgentSkills.ps1 to verify router bootstrap and local skill installation."
$global:LASTEXITCODE = 0
