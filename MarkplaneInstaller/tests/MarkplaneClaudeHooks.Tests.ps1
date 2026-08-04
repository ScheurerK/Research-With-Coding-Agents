$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$module = Join-Path $root "hooks\MarkplaneClaudeHooks.psm1"

Describe "Markplane Claude hook runtime" {
    It "ships the runtime module" {
        (Test-Path -LiteralPath $module -PathType Leaf) | Should Be $true
    }
}

if (Test-Path -LiteralPath $module) {
    Import-Module $module -Force

    Describe "Project and event routing" {
        It "finds a Markplane root from a nested directory" {
            $project = Join-Path $TestDrive "project"
            $nested = Join-Path $project "src\nested"
            New-Item -ItemType Directory -Force -Path (Join-Path $project ".markplane"), $nested | Out-Null
            (Find-MarkplaneProjectRoot -StartPath $nested) | Should Be $project
        }

        It "ignores normal edits but recognizes Markplane mutations" {
            $normal = [pscustomobject]@{ tool_name = "Edit"; tool_input = [pscustomobject]@{ file_path = "C:\repo\src\app.ps1" } }
            $item = [pscustomobject]@{ tool_name = "Write"; tool_input = [pscustomobject]@{ file_path = "C:\repo\.markplane\backlog\items\TASK-a.md" } }
            $read = [pscustomobject]@{ tool_name = "mcp__markplane__markplane_summary"; tool_input = [pscustomobject]@{} }
            $write = [pscustomobject]@{ tool_name = "mcp__markplane__markplane_update"; tool_input = [pscustomobject]@{} }
            (Test-MarkplaneRelevantPostToolUse -InputObject $normal -ProjectRoot "C:\repo") | Should Be $false
            (Test-MarkplaneRelevantPostToolUse -InputObject $item -ProjectRoot "C:\repo") | Should Be $true
            (Test-MarkplaneRelevantPostToolUse -InputObject $read -ProjectRoot "C:\repo") | Should Be $false
            (Test-MarkplaneRelevantPostToolUse -InputObject $write -ProjectRoot "C:\repo") | Should Be $true
        }
        It "recognizes Superpowers plan edits as Markplane-relevant" {
            $plan = [pscustomobject]@{ tool_name = "Edit"; tool_input = [pscustomobject]@{ file_path = "C:\repo\docs\superpowers\plans\2026-07-22-feature.md" } }
            (Test-MarkplaneRelevantPostToolUse -InputObject $plan -ProjectRoot "C:\repo") | Should Be $true
        }

        It "recognizes Codex command and patch mutations" {
            $command = [pscustomobject]@{ tool_name = "shell_command"; tool_input = [pscustomobject]@{ command = "markplane sync" } }
            $patch = [pscustomobject]@{ tool_name = "apply_patch"; tool_input = [pscustomobject]@{ patch = "*** Update File: docs/superpowers/plans/feature.md`n+details" } }
            (Test-MarkplaneRelevantPostToolUse -InputObject $command -ProjectRoot "C:\repo") | Should Be $true
            (Test-MarkplaneRelevantPostToolUse -InputObject $patch -ProjectRoot "C:\repo") | Should Be $true
        }

        It "recognizes Antigravity file and command mutations" {
            $normal = [pscustomobject]@{ tool_name = "write_to_file"; tool_input = [pscustomobject]@{ TargetFile = "C:\repo\src\app.ps1" } }
            $item = [pscustomobject]@{ tool_name = "replace_file_content"; tool_input = [pscustomobject]@{ TargetFile = "C:\repo\.markplane\backlog\items\TASK-a.md" } }
            $plan = [pscustomobject]@{ tool_name = "multi_replace_file_content"; tool_input = [pscustomobject]@{ TargetFile = "C:\repo\docs\superpowers\plans\feature.md" } }
            $command = [pscustomobject]@{ tool_name = "run_command"; tool_input = [pscustomobject]@{ CommandLine = "markplane update TASK-a --status in-progress" } }
            (Test-MarkplaneRelevantPostToolUse -InputObject $normal -ProjectRoot "C:\repo") | Should Be $false
            (Test-MarkplaneRelevantPostToolUse -InputObject $item -ProjectRoot "C:\repo") | Should Be $true
            (Test-MarkplaneRelevantPostToolUse -InputObject $plan -ProjectRoot "C:\repo") | Should Be $true
            (Test-MarkplaneRelevantPostToolUse -InputObject $command -ProjectRoot "C:\repo") | Should Be $true
        }

        It "caps context without splitting a surrogate pair" {
            $text = ("x" * 5999) + [char]0xD83D + [char]0xDE80 + "tail"
            $limited = Limit-MarkplaneContext -Text $text -MaxCharacters 6000
            [char]::IsHighSurrogate($limited[$limited.Length - 1]) | Should Be $false
            $limited | Should Match "truncated"
        }
    }

    Describe "Markplane quality gates" {
        It "flags planned tasks that still contain placeholders" {
            $project = Join-Path $TestDrive ([guid]::NewGuid().ToString("N"))
            $taskDir = Join-Path $project ".markplane\backlog\items"
            New-Item -ItemType Directory -Force -Path $taskDir | Out-Null
            Set-Content -LiteralPath (Join-Path $taskDir "TASK-test1.md") -Value @"
---
id: TASK-test1
title: Placeholder task
status: planned
priority: high
type: feature
effort: medium
---
# Placeholder task

## Description

[What needs to be done]

## Acceptance Criteria

- [ ] Criterion 1
"@
            $result = Test-MarkplaneProjectQuality -ProjectRoot $project
            $result.ExitCode | Should Be 1
            $result.StdOut | Should Match "TASK-test1"
            $result.StdOut | Should Match "placeholder"
        }

        It "flags Superpowers plans that are not linked from a Markplane PLAN" {
            $project = Join-Path $TestDrive ([guid]::NewGuid().ToString("N"))
            New-Item -ItemType Directory -Force -Path (Join-Path $project ".markplane\plans\items"), (Join-Path $project "docs\superpowers\plans") | Out-Null
            Set-Content -LiteralPath (Join-Path $project "docs\superpowers\plans\2026-07-22-feature.md") -Value "# Feature Plan"
            $result = Test-MarkplaneProjectQuality -ProjectRoot $project
            $result.ExitCode | Should Be 1
            $result.StdOut | Should Match "not linked"
            $result.StdOut | Should Match "docs/superpowers/plans/2026-07-22-feature.md"
        }

        It "flags a plan that does not implement any task" {
            $project = Join-Path $TestDrive ([guid]::NewGuid().ToString("N"))
            $planDir = Join-Path $project ".markplane\plans\items"
            New-Item -ItemType Directory -Force -Path $planDir | Out-Null
            Set-Content -LiteralPath (Join-Path $planDir "PLAN-y.md") -Value @"
---
id: PLAN-y
status: approved
implements: []
---
# Plan Y

## Ground Truth
- some/file.rs:L1-10 - concrete source reference

## Approach
Concrete approach text describing the design.

## Testing Strategy
Concrete testing text describing verification steps.
"@
            $result = Test-MarkplaneProjectQuality -ProjectRoot $project
            $result.ExitCode | Should Be 1
            $result.StdOut | Should Match "does not implement any task"

            Set-Content -LiteralPath (Join-Path $planDir "PLAN-y.md") -Value @"
---
id: PLAN-y
status: approved
implements: [TASK-z]
---
# Plan Y

## Ground Truth
- some/file.rs:L1-10 - concrete source reference

## Approach
Concrete approach text describing the design.

## Testing Strategy
Concrete testing text describing verification steps.
"@
            $result = Test-MarkplaneProjectQuality -ProjectRoot $project
            $result.ExitCode | Should Be 0
        }

        It "flags an Epic with no tasks linked, and softly warns about unlinked tasks" {
            $project = Join-Path $TestDrive ([guid]::NewGuid().ToString("N"))
            $taskDir = Join-Path $project ".markplane\backlog\items"
            $epicDir = Join-Path $project "roadmap\items"
            New-Item -ItemType Directory -Force -Path $taskDir, $epicDir | Out-Null
            Set-Content -LiteralPath (Join-Path $epicDir "EPIC-orphan.md") -Value @"
---
id: EPIC-orphan
title: Orphan Epic
status: later
---
# Orphan Epic
"@
            $result = Test-MarkplaneProjectQuality -ProjectRoot $project
            $result.ExitCode | Should Be 1
            $result.StdOut | Should Match "epic has no tasks linked"

            Set-Content -LiteralPath (Join-Path $taskDir "TASK-linked.md") -Value @"
---
id: TASK-linked
title: Linked task
status: done
epic: EPIC-orphan
---
# Linked task
"@
            $result = Test-MarkplaneProjectQuality -ProjectRoot $project
            $result.ExitCode | Should Be 0

            Set-Content -LiteralPath (Join-Path $taskDir "TASK-unlinked.md") -Value @"
---
id: TASK-unlinked
title: Unlinked task
status: done
epic: null
---
# Unlinked task
"@
            $result = Test-MarkplaneProjectQuality -ProjectRoot $project
            $result.ExitCode | Should Be 0
            $result.StdOut | Should Match "not linked to any Epic"
        }
    }
    Describe "Lifecycle behavior" {
        BeforeEach {
            $script:calls = @()
            $script:results = @{}
            $script:runner = {
                param($Executable, $Arguments, $WorkingDirectory)
                $script:calls += ,([pscustomobject]@{ Arguments = @($Arguments); WorkingDirectory = $WorkingDirectory })
                if ($script:results.ContainsKey($Arguments[0])) { return $script:results[$Arguments[0]] }
                [pscustomobject]@{ ExitCode = 0; StdOut = ""; StdErr = "" }
            }
            $script:project = Join-Path $TestDrive ([guid]::NewGuid().ToString("N"))
            New-Item -ItemType Directory -Force -Path (Join-Path $script:project ".markplane\.context") | Out-Null
            Set-Content -LiteralPath (Join-Path $script:project ".markplane\.context\summary.md") -Value "# Project A`n## Key Metrics`n- Backlog: 0 items"
            Set-Content -LiteralPath (Join-Path $script:project ".markplane\.context\resume.md") -Value "# Resume: Project A`n## Active Work`n- TASK-x: In progress item"
            $script:state = Join-Path $TestDrive "state"
        }

        It "syncs and injects the current project on SessionStart" {
            $input = [pscustomobject]@{ session_id = "s1"; cwd = $script:project; source = "startup" }
            $result = Invoke-MarkplaneClaudeHookEvent -Event SessionStart -InputObject $input -MarkplaneExe "C:\Markplane\markplane.exe" -StateRoot $script:state -CommandRunner $script:runner
            $script:calls[0].Arguments[0] | Should Be "sync"
            $result.hookSpecificOutput.additionalContext | Should Match "Project A"
            $result.hookSpecificOutput.additionalContext | Should Match "Key Metrics"
        }

        It "injects the lean resume view instead of the full summary on compact" {
            $input = [pscustomobject]@{ session_id = "s1b"; cwd = $script:project; source = "compact" }
            $result = Invoke-MarkplaneClaudeHookEvent -Event SessionStart -InputObject $input -MarkplaneExe "C:\Markplane\markplane.exe" -StateRoot $script:state -CommandRunner $script:runner
            $script:calls[0].Arguments[0] | Should Be "sync"
            $result.hookSpecificOutput.additionalContext | Should Match "TASK-x"
            $result.hookSpecificOutput.additionalContext | Should Not Match "Key Metrics"
        }

        It "syncs relevant PostToolUse and marks state dirty" {
            $input = [pscustomobject]@{ session_id = "s2"; cwd = $script:project; tool_name = "mcp__markplane__markplane_add"; tool_input = [pscustomobject]@{} }
            Invoke-MarkplaneClaudeHookEvent -Event PostToolUse -InputObject $input -MarkplaneExe "C:\Markplane\markplane.exe" -StateRoot $script:state -CommandRunner $script:runner
            $script:calls.Count | Should Be 1
            (Get-MarkplaneHookState -SessionId "s2" -ProjectRoot $script:project -StateRoot $script:state).dirty | Should Be $true
        }

        It "requests one correction and then warns when check fails" {
            Set-MarkplaneHookState -SessionId "s3" -ProjectRoot $script:project -StateRoot $script:state -Dirty $true -RetryUsed $false
            $script:results["check"] = [pscustomobject]@{ ExitCode = 1; StdOut = "broken reference"; StdErr = "" }
            $first = Invoke-MarkplaneClaudeHookEvent -Event Stop -InputObject ([pscustomobject]@{ session_id = "s3"; cwd = $script:project; stop_hook_active = $false; background_tasks = @() }) -MarkplaneExe "C:\Markplane\markplane.exe" -StateRoot $script:state -CommandRunner $script:runner
            $second = Invoke-MarkplaneClaudeHookEvent -Event Stop -InputObject ([pscustomobject]@{ session_id = "s3"; cwd = $script:project; stop_hook_active = $true; background_tasks = @() }) -MarkplaneExe "C:\Markplane\markplane.exe" -StateRoot $script:state -CommandRunner $script:runner
            $first.hookSpecificOutput.additionalContext | Should Match "broken reference"
            $second.systemMessage | Should Match "broken reference"
        }
        It "runs all Markplane checks including quality gates on Stop" {
            Set-MarkplaneHookState -SessionId "s4" -ProjectRoot $script:project -StateRoot $script:state -Dirty $true -RetryUsed $false
            New-Item -ItemType Directory -Force -Path (Join-Path $script:project ".markplane\backlog\items") | Out-Null
            Set-Content -LiteralPath (Join-Path $script:project ".markplane\backlog\items\TASK-test2.md") -Value @"
---
id: TASK-test2
title: Empty planned task
status: planned
priority: high
type: feature
effort: medium
---
# Empty planned task

## Description

[What needs to be done]
"@
            $result = Invoke-MarkplaneClaudeHookEvent -Event Stop -InputObject ([pscustomobject]@{ session_id = "s4"; cwd = $script:project; stop_hook_active = $false; background_tasks = @() }) -MarkplaneExe "C:\Markplane\markplane.exe" -StateRoot $script:state -CommandRunner $script:runner
            @($script:calls | Where-Object { $_.Arguments[0] -eq "check" }).Count | Should Be 1
            $result.hookSpecificOutput.additionalContext | Should Match "Markplane quality check failed"
            $result.hookSpecificOutput.additionalContext | Should Match "TASK-test2"
        }
    }
}
