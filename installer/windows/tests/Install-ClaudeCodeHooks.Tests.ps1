$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$installer = Join-Path $root "Install-ClaudeCodeHooks.ps1"

Describe "Claude hook installer" {
    It "ships the installer" {
        (Test-Path -LiteralPath $installer -PathType Leaf) | Should Be $true
    }
}

if (Test-Path -LiteralPath $installer) {
    . $installer

    Describe "Settings merge" {
        BeforeEach {
            $script:settings = Join-Path $TestDrive "settings.json"
            $script:hook = "C:\Program Files\Markplane\hooks\Invoke-MarkplaneClaudeHook.ps1"
            $script:exe = "C:\Program Files\Markplane\markplane.exe"
            Set-Content -LiteralPath $script:settings -Value '{"permissions":{"allow":["mcp__matlab__evaluate"]},"hooks":{"Notification":[{"matcher":"idle_prompt","hooks":[{"type":"command","command":"notify.exe"}]}]}}'
        }

        It "preserves unrelated settings and installs five events idempotently" {
            Update-ClaudeCodeMarkplaneHooks -SettingsPath $script:settings -HookScriptPath $script:hook -MarkplaneExePath $script:exe
            Update-ClaudeCodeMarkplaneHooks -SettingsPath $script:settings -HookScriptPath $script:hook -MarkplaneExePath $script:exe
            $json = Get-Content -Raw -LiteralPath $script:settings | ConvertFrom-Json
            $json.permissions.allow[0] | Should Be "mcp__matlab__evaluate"
            $json.hooks.Notification[0].hooks[0].command | Should Be "notify.exe"
            @($json.hooks.SessionStart).Count | Should Be 1
            @($json.hooks.PostToolUse).Count | Should Be 1
            @($json.hooks.SubagentStart).Count | Should Be 1
            @($json.hooks.Stop).Count | Should Be 1
            @($json.hooks.SessionEnd).Count | Should Be 1
        }

        It "removes only Markplane handlers" {
            Update-ClaudeCodeMarkplaneHooks -SettingsPath $script:settings -HookScriptPath $script:hook -MarkplaneExePath $script:exe
            Remove-ClaudeCodeMarkplaneHooks -SettingsPath $script:settings -HookScriptPath $script:hook
            $json = Get-Content -Raw -LiteralPath $script:settings | ConvertFrom-Json
            $json.hooks.Notification[0].hooks[0].command | Should Be "notify.exe"
            $json.hooks.SessionStart | Should BeNullOrEmpty
            $json.permissions.allow[0] | Should Be "mcp__matlab__evaluate"
        }

        It "creates a backup only once" {
            Update-ClaudeCodeMarkplaneHooks -SettingsPath $script:settings -HookScriptPath $script:hook -MarkplaneExePath $script:exe
            $backup = "$($script:settings).markplane.bak"
            $before = Get-Content -Raw -LiteralPath $backup
            Set-Content -LiteralPath $script:settings -Value '{"model":"opus"}'
            Update-ClaudeCodeMarkplaneHooks -SettingsPath $script:settings -HookScriptPath $script:hook -MarkplaneExePath $script:exe
            (Get-Content -Raw -LiteralPath $backup) | Should Be $before
        }
    }
}
