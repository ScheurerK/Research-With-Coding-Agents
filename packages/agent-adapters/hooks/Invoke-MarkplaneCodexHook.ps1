[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("SessionStart", "PostToolUse", "SubagentStart", "SubagentStop", "Stop", "SessionEnd")]
    [string]$Event,

    [Parameter(Mandatory = $true)]
    [string]$MarkplaneExe,

    [int]$MaxContextChars = 6000,

    [string]$StateRoot = (Join-Path $env:LOCALAPPDATA "Markplane\codex-hooks\sessions")
)

$ErrorActionPreference = "Stop"

function Get-CodexHookProperty {
    param(
        $Object,
        [Parameter(Mandatory = $true)][string[]]$Names
    )

    if ($null -eq $Object) {
        return $null
    }

    foreach ($name in $Names) {
        $property = $Object.PSObject.Properties[$name]
        if ($null -ne $property) {
            return $property.Value
        }
    }

    return $null
}

function Add-CodexNormalizedProperty {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        $Value
    )

    if ($null -eq $Object.PSObject.Properties[$Name]) {
        Add-Member -InputObject $Object -NotePropertyName $Name -NotePropertyValue $Value -Force
    } else {
        $Object.$Name = $Value
    }
}

function ConvertTo-ClaudeCompatibleHookInput {
    param([Parameter(Mandatory = $true)]$InputObject)

    $sessionId = Get-CodexHookProperty -Object $InputObject -Names @("session_id", "sessionId", "session")
    if ([string]::IsNullOrWhiteSpace([string]$sessionId)) {
        $sessionId = "unknown"
    }
    Add-CodexNormalizedProperty -Object $InputObject -Name "session_id" -Value ([string]$sessionId)

    $cwd = Get-CodexHookProperty -Object $InputObject -Names @("cwd", "workingDirectory", "working_directory")
    if (-not [string]::IsNullOrWhiteSpace([string]$cwd)) {
        Add-CodexNormalizedProperty -Object $InputObject -Name "cwd" -Value ([string]$cwd)
    }

    $toolName = Get-CodexHookProperty -Object $InputObject -Names @("tool_name", "toolName", "tool")
    if ($null -ne $toolName) {
        Add-CodexNormalizedProperty -Object $InputObject -Name "tool_name" -Value ([string]$toolName)
    }

    $toolInput = Get-CodexHookProperty -Object $InputObject -Names @("tool_input", "toolInput", "input")
    if ($null -ne $toolInput) {
        Add-CodexNormalizedProperty -Object $InputObject -Name "tool_input" -Value $toolInput
    }

    $backgroundTasks = Get-CodexHookProperty -Object $InputObject -Names @("background_tasks", "backgroundTasks")
    if ($null -ne $backgroundTasks) {
        Add-CodexNormalizedProperty -Object $InputObject -Name "background_tasks" -Value $backgroundTasks
    }

    return $InputObject
}

function Enable-CodexStopCheck {
    param(
        [Parameter(Mandatory = $true)]$InputObject,
        [Parameter(Mandatory = $true)][string]$StateRoot
    )

    $cwd = [string](Get-CodexHookProperty -Object $InputObject -Names @("cwd"))
    if ([string]::IsNullOrWhiteSpace($cwd)) {
        $cwd = (Get-Location).Path
    }

    $projectRoot = Find-MarkplaneProjectRoot -StartPath $cwd
    if (-not $projectRoot) {
        return
    }

    $sessionId = [string](Get-CodexHookProperty -Object $InputObject -Names @("session_id"))
    if ([string]::IsNullOrWhiteSpace($sessionId)) {
        $sessionId = "unknown"
    }

    $state = Get-MarkplaneHookState -SessionId $sessionId -ProjectRoot $projectRoot -StateRoot $StateRoot
    Set-MarkplaneHookState -SessionId $sessionId -ProjectRoot $projectRoot -StateRoot $StateRoot -Dirty $true -RetryUsed ([bool]$state.retryUsed)
}

try {
    $modulePath = Join-Path $PSScriptRoot "MarkplaneClaudeHooks.psm1"
    Import-Module $modulePath -Force

    $inputJson = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($inputJson)) {
        exit 0
    }

    $inputObject = ConvertTo-ClaudeCompatibleHookInput -InputObject ($inputJson | ConvertFrom-Json)
    $mappedEvent = $Event
    if ($Event -eq "SubagentStop") {
        $mappedEvent = "Stop"
    }

    if ($mappedEvent -eq "Stop") {
        Enable-CodexStopCheck -InputObject $inputObject -StateRoot $StateRoot
    }

    $result = Invoke-MarkplaneClaudeHookEvent -Event $mappedEvent -InputObject $inputObject -MarkplaneExe $MarkplaneExe -MaxContextChars $MaxContextChars -StateRoot $StateRoot
    if ($null -ne $result) {
        $result | ConvertTo-Json -Depth 30 -Compress | Write-Output
    }
} catch {
    [Console]::Error.WriteLine("Markplane Codex hook failed open: $($_.Exception.Message)")
    exit 0
}
