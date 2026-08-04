[CmdletBinding()]
param(
    [string]$InstallDir = "$env:LOCALAPPDATA\Programs\ResearchWithCodingAgents",
    [string]$HooksPath = (Join-Path $HOME ".codex\hooks.json"),
    [int]$MaxContextChars = 6000,
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

function Get-CodexHookDefaultScriptPath {
    param([Parameter(Mandatory = $true)][string]$InstallDir)
    return (Join-Path $InstallDir "hooks\Invoke-MarkplaneCodexHook.ps1")
}

function Get-CodexHookDefaultExePath {
    param([Parameter(Mandatory = $true)][string]$InstallDir)
    return (Join-Path $InstallDir "markplane.exe")
}

function Read-CodexHooksJson {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return [pscustomobject]@{}
    }

    $text = [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($false))
    if ([string]::IsNullOrWhiteSpace($text)) {
        return [pscustomobject]@{}
    }

    return ($text | ConvertFrom-Json)
}

function Write-CodexHooksJson {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Settings
    )

    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }

    $temp = Join-Path $directory ([System.IO.Path]::GetRandomFileName())
    $json = $Settings | ConvertTo-Json -Depth 100
    [System.IO.File]::WriteAllText($temp, $json + "`n", [System.Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temp -Destination $Path -Force
}

function Ensure-CodexProperty {
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

function Backup-CodexHooksOnce {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return
    }

    $backup = "$Path.markplane.bak"
    if (-not (Test-Path -LiteralPath $backup)) {
        Copy-Item -LiteralPath $Path -Destination $backup
    }
}

function Quote-CodexHookArgument {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Argument)

    if ($Argument -notmatch '[\s"]') {
        return $Argument
    }

    return '"' + (($Argument -replace '(\\*)"', '$1$1\"') -replace '(\\+)$', '$1$1') + '"'
}

function Test-CodexMarkplaneHookHandler {
    param(
        $Hook,
        [Parameter(Mandatory = $true)][string]$HookScriptPath
    )

    if ($null -eq $Hook) {
        return $false
    }

    $command = [string]$Hook.command
    if ($command -and $command.IndexOf($HookScriptPath, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        return $true
    }

    $commandWindows = [string]$Hook.commandWindows
    if ($commandWindows -and $commandWindows.IndexOf($HookScriptPath, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        return $true
    }

    foreach ($arg in @($Hook.args)) {
        if ([string]$arg -ieq $HookScriptPath) {
            return $true
        }
    }

    return $false
}

function Remove-CodexMarkplaneHandlersFromEvent {
    param(
        [Parameter(Mandatory = $true)]$EventEntries,
        [Parameter(Mandatory = $true)][string]$HookScriptPath
    )

    $remainingEntries = @()
    foreach ($entry in @($EventEntries)) {
        $remainingHooks = @()
        foreach ($hook in @($entry.hooks)) {
            if (-not (Test-CodexMarkplaneHookHandler -Hook $hook -HookScriptPath $HookScriptPath)) {
                $remainingHooks += $hook
            }
        }
        if ($remainingHooks.Count -gt 0) {
            $entry.hooks = @($remainingHooks)
            $remainingEntries += $entry
        }
    }

    return @($remainingEntries)
}

function New-CodexMarkplaneHookEntry {
    param(
        [Parameter(Mandatory = $true)][string]$Event,
        [string]$Matcher,
        [Parameter(Mandatory = $true)][string]$HookScriptPath,
        [Parameter(Mandatory = $true)][string]$MarkplaneExePath,
        [int]$MaxContextChars = 6000
    )

    $arguments = @(
        "-NoProfile",
        "-NonInteractive",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        $HookScriptPath,
        "-Event",
        $Event,
        "-MarkplaneExe",
        $MarkplaneExePath,
        "-MaxContextChars",
        [string]$MaxContextChars
    )

    $command = "powershell.exe " + (($arguments | ForEach-Object { Quote-CodexHookArgument -Argument $_ }) -join " ")
    $hook = [pscustomobject]@{
        type = "command"
        command = $command
        commandWindows = $command
        timeout = 15
        statusMessage = "Markplane $Event"
    }

    if ([string]::IsNullOrWhiteSpace($Matcher)) {
        return [pscustomobject]@{ hooks = @($hook) }
    }

    return [pscustomobject]@{
        matcher = $Matcher
        hooks = @($hook)
    }
}

function Remove-CodexMarkplaneHooks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$HooksPath,
        [Parameter(Mandatory = $true)][string]$HookScriptPath
    )

    $settings = Read-CodexHooksJson -Path $HooksPath
    $hooksProperty = $settings.PSObject.Properties["hooks"]
    if ($null -eq $hooksProperty) {
        return
    }

    foreach ($event in @("SessionStart", "PostToolUse", "SubagentStart", "Stop", "SubagentStop")) {
        $property = $settings.hooks.PSObject.Properties[$event]
        if ($null -eq $property) {
            continue
        }
        $remaining = Remove-CodexMarkplaneHandlersFromEvent -EventEntries $property.Value -HookScriptPath $HookScriptPath
        if ($remaining.Count -eq 0) {
            $settings.hooks.PSObject.Properties.Remove($event)
        } else {
            $settings.hooks.$event = @($remaining)
        }
    }

    Write-CodexHooksJson -Path $HooksPath -Settings $settings
}

