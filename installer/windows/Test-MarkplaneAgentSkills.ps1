[CmdletBinding()]
param(
    [string]$CodexRoot = (Join-Path $env:USERPROFILE ".codex"),
    [string]$ClaudeRoot = (Join-Path $env:USERPROFILE ".claude"),
    [string]$GeminiRoot = (Join-Path $env:USERPROFILE ".gemini"),
    [string]$SkillSourceRoot,
    [switch]$SkipCodex,
    [switch]$SkipClaude,
    [switch]$SkipAntigravity,
    [switch]$SkipTelemetry
)

$ErrorActionPreference = "Stop"

function Get-ScriptDirectory {
    if ($PSScriptRoot) { return $PSScriptRoot }
    return (Get-Location).Path
}

if (-not $SkillSourceRoot) {
    $SkillSourceRoot = Join-Path (Get-ScriptDirectory) "skills"
}

$isInProcessInvocation = $MyInvocation.InvocationName -in @("&", ".")

$requiredHintPatterns = @(
    'At the start of every main-agent turn, first load `using-superpowers`',
    'before file reads, tool calls, planning, clarification questions, or implementation',
    'does not apply to narrow subagents',
    'compact task contract'
)

$requiredRouterPatterns = @(
    'name: using-superpowers',
    'Before any response or action:',
    'If dispatched as a subagent for a narrow task, stop using this skill.'
)

$requiredGeminiAuthoritativePatterns = @(
    '## Authoritative Superpowers bundle',
    'The Superpowers skills bundled inside the Markplane plugin are authoritative.',
    'every selected Superpowers skill from that plugin',
    'Preserve but do not prefer same-named external copies.',
    'You must not fetch, install, or upgrade Superpowers from the internet.'
)

function Read-TextOrNull {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }
    return [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($false))
}

function Add-MissingPatternIssues {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [AllowNull()][string]$Text,
        [Parameter(Mandatory = $true)][string[]]$Patterns,
        [System.Collections.ArrayList]$Issues
    )

    if ($null -eq $Text) {
        [void]$Issues.Add("Missing $Label")
        return
    }

    foreach ($pattern in $Patterns) {
        if ($Text.IndexOf($pattern, [System.StringComparison]::Ordinal) -lt 0) {
            [void]$Issues.Add("$Label does not contain: $pattern")
        }
    }
}

