$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$repoRoot = Split-Path -Parent (Split-Path -Parent $root)
$installer = Join-Path $root "Install-MarkplaneAgentSkills.ps1"
$healthCheck = Join-Path $root "Test-MarkplaneAgentSkills.ps1"
$hint = Join-Path $root "research-checkpoint-agents-extension.txt"
$skills = Join-Path $repoRoot "components\superpowers\skills"

Describe "Agent skill installer" {
    It "uses the default skill source root in a subprocess when all checks are skipped" {
        $fixtureRoot = Join-Path $TestDrive "default-health-check"
        $fixtureHealthCheck = Join-Path $fixtureRoot "Test-MarkplaneAgentSkills.ps1"
        $fixtureSkills = Join-Path $fixtureRoot "skills"

        New-Item -ItemType Directory -Force -Path $fixtureRoot | Out-Null
        Copy-Item -LiteralPath $healthCheck -Destination $fixtureHealthCheck
        Copy-Item -LiteralPath $skills -Destination $fixtureSkills -Recurse

        & powershell.exe -NoProfile -File $fixtureHealthCheck -SkipCodex -SkipClaude -SkipAntigravity -SkipTelemetry

        $LASTEXITCODE | Should Be 0
    }

    It "ships the installer, hint, and health check" {
        (Test-Path -LiteralPath $installer -PathType Leaf) | Should Be $true
        (Test-Path -LiteralPath $hint -PathType Leaf) | Should Be $true
        (Test-Path -LiteralPath $healthCheck -PathType Leaf) | Should Be $true
    }

    It "requires using-superpowers before main-agent actions" {
        $content = Get-Content -Raw -LiteralPath $hint
        $content | Should Match 'At the start of every main-agent turn, first load `using-superpowers`'
        $content | Should Match 'before file reads, tool calls, planning, clarification questions, or implementation'
        $content | Should Match 'does not apply to narrow subagents'
        $content | Should Match 'compact task contract'
    }
    It "declares Research With Coding Agents Superpowers as authoritative for Codex and Claude Code" {
        $content = Get-Content -Raw -LiteralPath $hint
        $content | Should Match "Research With Coding Agents"
        $content | Should Match "bundled customized Superpowers"
        $content | Should Match "authoritative"
        $content | Should Match "foreign Superpowers"
        $content | Should Match "SUPERPOWERS_DISABLE_TELEMETRY=1"
    }

    It "installs hints and passes local health check idempotently" {
        $profile = Join-Path $TestDrive "profile"
        New-Item -ItemType Directory -Force -Path $profile | Out-Null
        $oldUserProfile = $env:USERPROFILE
        try {
            $env:USERPROFILE = $profile
            & $installer -SkillSourceRoot $skills -AgentsHintPath $hint -SkipTelemetry
            & $installer -SkillSourceRoot $skills -AgentsHintPath $hint -SkipTelemetry
            $LASTEXITCODE | Should Be 0

            $codexAgents = Join-Path $profile ".codex\AGENTS.md"
            $claudeAgents = Join-Path $profile ".claude\CLAUDE.md"
            $codexContent = Get-Content -Raw -LiteralPath $codexAgents
            $claudeContent = Get-Content -Raw -LiteralPath $claudeAgents
            @([regex]::Matches($codexContent, "At the start of every main-agent turn")).Count | Should Be 1
            @([regex]::Matches($claudeContent, "At the start of every main-agent turn")).Count | Should Be 1

            & $healthCheck -CodexRoot (Join-Path $profile ".codex") -ClaudeRoot (Join-Path $profile ".claude")
            $LASTEXITCODE | Should Be 0
        } finally {
            $env:USERPROFILE = $oldUserProfile
        }
    }

    It "fails health check when the router hint is missing" {
        $profile = Join-Path $TestDrive "broken-profile"
        New-Item -ItemType Directory -Force -Path (Join-Path $profile ".codex\skills\using-superpowers"), (Join-Path $profile ".claude\skills\using-superpowers") | Out-Null
        Set-Content -LiteralPath (Join-Path $profile ".codex\skills\using-superpowers\SKILL.md") -Value "Before any response or action:"
        Set-Content -LiteralPath (Join-Path $profile ".claude\skills\using-superpowers\SKILL.md") -Value "Before any response or action:"
        Set-Content -LiteralPath (Join-Path $profile ".codex\AGENTS.md") -Value "## Missing router"
        Set-Content -LiteralPath (Join-Path $profile ".claude\CLAUDE.md") -Value "## Missing router"

        & $healthCheck -CodexRoot (Join-Path $profile ".codex") -ClaudeRoot (Join-Path $profile ".claude")
        $LASTEXITCODE | Should Be 1
    }
}

