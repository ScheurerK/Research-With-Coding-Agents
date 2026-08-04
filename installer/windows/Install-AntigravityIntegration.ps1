[CmdletBinding()]
param(
    [string]$InstallDir = "$env:LOCALAPPDATA\Programs\ResearchWithCodingAgents",
    [string]$SkillSourceRoot,
    [string]$AgentsHintPath,
    [int]$MaxContextChars = 6000,
    [switch]$SkipTelemetry,
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message"
}

function Get-ScriptDirectory {
    if ($PSScriptRoot) { return $PSScriptRoot }
    return (Get-Location).Path
}

function Resolve-SkillSourceRoot {
    param([string]$ExplicitRoot)
    if ($ExplicitRoot) { return (Resolve-Path -LiteralPath $ExplicitRoot -ErrorAction Stop).Path }
    $candidate = Join-Path (Get-ScriptDirectory) "skills"
    if (Test-Path -LiteralPath $candidate -PathType Container) { return $candidate }
    throw "Skill source folder not found."
}

function Resolve-AgentsHintFile {
    param([string]$ExplicitPath)
    if ($ExplicitPath) { return (Resolve-Path -LiteralPath $ExplicitPath -ErrorAction Stop).Path }
    $candidate = Join-Path (Get-ScriptDirectory) "research-checkpoint-agents-extension.txt"
    if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    throw "Agent hint file not found."
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

function Get-ValidatedBundledSkills {
    param([Parameter(Mandatory = $true)][string]$SourceRoot)

    $skills = @(Get-ChildItem -LiteralPath $SourceRoot -Directory)
    if ($skills.Count -eq 0) { throw "No bundled skills found in $SourceRoot" }
    foreach ($skill in $skills) {
        $skillFile = Join-Path $skill.FullName "SKILL.md"
        if (-not (Test-Path -LiteralPath $skillFile -PathType Leaf)) {
            throw "Bundled skill is missing SKILL.md: $skillFile"
        }
    }
    return $skills
}

function Assert-AntigravityBundlePreflight {
    param([Parameter(Mandatory = $true)][string]$SourceRoot)

    [void]@(Get-ValidatedBundledSkills -SourceRoot $SourceRoot)
    $mappingPath = Join-Path $SourceRoot "using-superpowers\references\antigravity-tools.md"
    if (-not (Test-Path -LiteralPath $mappingPath -PathType Leaf)) {
        throw "Antigravity Superpowers mapping was not found: $mappingPath"
    }
    return $mappingPath
}

function Copy-BundledSkills {
    param(
        [Parameter(Mandatory = $true)][string]$SourceRoot,
        [Parameter(Mandatory = $true)][string]$DestinationRoot
    )

    $skills = @(Get-ValidatedBundledSkills -SourceRoot $SourceRoot)
    if (Test-Path -LiteralPath $DestinationRoot) {
        Remove-Item -LiteralPath $DestinationRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $DestinationRoot | Out-Null
    foreach ($skill in $skills) {
        Copy-Item -LiteralPath $skill.FullName -Destination (Join-Path $DestinationRoot $skill.Name) -Recurse -Force
    }
}

function Update-ManagedBlock {
    param(
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [Parameter(Mandatory = $true)][string]$Block,
        [Parameter(Mandatory = $true)][string]$StartMarker,
        [Parameter(Mandatory = $true)][string]$EndMarker
    )
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $TargetPath) | Out-Null
    $existing = ""
    if (Test-Path -LiteralPath $TargetPath -PathType Leaf) {
        $existing = [System.IO.File]::ReadAllText($TargetPath, [System.Text.UTF8Encoding]::new($false))
    }
    $managed = "$StartMarker`r`n$($Block.Trim())`r`n$EndMarker"
    $pattern = "(?ms)$([regex]::Escape($StartMarker)).*?$([regex]::Escape($EndMarker))"
    if ([regex]::IsMatch($existing, $pattern)) {
        $updated = [regex]::Replace($existing, $pattern, $managed)
    } else {
        $separator = if ($existing.Trim().Length -gt 0) { "`r`n`r`n" } else { "" }
        $updated = $existing.TrimEnd() + $separator + $managed + "`r`n"
    }
    [System.IO.File]::WriteAllText($TargetPath, $updated, [System.Text.UTF8Encoding]::new($false))
}

function Remove-ManagedBlock {
    param(
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [Parameter(Mandatory = $true)][string]$StartMarker,
        [Parameter(Mandatory = $true)][string]$EndMarker
    )
    if (-not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) { return }
    $existing = [System.IO.File]::ReadAllText($TargetPath, [System.Text.UTF8Encoding]::new($false))
    $pattern = "(?ms)$([regex]::Escape($StartMarker)).*?$([regex]::Escape($EndMarker))"
    $updated = [regex]::Replace($existing, $pattern, "").TrimEnd() + "`r`n"
    [System.IO.File]::WriteAllText($TargetPath, $updated, [System.Text.UTF8Encoding]::new($false))
}

function Quote-HookArgument {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Argument)
    if ($Argument -notmatch '[\s"]') { return $Argument }
    return '"' + (($Argument -replace '(\\*)"', '$1$1\"') -replace '(\\+)$', '$1$1') + '"'
}