function Update-CodexMarkplaneHooks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$HooksPath,
        [Parameter(Mandatory = $true)][string]$HookScriptPath,
        [Parameter(Mandatory = $true)][string]$MarkplaneExePath,
        [int]$MaxContextChars = 6000
    )

    Backup-CodexHooksOnce -Path $HooksPath
    $settings = Read-CodexHooksJson -Path $HooksPath
    $hooks = Ensure-CodexProperty -Object $settings -Name "hooks" -Value ([pscustomobject]@{})

    foreach ($event in @("SessionStart", "PostToolUse", "SubagentStart", "Stop", "SubagentStop")) {
        $property = $hooks.PSObject.Properties[$event]
        if ($null -ne $property) {
            $remaining = Remove-CodexMarkplaneHandlersFromEvent -EventEntries $property.Value -HookScriptPath $HookScriptPath
            if ($remaining.Count -eq 0) {
                $hooks.PSObject.Properties.Remove($event)
            } else {
                $hooks.$event = @($remaining)
            }
        }
    }

    $entries = @{
        SessionStart = New-CodexMarkplaneHookEntry -Event "SessionStart" -Matcher "startup|resume|clear|compact" -HookScriptPath $HookScriptPath -MarkplaneExePath $MarkplaneExePath -MaxContextChars $MaxContextChars
        PostToolUse = New-CodexMarkplaneHookEntry -Event "PostToolUse" -Matcher "Edit|Write|MultiEdit|apply_patch|Bash|Shell|PowerShell|shell_command|exec_command|mcp__markplane__.*" -HookScriptPath $HookScriptPath -MarkplaneExePath $MarkplaneExePath -MaxContextChars $MaxContextChars
        SubagentStart = New-CodexMarkplaneHookEntry -Event "SubagentStart" -Matcher "*" -HookScriptPath $HookScriptPath -MarkplaneExePath $MarkplaneExePath -MaxContextChars $MaxContextChars
        Stop = New-CodexMarkplaneHookEntry -Event "Stop" -HookScriptPath $HookScriptPath -MarkplaneExePath $MarkplaneExePath -MaxContextChars $MaxContextChars
        SubagentStop = New-CodexMarkplaneHookEntry -Event "SubagentStop" -HookScriptPath $HookScriptPath -MarkplaneExePath $MarkplaneExePath -MaxContextChars $MaxContextChars
    }

    foreach ($event in @("SessionStart", "PostToolUse", "SubagentStart", "Stop", "SubagentStop")) {
        if ($null -eq $hooks.PSObject.Properties[$event]) {
            Add-Member -InputObject $hooks -NotePropertyName $event -NotePropertyValue @($entries[$event]) -Force
        } else {
            $hooks.$event = @(@($hooks.$event) + $entries[$event])
        }
    }

    Write-CodexHooksJson -Path $HooksPath -Settings $settings
}

function Remove-MarkplaneCodexHookState {
    $stateRoot = Join-Path $env:LOCALAPPDATA "ResearchWithCodingAgents\codex-hooks\sessions"
    if (Test-Path -LiteralPath $stateRoot -PathType Container) {
        Remove-Item -LiteralPath $stateRoot -Recurse -Force
    }
}

function Write-CodexHookPolicyWarnings {
    foreach ($path in @((Join-Path $HOME ".codex\config.toml"), (Join-Path $HOME ".codex\requirements.toml"))) {
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $text = Get-Content -Raw -LiteralPath $path
            if ($text -match '(?im)^\s*allow_managed_hooks_only\s*=\s*true\s*$') {
                Write-Warning "Codex allow_managed_hooks_only is enabled in $path. User-level Markplane hooks may require trust or may be ignored."
            }
        }
    }
}

function Invoke-CodexHookInstallerMain {
    if ($Uninstall) {
        $hookScript = Get-CodexHookDefaultScriptPath -InstallDir $InstallDir
        Remove-CodexMarkplaneHooks -HooksPath $HooksPath -HookScriptPath $hookScript
        Remove-MarkplaneCodexHookState
        Write-Host "Removed Markplane Codex hooks."
        return
    }

    $hookScript = Get-CodexHookDefaultScriptPath -InstallDir $InstallDir
    $markplaneExe = Get-CodexHookDefaultExePath -InstallDir $InstallDir
    if (-not (Test-Path -LiteralPath $hookScript -PathType Leaf)) {
        throw "Markplane Codex hook script was not found: $hookScript"
    }
    if (-not (Test-Path -LiteralPath $markplaneExe -PathType Leaf)) {
        throw "markplane.exe was not found: $markplaneExe"
    }

    Update-CodexMarkplaneHooks -HooksPath $HooksPath -HookScriptPath $hookScript -MarkplaneExePath $markplaneExe -MaxContextChars $MaxContextChars
    Write-CodexHookPolicyWarnings
    Write-Host "Installed Markplane Codex hooks."
    Write-Host "Codex may ask you to trust these hook commands on first use."
}

if ($MyInvocation.InvocationName -ne ".") {
    Invoke-CodexHookInstallerMain
}
