[CmdletBinding()]
param(
    [string]$InstallDir = "$env:LOCALAPPDATA\Programs\Markplane",
    [string]$SettingsPath = (Join-Path $HOME ".claude\settings.json"),
    [int]$MaxContextChars = 6000,
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

function Get-ClaudeHookDefaultScriptPath {
    param([Parameter(Mandatory = $true)][string]$InstallDir)
    return (Join-Path $InstallDir "hooks\Invoke-MarkplaneClaudeHook.ps1")
}

function Get-ClaudeHookDefaultExePath {
    param([Parameter(Mandatory = $true)][string]$InstallDir)
    return (Join-Path $InstallDir "markplane.exe")
}

function Read-ClaudeSettingsJson {
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

function Write-ClaudeSettingsJson {
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

function Ensure-ClaudeProperty {
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

function Backup-ClaudeSettingsOnce {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return
    }
    $backup = "$Path.markplane.bak"
    if (-not (Test-Path -LiteralPath $backup)) {
        Copy-Item -LiteralPath $Path -Destination $backup
    }
}

function Test-MarkplaneHookHandler {
    param(
        $Hook,
        [Parameter(Mandatory = $true)][string]$HookScriptPath
    )

    if ($null -eq $Hook) {
        return $false
    }
    $args = @($Hook.args)
    foreach ($arg in $args) {
        if ([string]$arg -ieq $HookScriptPath) {
            return $true
        }
    }
    $command = [string]$Hook.command
    return ($command -ieq $HookScriptPath)
}

function Remove-MarkplaneHandlersFromEvent {
    param(
        [Parameter(Mandatory = $true)]$EventEntries,
        [Parameter(Mandatory = $true)][string]$HookScriptPath
    )

    $remainingEntries = @()
    foreach ($entry in @($EventEntries)) {
        $remainingHooks = @()
        foreach ($hook in @($entry.hooks)) {
            if (-not (Test-MarkplaneHookHandler -Hook $hook -HookScriptPath $HookScriptPath)) {
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

function New-MarkplaneHookEntry {
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

    $hook = [pscustomobject]@{
        type = "command"
        command = "powershell.exe"
        args = @($arguments)
        timeout = 10
    }

    if ([string]::IsNullOrWhiteSpace($Matcher)) {
        return [pscustomobject]@{ hooks = @($hook) }
    }

    return [pscustomobject]@{
        matcher = $Matcher
        hooks = @($hook)
    }
}

function Remove-ClaudeCodeMarkplaneHooks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$SettingsPath,
        [Parameter(Mandatory = $true)][string]$HookScriptPath
    )

    $settings = Read-ClaudeSettingsJson -Path $SettingsPath
    $hooks = $settings.PSObject.Properties["hooks"]
    if ($null -eq $hooks) {
        return
    }

    foreach ($event in @("SessionStart", "PostToolUse", "SubagentStart", "Stop", "SessionEnd")) {
        $property = $settings.hooks.PSObject.Properties[$event]
        if ($null -eq $property) {
            continue
        }
        $remaining = Remove-MarkplaneHandlersFromEvent -EventEntries $property.Value -HookScriptPath $HookScriptPath
        if ($remaining.Count -eq 0) {
            $settings.hooks.PSObject.Properties.Remove($event)
        } else {
            $settings.hooks.$event = @($remaining)
        }
    }

    Write-ClaudeSettingsJson -Path $SettingsPath -Settings $settings
}

function Update-ClaudeCodeMarkplaneHooks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$SettingsPath,
        [Parameter(Mandatory = $true)][string]$HookScriptPath,
        [Parameter(Mandatory = $true)][string]$MarkplaneExePath,
        [int]$MaxContextChars = 6000
    )

    Backup-ClaudeSettingsOnce -Path $SettingsPath
    $settings = Read-ClaudeSettingsJson -Path $SettingsPath
    $hooks = Ensure-ClaudeProperty -Object $settings -Name "hooks" -Value ([pscustomobject]@{})

    foreach ($event in @("SessionStart", "PostToolUse", "SubagentStart", "Stop", "SessionEnd")) {
        $property = $hooks.PSObject.Properties[$event]
        if ($null -ne $property) {
            $remaining = Remove-MarkplaneHandlersFromEvent -EventEntries $property.Value -HookScriptPath $HookScriptPath
            if ($remaining.Count -eq 0) {
                $hooks.PSObject.Properties.Remove($event)
            } else {
                $hooks.$event = @($remaining)
            }
        }
    }

    $entries = @{
        SessionStart = New-MarkplaneHookEntry -Event "SessionStart" -Matcher "startup|resume|clear|compact" -HookScriptPath $HookScriptPath -MarkplaneExePath $MarkplaneExePath -MaxContextChars $MaxContextChars
        PostToolUse = New-MarkplaneHookEntry -Event "PostToolUse" -Matcher "Edit|Write|Bash|mcp__markplane__.*" -HookScriptPath $HookScriptPath -MarkplaneExePath $MarkplaneExePath -MaxContextChars $MaxContextChars
        SubagentStart = New-MarkplaneHookEntry -Event "SubagentStart" -Matcher "*" -HookScriptPath $HookScriptPath -MarkplaneExePath $MarkplaneExePath -MaxContextChars $MaxContextChars
        Stop = New-MarkplaneHookEntry -Event "Stop" -HookScriptPath $HookScriptPath -MarkplaneExePath $MarkplaneExePath -MaxContextChars $MaxContextChars
        SessionEnd = New-MarkplaneHookEntry -Event "SessionEnd" -HookScriptPath $HookScriptPath -MarkplaneExePath $MarkplaneExePath -MaxContextChars $MaxContextChars
    }

    foreach ($event in @("SessionStart", "PostToolUse", "SubagentStart", "Stop", "SessionEnd")) {
        if ($null -eq $hooks.PSObject.Properties[$event]) {
            Add-Member -InputObject $hooks -NotePropertyName $event -NotePropertyValue @($entries[$event]) -Force
        } else {
            $hooks.$event = @(@($hooks.$event) + $entries[$event])
        }
    }

    if ($settings.PSObject.Properties["disableAllHooks"] -and [bool]$settings.disableAllHooks) {
        Write-Warning "Claude Code disableAllHooks is set. Markplane hooks were installed but Claude may not run them."
    }
    if ($settings.PSObject.Properties["allowManagedHooksOnly"] -and [bool]$settings.allowManagedHooksOnly) {
        Write-Warning "Claude Code allowManagedHooksOnly is set. User-scoped Markplane hooks may be ignored."
    }

    Write-ClaudeSettingsJson -Path $SettingsPath -Settings $settings
}

function Remove-MarkplaneClaudeHookState {
    $stateRoot = Join-Path $env:LOCALAPPDATA "Markplane\claude-hooks\sessions"
    if (Test-Path -LiteralPath $stateRoot -PathType Container) {
        Remove-Item -LiteralPath $stateRoot -Recurse -Force
    }
}

function Invoke-ClaudeCodeHookInstallerMain {
    if ($Uninstall) {
        $hookScript = Get-ClaudeHookDefaultScriptPath -InstallDir $InstallDir
        Remove-ClaudeCodeMarkplaneHooks -SettingsPath $SettingsPath -HookScriptPath $hookScript
        Remove-MarkplaneClaudeHookState
        Write-Host "Removed Markplane Claude Code hooks."
        return
    }

    $hookScript = Get-ClaudeHookDefaultScriptPath -InstallDir $InstallDir
    $markplaneExe = Get-ClaudeHookDefaultExePath -InstallDir $InstallDir
    if (-not (Test-Path -LiteralPath $hookScript -PathType Leaf)) {
        throw "Markplane Claude hook script was not found: $hookScript"
    }
    if (-not (Test-Path -LiteralPath $markplaneExe -PathType Leaf)) {
        throw "markplane.exe was not found: $markplaneExe"
    }

    Update-ClaudeCodeMarkplaneHooks -SettingsPath $SettingsPath -HookScriptPath $hookScript -MarkplaneExePath $markplaneExe -MaxContextChars $MaxContextChars
    Write-Host "Installed Markplane Claude Code hooks."
    Write-Host "In Claude Code, run /hooks to inspect them."
}

if ($MyInvocation.InvocationName -ne ".") {
    Invoke-ClaudeCodeHookInstallerMain
}