function New-AntigravityHookHandler {
    param(
        [Parameter(Mandatory = $true)][string]$Event,
        [Parameter(Mandatory = $true)][string]$HookScriptPath,
        [Parameter(Mandatory = $true)][string]$MarkplaneExePath,
        [int]$MaxContextChars
    )
    $arguments = @("-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", $HookScriptPath, "-Event", $Event, "-MarkplaneExe", $MarkplaneExePath, "-MaxContextChars", [string]$MaxContextChars)
    $command = "powershell.exe " + (($arguments | ForEach-Object { Quote-HookArgument -Argument $_ }) -join " ")
    return [pscustomobject]@{ type = "command"; command = $command; timeout = 15 }
}

function Update-AntigravityHooks {
    param(
        [Parameter(Mandatory = $true)][string]$HooksPath,
        [Parameter(Mandatory = $true)][string]$HookScriptPath,
        [Parameter(Mandatory = $true)][string]$MarkplaneExePath,
        [int]$MaxContextChars
    )
    Backup-Once -Path $HooksPath
    $settings = Read-JsonObject -Path $HooksPath
    if ($settings.PSObject.Properties["markplane"]) {
        $settings.PSObject.Properties.Remove("markplane")
    }
    $preInvocation = New-AntigravityHookHandler -Event "PreInvocation" -HookScriptPath $HookScriptPath -MarkplaneExePath $MarkplaneExePath -MaxContextChars $MaxContextChars
    $postToolUse = New-AntigravityHookHandler -Event "PostToolUse" -HookScriptPath $HookScriptPath -MarkplaneExePath $MarkplaneExePath -MaxContextChars $MaxContextChars
    $stop = New-AntigravityHookHandler -Event "Stop" -HookScriptPath $HookScriptPath -MarkplaneExePath $MarkplaneExePath -MaxContextChars $MaxContextChars
    Add-Member -InputObject $settings -NotePropertyName "markplane" -NotePropertyValue ([pscustomobject]@{
        PreInvocation = @($preInvocation)
        PostToolUse = @([pscustomobject]@{
            matcher = "write_to_file|replace_file_content|multi_replace_file_content|run_command|mcp_.*markplane.*"
            hooks = @($postToolUse)
        })
        Stop = @($stop)
    }) -Force
    Write-JsonObject -Path $HooksPath -Value $settings
}

function Update-AntigravityMcp {
    param(
        [Parameter(Mandatory = $true)][string]$McpPath,
        [Parameter(Mandatory = $true)][string]$MarkplaneExePath
    )
    if (-not (Test-Path -LiteralPath $McpPath -PathType Leaf)) { return }
    Backup-Once -Path $McpPath
    $settings = Read-JsonObject -Path $McpPath
    if ($settings.PSObject.Properties["mcpServers"] -and $settings.mcpServers.PSObject.Properties["markplane"]) {
        $settings.mcpServers.PSObject.Properties.Remove("markplane")
        Write-JsonObject -Path $McpPath -Value $settings
    }
}

