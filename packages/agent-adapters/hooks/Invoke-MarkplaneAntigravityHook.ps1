[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("PreInvocation", "PostToolUse", "Stop")]
    [string]$Event,

    [Parameter(Mandatory = $true)]
    [string]$MarkplaneExe,

    [int]$MaxContextChars = 6000,

    [string]$StateRoot = (Join-Path $env:LOCALAPPDATA "Markplane\antigravity-hooks\sessions")
)

$ErrorActionPreference = "Stop"

function Get-AntigravityProperty {
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

function Add-AntigravityNormalizedProperty {
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

function ConvertTo-ClaudeCompatibleAntigravityInput {
    param([Parameter(Mandatory = $true)]$InputObject)

    $sessionId = Get-AntigravityProperty -Object $InputObject -Names @("session_id", "sessionId", "conversationId")
    if ([string]::IsNullOrWhiteSpace([string]$sessionId)) {
        $sessionId = "unknown"
    }
    Add-AntigravityNormalizedProperty -Object $InputObject -Name "session_id" -Value ([string]$sessionId)

    $workspacePaths = @(Get-AntigravityProperty -Object $InputObject -Names @("workspacePaths", "workspace_paths"))
    if ($workspacePaths.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$workspacePaths[0])) {
        Add-AntigravityNormalizedProperty -Object $InputObject -Name "cwd" -Value ([string]$workspacePaths[0])
    }

    $toolCall = Get-AntigravityProperty -Object $InputObject -Names @("toolCall", "tool_call")
    if ($null -ne $toolCall) {
        $toolName = Get-AntigravityProperty -Object $toolCall -Names @("name")
        if ($null -ne $toolName) {
            Add-AntigravityNormalizedProperty -Object $InputObject -Name "tool_name" -Value ([string]$toolName)
        }
        $toolArgs = Get-AntigravityProperty -Object $toolCall -Names @("args")
        if ($null -ne $toolArgs) {
            Add-AntigravityNormalizedProperty -Object $InputObject -Name "tool_input" -Value $toolArgs
        }
    }

    $fullyIdle = Get-AntigravityProperty -Object $InputObject -Names @("fullyIdle", "fully_idle")
    if ($null -ne $fullyIdle -and -not [bool]$fullyIdle) {
        Add-AntigravityNormalizedProperty -Object $InputObject -Name "background_tasks" -Value @("antigravity-active")
    }

    return $InputObject
}

function ConvertTo-AntigravityOutput {
    param(
        [Parameter(Mandatory = $true)][string]$Event,
        $HookResult
    )

    if ($null -eq $HookResult) {
        if ($Event -eq "Stop") {
            return [pscustomobject]@{ decision = "allow" }
        }
        return [pscustomobject]@{}
    }

    $hookContext = $null
    $systemMessage = $null
    if ($HookResult.PSObject.Properties["hookSpecificOutput"]) {
        $hookContext = [string]$HookResult.hookSpecificOutput.additionalContext
    }
    if ($HookResult.PSObject.Properties["systemMessage"]) {
        $systemMessage = [string]$HookResult.systemMessage
    }

    if ($Event -eq "Stop") {
        if (-not [string]::IsNullOrWhiteSpace($hookContext)) {
            return [pscustomobject]@{
                decision = "continue"
                reason = $hookContext
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($systemMessage)) {
            [Console]::Error.WriteLine($systemMessage)
        }
        return [pscustomobject]@{ decision = "allow" }
    }

    $additionalContext = if (-not [string]::IsNullOrWhiteSpace($hookContext)) { $hookContext } else { $systemMessage }
    if (-not [string]::IsNullOrWhiteSpace($additionalContext)) {
        return [pscustomobject]@{
            injectSteps = @(
                [pscustomobject]@{ ephemeralMessage = $additionalContext }
            )
        }
    }

    return [pscustomobject]@{}
}

try {
    $modulePath = Join-Path $PSScriptRoot "MarkplaneClaudeHooks.psm1"
    Import-Module $modulePath -Force

    $inputJson = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($inputJson)) {
        "{}" | Write-Output
        exit 0
    }

    $inputObject = ConvertTo-ClaudeCompatibleAntigravityInput -InputObject ($inputJson | ConvertFrom-Json)
    $mappedEvent = switch ($Event) {
        "PreInvocation" { "SessionStart" }
        "PostToolUse" { "PostToolUse" }
        "Stop" { "Stop" }
    }

    if ($Event -eq "PreInvocation") {
        $invocationNum = Get-AntigravityProperty -Object $inputObject -Names @("invocationNum", "invocation_num")
        if ($null -ne $invocationNum -and [int]$invocationNum -gt 0) {
            "{}" | Write-Output
            exit 0
        }
    }

    if ($Event -eq "PostToolUse" -and $null -eq (Get-AntigravityProperty -Object $inputObject -Names @("tool_name"))) {
        Add-AntigravityNormalizedProperty -Object $inputObject -Name "tool_name" -Value "run_command"
        Add-AntigravityNormalizedProperty -Object $inputObject -Name "tool_input" -Value ([pscustomobject]@{ command = "markplane sync" })
    }

    $result = Invoke-MarkplaneClaudeHookEvent -Event $mappedEvent -InputObject $inputObject -MarkplaneExe $MarkplaneExe -MaxContextChars $MaxContextChars -StateRoot $StateRoot
    ConvertTo-AntigravityOutput -Event $Event -HookResult $result | ConvertTo-Json -Depth 30 -Compress | Write-Output
} catch {
    [Console]::Error.WriteLine("Markplane Antigravity hook failed open: $($_.Exception.Message)")
    if ($Event -eq "Stop") {
        '{"decision":"allow"}' | Write-Output
    } else {
        "{}" | Write-Output
    }
    exit 0
}