function Add-DirectAntigravityHookIssues {
    param(
        [Parameter(Mandatory = $true)][string]$Event,
        $Entries,
        [System.Collections.ArrayList]$Issues
    )

    $handlers = @($Entries)
    if ($handlers.Count -ne 1) {
        [void]$Issues.Add("Gemini hooks.json markplane.$Event must contain exactly one direct command handler")
        return
    }

    $handler = $handlers[0]
    $command = if ($null -ne $handler) { [string]$handler.command } else { "" }
    if ($null -eq $handler -or
        $handler.PSObject.Properties["hooks"] -or
        [string]$handler.type -ne "command" -or
        [string]::IsNullOrWhiteSpace($command) -or
        $command.IndexOf("Invoke-MarkplaneAntigravityHook.ps1", [System.StringComparison]::OrdinalIgnoreCase) -lt 0 -or
        $command.IndexOf("-Event $Event", [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        [void]$Issues.Add("Gemini hooks.json markplane.$Event must use a direct Invoke-MarkplaneAntigravityHook.ps1 command handler")
    }
}

function Add-MatchedAntigravityPostToolUseIssues {
    param(
        $Entries,
        [System.Collections.ArrayList]$Issues
    )

    $wrappers = @($Entries)
    if ($wrappers.Count -ne 1) {
        [void]$Issues.Add("Gemini hooks.json markplane.PostToolUse must contain exactly one matcher entry")
        return
    }

    $wrapper = $wrappers[0]
    $matcher = if ($null -ne $wrapper) { [string]$wrapper.matcher } else { "" }
    if ($null -eq $wrapper -or
        $wrapper.PSObject.Properties["command"] -or
        [string]::IsNullOrWhiteSpace($matcher) -or
        -not $wrapper.PSObject.Properties["hooks"]) {
        [void]$Issues.Add("Gemini hooks.json markplane.PostToolUse must use a matcher with nested hooks")
        return
    }

    foreach ($requiredMatcherText in @("write_to_file", "replace_file_content", "multi_replace_file_content", "run_command", "mcp_.*markplane.*")) {
        if ($matcher.IndexOf($requiredMatcherText, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            [void]$Issues.Add("Gemini hooks.json markplane.PostToolUse matcher does not contain: $requiredMatcherText")
        }
    }
    Add-DirectAntigravityHookIssues -Event "PostToolUse" -Entries $wrapper.hooks -Issues $Issues
}

function Get-TreeManifest {
    param([Parameter(Mandatory = $true)][string]$Root)
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) { return $null }
    $resolved = (Resolve-Path -LiteralPath $Root).Path
    $manifest = @{}
    foreach ($file in Get-ChildItem -LiteralPath $resolved -Recurse -File) {
        $relative = $file.FullName.Substring($resolved.Length).TrimStart('\')
        $manifest[$relative] = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
    }
    return $manifest
}

function Add-TreeParityIssues {
    param([string]$Label, [string]$ExpectedRoot, [string]$ActualRoot, [System.Collections.ArrayList]$Issues)
    $expected = Get-TreeManifest -Root $ExpectedRoot
    $actual = Get-TreeManifest -Root $ActualRoot
    if ($null -eq $expected) { [void]$Issues.Add("Missing $Label source: $ExpectedRoot"); return }
    if ($null -eq $actual) { [void]$Issues.Add("Missing $Label installation: $ActualRoot"); return }
    foreach ($path in @($expected.Keys + $actual.Keys | Sort-Object -Unique)) {
        if (-not $expected.ContainsKey($path)) { [void]$Issues.Add("$Label has extra file: $path") }
        elseif (-not $actual.ContainsKey($path)) { [void]$Issues.Add("$Label is missing file: $path") }
        elseif ($expected[$path] -ne $actual[$path]) { [void]$Issues.Add("$Label differs: $path") }
    }
}

$issues = New-Object System.Collections.ArrayList
$warnings = New-Object System.Collections.ArrayList

$codexAgentsPath = Join-Path $CodexRoot "AGENTS.md"
$claudeAgentsPath = Join-Path $ClaudeRoot "CLAUDE.md"
$codexRouterPath = Join-Path $CodexRoot "skills\using-superpowers\SKILL.md"
$claudeRouterPath = Join-Path $ClaudeRoot "skills\using-superpowers\SKILL.md"
$geminiPath = Join-Path $GeminiRoot "GEMINI.md"
$geminiRouterPath = Join-Path $GeminiRoot "config\plugins\markplane\skills\using-superpowers\SKILL.md"
$geminiVisualsPath = Join-Path $GeminiRoot "config\plugins\markplane\rules\markplane-visuals.md"
$geminiMcpPath = Join-Path $GeminiRoot "config\plugins\markplane\rules\markplane-mcp.md"
$geminiAntigravityMappingPath = Join-Path $GeminiRoot "config\plugins\markplane\rules\superpowers-antigravity.md"
$geminiHooksPath = Join-Path $GeminiRoot "config\hooks.json"
$antigravityMappingSourcePath = Join-Path $SkillSourceRoot "using-superpowers\references\antigravity-tools.md"

if (-not $SkipCodex) {
    Add-MissingPatternIssues -Label "Codex AGENTS.md router hint" -Text (Read-TextOrNull -Path $codexAgentsPath) -Patterns $requiredHintPatterns -Issues $issues
    Add-MissingPatternIssues -Label "Codex using-superpowers skill" -Text (Read-TextOrNull -Path $codexRouterPath) -Patterns $requiredRouterPatterns -Issues $issues
}

if (-not $SkipClaude) {
    Add-MissingPatternIssues -Label "Claude CLAUDE.md router hint" -Text (Read-TextOrNull -Path $claudeAgentsPath) -Patterns $requiredHintPatterns -Issues $issues
    Add-MissingPatternIssues -Label "Claude using-superpowers skill" -Text (Read-TextOrNull -Path $claudeRouterPath) -Patterns $requiredRouterPatterns -Issues $issues
}

$shouldCheckAntigravity = -not $SkipAntigravity -and ((Test-Path -LiteralPath $GeminiRoot -PathType Container) -or $PSBoundParameters.ContainsKey("GeminiRoot"))
if ($shouldCheckAntigravity) {
    $geminiInstructions = Read-TextOrNull -Path $geminiPath
    Add-MissingPatternIssues -Label "Gemini GEMINI.md router hint" -Text $geminiInstructions -Patterns $requiredHintPatterns -Issues $issues
    Add-MissingPatternIssues -Label "Gemini GEMINI.md authoritative Superpowers instruction" -Text $geminiInstructions -Patterns $requiredGeminiAuthoritativePatterns -Issues $issues
    Add-MissingPatternIssues -Label "Gemini using-superpowers skill" -Text (Read-TextOrNull -Path $geminiRouterPath) -Patterns $requiredRouterPatterns -Issues $issues
    Add-MissingPatternIssues -Label "Gemini Markplane visuals rule" -Text (Read-TextOrNull -Path $geminiVisualsPath) -Patterns @("Markplane Visuals", "markplane serve", "local Markplane web UI") -Issues $issues
    Add-MissingPatternIssues -Label "Gemini Markplane MCP rule" -Text (Read-TextOrNull -Path $geminiMcpPath) -Patterns @("Markplane Workspace MCP", "Install-AntigravityWorkspace.ps1", "--project") -Issues $issues
    Add-TreeParityIssues -Label "Gemini Markplane plugin skills" -ExpectedRoot $SkillSourceRoot -ActualRoot (Join-Path $GeminiRoot "config\plugins\markplane\skills") -Issues $issues

    $geminiHooks = $null
    if (-not (Test-Path -LiteralPath $geminiHooksPath -PathType Leaf)) {
        [void]$issues.Add("Missing Gemini hooks.json: $geminiHooksPath")
    } else {
        try {
            $geminiHooks = [System.IO.File]::ReadAllText($geminiHooksPath, [System.Text.UTF8Encoding]::new($false)) | ConvertFrom-Json
        } catch {
            [void]$issues.Add("Invalid Gemini hooks.json: $($_.Exception.Message)")
        }
    }
    if ($null -ne $geminiHooks) {
        if (-not $geminiHooks.PSObject.Properties["markplane"]) {
            [void]$issues.Add("Gemini hooks.json is missing the markplane namespace")
        } else {
            Add-DirectAntigravityHookIssues -Event "PreInvocation" -Entries $geminiHooks.markplane.PreInvocation -Issues $issues
            Add-MatchedAntigravityPostToolUseIssues -Entries $geminiHooks.markplane.PostToolUse -Issues $issues
            Add-DirectAntigravityHookIssues -Event "Stop" -Entries $geminiHooks.markplane.Stop -Issues $issues
        }
    }

    if (-not (Test-Path -LiteralPath $antigravityMappingSourcePath -PathType Leaf)) {
        [void]$issues.Add("Missing Gemini Antigravity mapping source: $antigravityMappingSourcePath")
    } elseif (-not (Test-Path -LiteralPath $geminiAntigravityMappingPath -PathType Leaf)) {
        [void]$issues.Add("Missing Gemini Antigravity mapping installation: $geminiAntigravityMappingPath")
    } elseif ((Get-FileHash -Algorithm SHA256 -LiteralPath $antigravityMappingSourcePath).Hash -ne (Get-FileHash -Algorithm SHA256 -LiteralPath $geminiAntigravityMappingPath).Hash) {
        [void]$issues.Add("Gemini Antigravity mapping differs: superpowers-antigravity.md")
    }

    $externalSkillRoots = @(
        (Join-Path $GeminiRoot "config\skills"),
        (Join-Path $GeminiRoot "skills")
    )
    $pluginsRoot = Join-Path $GeminiRoot "config\plugins"
    foreach ($plugin in Get-ChildItem -LiteralPath $pluginsRoot -Directory -ErrorAction SilentlyContinue) {
        if ($plugin.Name -ine "markplane") {
            $pluginSkillsRoot = Join-Path $plugin.FullName "skills"
            if (Test-Path -LiteralPath $pluginSkillsRoot -PathType Container) {
                $externalSkillRoots += $pluginSkillsRoot
            }
        }
    }

    foreach ($externalRoot in $externalSkillRoots) {
        foreach ($skill in Get-ChildItem -LiteralPath $SkillSourceRoot -Directory -ErrorAction SilentlyContinue) {
            if (Test-Path -LiteralPath (Join-Path $externalRoot $skill.Name) -PathType Container) {
                [void]$warnings.Add("Found same-named external skill '$($skill.Name)' in $externalRoot; the Markplane plugin copy remains authoritative.")
            }
        }
    }
}

if (-not $SkipTelemetry) {
    $telemetry = [Environment]::GetEnvironmentVariable("SUPERPOWERS_DISABLE_TELEMETRY", "User")
    if ($telemetry -ne "1" -and $env:SUPERPOWERS_DISABLE_TELEMETRY -ne "1") {
        [void]$issues.Add("SUPERPOWERS_DISABLE_TELEMETRY is not set to 1")
    }
}

foreach ($warning in $warnings) { Write-Output "WARNING: $warning" }

if ($issues.Count -gt 0) {
    Write-Host "Markplane agent skill health check failed:"
    foreach ($issue in $issues) {
        Write-Host "- $issue"
    }
    $global:LASTEXITCODE = 1
    if (-not $isInProcessInvocation) {
        exit 1
    }
    return
}

Write-Host "Markplane agent skill health check passed."
$global:LASTEXITCODE = 0