function Remove-AntigravityMcp {
    param([Parameter(Mandatory = $true)][string]$McpPath)
    if (-not (Test-Path -LiteralPath $McpPath -PathType Leaf)) { return }
    $settings = Read-JsonObject -Path $McpPath
    if ($settings.PSObject.Properties["mcpServers"] -and $settings.mcpServers.PSObject.Properties["markplane"]) {
        $settings.mcpServers.PSObject.Properties.Remove("markplane")
        Write-JsonObject -Path $McpPath -Value $settings
    }
}

function Remove-AntigravityHookState {
    $stateRoot = Join-Path $env:LOCALAPPDATA "Markplane\antigravity-hooks\sessions"
    if (Test-Path -LiteralPath $stateRoot -PathType Container) {
        try {
            Remove-Item -LiteralPath $stateRoot -Recurse -Force -ErrorAction Stop
        } catch {
            Write-Warning "Could not remove Antigravity hook session state at ${stateRoot}: $($_.Exception.Message)"
        }
    }
}

function Set-SuperpowersTelemetryDisabled {
    $envPath = "HKCU:\Environment"
    New-Item -Path $envPath -Force | Out-Null
    New-ItemProperty -Path $envPath -Name "SUPERPOWERS_DISABLE_TELEMETRY" -Value "1" -PropertyType String -Force | Out-Null
    $env:SUPERPOWERS_DISABLE_TELEMETRY = "1"
}

$geminiRoot = Join-Path $env:USERPROFILE ".gemini"
$configRoot = Join-Path $geminiRoot "config"
$pluginRoot = Join-Path $configRoot "plugins\markplane"
$geminiPath = Join-Path $geminiRoot "GEMINI.md"
$hooksPath = Join-Path $configRoot "hooks.json"
$mcpPath = Join-Path $configRoot "mcp_config.json"
$startMarker = "<!-- BEGIN MARKPLANE ANTIGRAVITY INSTRUCTIONS -->"
$endMarker = "<!-- END MARKPLANE ANTIGRAVITY INSTRUCTIONS -->"

if ($Uninstall) {
    Remove-Item -LiteralPath $pluginRoot -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $hooksPath -PathType Leaf) {
        $hooks = Read-JsonObject -Path $hooksPath
        if ($hooks.PSObject.Properties["markplane"]) { $hooks.PSObject.Properties.Remove("markplane") }
        Write-JsonObject -Path $hooksPath -Value $hooks
    }
    Remove-AntigravityMcp -McpPath $mcpPath
    Remove-ManagedBlock -TargetPath $geminiPath -StartMarker $startMarker -EndMarker $endMarker
    Remove-AntigravityHookState
    Write-Host "Removed Markplane Antigravity integration."
    $global:LASTEXITCODE = 0
    return
}

$sourceRoot = Resolve-SkillSourceRoot -ExplicitRoot $SkillSourceRoot
$hintFile = Resolve-AgentsHintFile -ExplicitPath $AgentsHintPath
$resolvedInstallDir = (Resolve-Path -LiteralPath $InstallDir -ErrorAction Stop).Path
$markplaneExe = Join-Path $resolvedInstallDir "markplane.exe"
$hookScript = Join-Path $resolvedInstallDir "hooks\Invoke-MarkplaneAntigravityHook.ps1"
if (-not (Test-Path -LiteralPath $markplaneExe -PathType Leaf)) { throw "markplane.exe was not found: $markplaneExe" }
if (-not (Test-Path -LiteralPath $hookScript -PathType Leaf)) { throw "Antigravity hook script was not found: $hookScript" }
$antigravityMappingPath = Assert-AntigravityBundlePreflight -SourceRoot $sourceRoot

