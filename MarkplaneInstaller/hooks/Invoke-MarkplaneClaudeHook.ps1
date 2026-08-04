[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("SessionStart", "PostToolUse", "SubagentStart", "Stop", "SessionEnd")]
    [string]$Event,

    [Parameter(Mandatory = $true)]
    [string]$MarkplaneExe,

    [int]$MaxContextChars = 6000,

    [string]$StateRoot = (Join-Path $env:LOCALAPPDATA "Markplane\claude-hooks\sessions")
)

$ErrorActionPreference = "Stop"

try {
    $modulePath = Join-Path $PSScriptRoot "MarkplaneClaudeHooks.psm1"
    Import-Module $modulePath -Force

    $inputJson = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($inputJson)) {
        exit 0
    }

    $inputObject = $inputJson | ConvertFrom-Json
    $result = Invoke-MarkplaneClaudeHookEvent -Event $Event -InputObject $inputObject -MarkplaneExe $MarkplaneExe -MaxContextChars $MaxContextChars -StateRoot $StateRoot
    if ($null -ne $result) {
        $result | ConvertTo-Json -Depth 30 -Compress | Write-Output
    }
} catch {
    [Console]::Error.WriteLine("Markplane Claude hook failed open: $($_.Exception.Message)")
    exit 0
}
