$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$adapter = Join-Path $root "hooks\Invoke-MarkplaneAntigravityHook.ps1"
$markplane = Join-Path $root "markplane.exe"

function Invoke-AntigravityHookProcess {
    param(
        [Parameter(Mandatory = $true)][string]$Event,
        [Parameter(Mandatory = $true)][string]$InputJson,
        [Parameter(Mandatory = $true)][string]$MarkplaneExe,
        [Parameter(Mandatory = $true)][string]$StateRoot
    )

    $stderrPath = Join-Path $TestDrive ("adapter-stderr-{0}.txt" -f [guid]::NewGuid().ToString("N"))
    $arguments = @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $adapter,
        "-Event", $Event, "-MarkplaneExe", $MarkplaneExe, "-StateRoot", $StateRoot
    )
    $stdout = $InputJson | & powershell.exe @arguments 2> $stderrPath
    $exitCode = $LASTEXITCODE
    $stderr = if (Test-Path -LiteralPath $stderrPath -PathType Leaf) {
        Get-Content -Raw -LiteralPath $stderrPath
    } else {
        ""
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        StdOut = (($stdout | Out-String).Trim())
        StdErr = $stderr
    }
}

function New-FailingMarkplaneProject {
    param([Parameter(Mandatory = $true)][string]$Path)

    $taskRoot = Join-Path $Path ".markplane\backlog\items"
    New-Item -ItemType Directory -Force -Path $taskRoot | Out-Null
    Set-Content -LiteralPath (Join-Path $taskRoot "TASK-broken.md") -Value @"
---
id: TASK-broken
title: Broken task
status: planned
---
# Broken task

## Description

[What needs to be done]
"@
}

Describe "Antigravity hook adapter contract" {
    It "returns empty output for later PreInvocation calls" {
        $json = '{"invocationNum":1,"conversationId":"later","workspacePaths":[]}' |
            powershell -NoProfile -ExecutionPolicy Bypass -File $adapter -Event PreInvocation -MarkplaneExe $markplane
        @(($json | ConvertFrom-Json).PSObject.Properties).Count | Should Be 0
    }

    It "returns an empty object for PostToolUse outside a Markplane project" {
        $json = ('{"stepIdx":2,"conversationId":"post","workspacePaths":["' + ($TestDrive -replace '\\','\\') + '"]}') |
            powershell -NoProfile -ExecutionPolicy Bypass -File $adapter -Event PostToolUse -MarkplaneExe $markplane
        @(($json | ConvertFrom-Json).PSObject.Properties).Count | Should Be 0
    }

    It "allows Stop outside a Markplane project" {
        $json = ('{"executionNum":1,"terminationReason":"model_stop","fullyIdle":true,"conversationId":"stop","workspacePaths":["' + ($TestDrive -replace '\\','\\') + '"]}') |
            powershell -NoProfile -ExecutionPolicy Bypass -File $adapter -Event Stop -MarkplaneExe $markplane
        ($json | ConvertFrom-Json).decision | Should Be "allow"
    }

    It "continues once then allows with a visible warning after two failed Stop checks" {
        $project = Join-Path $TestDrive "failing-stop-project"
        $stateRoot = Join-Path $TestDrive "failing-stop-state"
        New-FailingMarkplaneProject -Path $project
        $sessionId = "two-failed-stops"

        $postInput = [pscustomobject]@{
            stepIdx = 1
            conversationId = $sessionId
            workspacePaths = @($project)
            toolCall = [pscustomobject]@{
                name = "run_command"
                args = [pscustomobject]@{ command = "markplane sync" }
            }
        } | ConvertTo-Json -Depth 10 -Compress
        $post = Invoke-AntigravityHookProcess -Event PostToolUse -InputJson $postInput -MarkplaneExe $markplane -StateRoot $stateRoot
        $post.ExitCode | Should Be 0

        $stopInput = [pscustomobject]@{
            executionNum = 1
            terminationReason = "model_stop"
            fullyIdle = $true
            conversationId = $sessionId
            workspacePaths = @($project)
        } | ConvertTo-Json -Depth 10 -Compress
        $first = Invoke-AntigravityHookProcess -Event Stop -InputJson $stopInput -MarkplaneExe $markplane -StateRoot $stateRoot
        $second = Invoke-AntigravityHookProcess -Event Stop -InputJson $stopInput -MarkplaneExe $markplane -StateRoot $stateRoot
        $firstOutput = $first.StdOut | ConvertFrom-Json
        $secondOutput = $second.StdOut | ConvertFrom-Json

        $first.ExitCode | Should Be 0
        $firstOutput.decision | Should Be "continue"
        $firstOutput.reason | Should Match "Fix the issue once"
        $second.ExitCode | Should Be 0
        $secondOutput.decision | Should Be "allow"
        $second.StdErr | Should Match "still failed after one correction attempt"
    }

    It "allows Stop and reports a diagnostic when the shared hook throws" {
        $project = Join-Path $TestDrive "exception-stop-project"
        $stateRoot = Join-Path $TestDrive "exception-stop-state"
        New-FailingMarkplaneProject -Path $project
        $sessionId = "exception-stop"
        $postInput = [pscustomobject]@{
            conversationId = $sessionId
            workspacePaths = @($project)
            toolCall = [pscustomobject]@{
                name = "run_command"
                args = [pscustomobject]@{ command = "markplane sync" }
            }
        } | ConvertTo-Json -Depth 10 -Compress
        [void](Invoke-AntigravityHookProcess -Event PostToolUse -InputJson $postInput -MarkplaneExe $markplane -StateRoot $stateRoot)

        $stopInput = [pscustomobject]@{
            fullyIdle = $true
            conversationId = $sessionId
            workspacePaths = @($project)
        } | ConvertTo-Json -Depth 10 -Compress
        $result = Invoke-AntigravityHookProcess -Event Stop -InputJson $stopInput -MarkplaneExe (Join-Path $TestDrive "missing-markplane.exe") -StateRoot $stateRoot

        $result.ExitCode | Should Be 0
        ($result.StdOut | ConvertFrom-Json).decision | Should Be "allow"
        $result.StdErr | Should Match "Markplane Antigravity hook failed open"
    }
}