$root = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent (Split-Path -Parent $root)
$installer = Join-Path $root "Install-CodexHooks.ps1"
$adapter = Join-Path $repoRoot "packages\agent-adapters\hooks\Invoke-MarkplaneCodexHook.ps1"

Describe "Codex hook installer" {
    It "ships the installer and adapter" {
        (Test-Path -LiteralPath $installer -PathType Leaf) | Should Be $true
        (Test-Path -LiteralPath $adapter -PathType Leaf) | Should Be $true
    }
}

if ((Test-Path -LiteralPath $installer) -and (Test-Path -LiteralPath $adapter)) {
    . $installer

    Describe "Codex hooks.json merge" {
        BeforeEach {
            $script:hooksJson = Join-Path $TestDrive "hooks.json"
            $script:hook = "C:\Program Files\Markplane\hooks\Invoke-MarkplaneCodexHook.ps1"
            $script:exe = "C:\Program Files\Markplane\markplane.exe"
            Set-Content -LiteralPath $script:hooksJson -Value '{"hooks":{"PreToolUse":[{"matcher":"^Bash$","hooks":[{"type":"command","command":"policy.exe","timeout":3}]}]}}'
        }

        It "preserves unrelated hooks and installs five events idempotently" {
            Update-CodexMarkplaneHooks -HooksPath $script:hooksJson -HookScriptPath $script:hook -MarkplaneExePath $script:exe
            Update-CodexMarkplaneHooks -HooksPath $script:hooksJson -HookScriptPath $script:hook -MarkplaneExePath $script:exe
            $json = Get-Content -Raw -LiteralPath $script:hooksJson | ConvertFrom-Json
            $json.hooks.PreToolUse[0].hooks[0].command | Should Be "policy.exe"
            @($json.hooks.SessionStart).Count | Should Be 1
            @($json.hooks.PostToolUse).Count | Should Be 1
            @($json.hooks.SubagentStart).Count | Should Be 1
            @($json.hooks.Stop).Count | Should Be 1
            @($json.hooks.SubagentStop).Count | Should Be 1
        }

        It "removes only Markplane Codex handlers" {
            Update-CodexMarkplaneHooks -HooksPath $script:hooksJson -HookScriptPath $script:hook -MarkplaneExePath $script:exe
            Remove-CodexMarkplaneHooks -HooksPath $script:hooksJson -HookScriptPath $script:hook
            $json = Get-Content -Raw -LiteralPath $script:hooksJson | ConvertFrom-Json
            $json.hooks.PreToolUse[0].hooks[0].command | Should Be "policy.exe"
            $json.hooks.SessionStart | Should BeNullOrEmpty
            $json.hooks.PostToolUse | Should BeNullOrEmpty
        }

        It "creates a backup only once" {
            Update-CodexMarkplaneHooks -HooksPath $script:hooksJson -HookScriptPath $script:hook -MarkplaneExePath $script:exe
            $backup = "$($script:hooksJson).markplane.bak"
            $before = Get-Content -Raw -LiteralPath $backup
            Set-Content -LiteralPath $script:hooksJson -Value '{"hooks":{}}'
            Update-CodexMarkplaneHooks -HooksPath $script:hooksJson -HookScriptPath $script:hook -MarkplaneExePath $script:exe
            (Get-Content -Raw -LiteralPath $backup) | Should Be $before
        }
    }
}