New-Item -ItemType Directory -Force -Path $pluginRoot | Out-Null
[System.IO.File]::WriteAllText((Join-Path $pluginRoot "plugin.json"), "{`n  `"name`": `"markplane`"`n}`n", [System.Text.UTF8Encoding]::new($false))
$authoritativeSuperpowersBlock = @'
## Authoritative Superpowers bundle

Research With Coding Agents bundled customized Superpowers is authoritative for Gemini/Antigravity. The Superpowers skills bundled inside the Markplane plugin are authoritative. Load `using-superpowers` and every selected Superpowers skill from that plugin. Preserve any foreign Superpowers installation and same-named external copies, but do not prefer them over the Research With Coding Agents bundle. Preserve but do not prefer same-named external copies. You must not fetch, install, or upgrade Superpowers from the internet. Keep SUPERPOWERS_DISABLE_TELEMETRY=1 for managed sessions.
'@
$hint = (Get-Content -Raw -LiteralPath $hintFile).Trim()
$routerRule = "$hint`r`n`r`n$authoritativeSuperpowersBlock"

Copy-BundledSkills -SourceRoot $sourceRoot -DestinationRoot (Join-Path $pluginRoot "skills")
New-Item -ItemType Directory -Force -Path (Join-Path $pluginRoot "rules") | Out-Null
[System.IO.File]::WriteAllText(
    (Join-Path $pluginRoot "rules\superpowers-antigravity.md"),
    [System.IO.File]::ReadAllText($antigravityMappingPath, [System.Text.UTF8Encoding]::new($false)),
    [System.Text.UTF8Encoding]::new($false)
)
[System.IO.File]::WriteAllText((Join-Path $pluginRoot "rules\markplane-router.md"), $routerRule, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $pluginRoot "rules\markplane-visuals.md"), @"
# Markplane Visuals

When the user asks for Markplane visuals, graph, board, roadmap, or project overview in Antigravity, use the local Markplane web UI. From the resolved project root, run `markplane serve`, then open the local URL with Antigravity's browser tools. Prefer the web UI for graph inspection; use `markplane graph <ID>` only for text-only terminals.

The Markplane activity-bar interface is bundled as `markplane-vscode-0.1.2.vsix`. Install it through an available official VS Code or Antigravity IDE CLI using `--install-extension <vsix> --force`, then run `Developer: Reload Window`. If an IDE CLI is unavailable or the panel is not active, use the local Markplane web UI; it is the supported portable visual path across Antigravity versions.

Do not fetch external visual assets or telemetry. The visual UI is local to the user's machine.
"@, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $pluginRoot "rules\markplane-mcp.md"), @"
# Markplane Workspace MCP

Markplane MCP is project-scoped. Do not register it as a global Antigravity MCP server without a project root. Global startup directories may not contain .markplane, which makes markplane mcp exit during initialize.

When the user asks for Markplane MCP tools in the current project, first ensure the project contains .markplane, then run:

    powershell -ExecutionPolicy Bypass -File "$resolvedInstallDir\Install-AntigravityWorkspace.ps1" -ProjectRoot "<project-root>" -MarkplaneExe "$markplaneExe"

This writes .agents\mcp_config.json with markplane mcp --project <project-root> and cwd set to the same project root. Preserve unrelated MCP servers. Use hooks and CLI-only Markplane access if the workspace-local MCP has not been installed.
"@, [System.Text.UTF8Encoding]::new($false))

$geminiBlock = @"
$hint

$authoritativeSuperpowersBlock

## Markplane MCP

Markplane MCP is workspace-local in Antigravity. Do not use a global Markplane MCP entry unless it passes a concrete project root. For a Markplane project that needs MCP tools, run Install-AntigravityWorkspace.ps1 from the installed Markplane folder so .agents\mcp_config.json contains markplane mcp --project <project-root> and cwd points to that project.

## Markplane visuals

For Markplane visuals in Antigravity/Gemini, use the local web UI: run `markplane serve` from the current Markplane project root and open the local URL with the browser tool. Prefer this for graph, board, roadmap, and project overview requests. Do not use external assets or telemetry.
"@
Update-ManagedBlock -TargetPath $geminiPath -Block $geminiBlock -StartMarker $startMarker -EndMarker $endMarker
Update-AntigravityMcp -McpPath $mcpPath -MarkplaneExePath $markplaneExe
Update-AntigravityHooks -HooksPath $hooksPath -HookScriptPath $hookScript -MarkplaneExePath $markplaneExe -MaxContextChars $MaxContextChars
if (-not $SkipTelemetry) { Set-SuperpowersTelemetryDisabled }

Write-Step "Installed Markplane Antigravity plugin in $pluginRoot"
Write-Step "Removed stale global Antigravity Markplane MCP from $mcpPath when present"
Write-Step "Configured Antigravity hooks in $hooksPath"
Write-Step "Installed Gemini global instructions in $geminiPath"
$global:LASTEXITCODE = 0


