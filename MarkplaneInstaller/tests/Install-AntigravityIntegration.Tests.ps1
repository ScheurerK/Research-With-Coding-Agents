$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$installer = Join-Path $root "Install-AntigravityIntegration.ps1"
$workspaceInstaller = Join-Path $root "Install-AntigravityWorkspace.ps1"
$hookScript = Join-Path $root "hooks\Invoke-MarkplaneAntigravityHook.ps1"
$skills = Join-Path $root "skills"
$hint = Join-Path $root "research-checkpoint-agents-extension.txt"
$healthCheck = Join-Path $root "Test-MarkplaneAgentSkills.ps1"

function Get-RecursiveHashManifest {
    param([Parameter(Mandatory = $true)][string]$Root)

    $resolvedRoot = (Resolve-Path -LiteralPath $Root).Path
    return @(
        Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File |
            Sort-Object FullName |
            ForEach-Object {
                $relative = $_.FullName.Substring($resolvedRoot.Length).TrimStart('\')
                "{0}|{1}" -f $relative, (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
            }
    )
}

Describe "Antigravity Gemini integration" {
    It "ships the installer and hook adapter" {
        (Test-Path -LiteralPath $installer -PathType Leaf) | Should Be $true
        (Test-Path -LiteralPath $workspaceInstaller -PathType Leaf) | Should Be $true
        (Test-Path -LiteralPath $hookScript -PathType Leaf) | Should Be $true
    }

    It "teaches using-superpowers when to read Antigravity tool mappings" {
        $content = Get-Content -Raw -LiteralPath (Join-Path $root "skills\using-superpowers\SKILL.md")
        $content | Should Match "references/antigravity-tools.md"
        $content | Should Match "Antigravity"
    }
    It "declares Research With Coding Agents Superpowers as authoritative for Gemini Antigravity" {
        $content = Get-Content -Raw -LiteralPath $installer
        $content | Should Match "Research With Coding Agents"
        $content | Should Match "bundled customized Superpowers"
        $content | Should Match "authoritative"
        $content | Should Match "foreign Superpowers"
        $content | Should Match "SUPERPOWERS_DISABLE_TELEMETRY"
    }

    It "includes Antigravity integration in both Windows installers" {
        foreach ($iss in @("MarkplaneInstaller.iss", "MarkplaneAgentInstaller.iss")) {
            $content = Get-Content -Raw -LiteralPath (Join-Path $root $iss)
            $content | Should Match "Install-AntigravityIntegration.ps1"
            $content | Should Match "Install-AntigravityWorkspace.ps1"
            $content | Should Match "Invoke-MarkplaneAntigravityHook.ps1"
            $content | Should Match "Configure Antigravity Gemini integration"
            $content | Should Match "RemoveMarkplaneAntigravityIntegration"
        }
    }

    It "preserves unrelated top-level hooks configuration across repeated installation" {
        $profile = Join-Path $TestDrive "hooks-profile"
        $installDir = Join-Path $TestDrive "MarkplaneHooks"
        New-Item -ItemType Directory -Force -Path (Join-Path $installDir "hooks") | Out-Null
        Copy-Item -LiteralPath $hookScript -Destination (Join-Path $installDir "hooks\Invoke-MarkplaneAntigravityHook.ps1")
        Set-Content -LiteralPath (Join-Path $installDir "markplane.exe") -Value "fake"
        $hooksPath = Join-Path $profile ".gemini\config\hooks.json"
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $hooksPath) | Out-Null
        Set-Content -LiteralPath $hooksPath -Value (@{
            foreign = @{
                PostToolUse = @(@{
                    matcher = "foreign_tool"
                    hooks = @(@{ command = "foreign-hook.exe" })
                })
            }
        } | ConvertTo-Json -Depth 10)

        $oldUserProfile = $env:USERPROFILE
        try {
            $env:USERPROFILE = $profile
            foreach ($run in 1..2) {
                & $installer -InstallDir $installDir -SkillSourceRoot $skills -AgentsHintPath $hint -SkipTelemetry
                $LASTEXITCODE | Should Be 0

                $hooks = Get-Content -Raw -LiteralPath $hooksPath | ConvertFrom-Json
                $hooks.foreign.PostToolUse[0].matcher | Should Be "foreign_tool"
                $hooks.foreign.PostToolUse[0].hooks[0].command | Should Be "foreign-hook.exe"
                $hooks.markplane.PreInvocation.Count | Should Be 1
            }
        } finally {
            $env:USERPROFILE = $oldUserProfile
        }
    }
    It "installs plugin skills, rules, hooks, and visuals without active global project-scoped MCP" {
        $profile = Join-Path $TestDrive "profile"
        $installDir = Join-Path $TestDrive "Markplane"
        New-Item -ItemType Directory -Force -Path (Join-Path $installDir "hooks") | Out-Null
        Copy-Item -LiteralPath $hookScript -Destination (Join-Path $installDir "hooks\Invoke-MarkplaneAntigravityHook.ps1")
        Set-Content -LiteralPath (Join-Path $installDir "markplane.exe") -Value "fake"
        New-Item -ItemType Directory -Force -Path (Join-Path $profile ".gemini\config") | Out-Null
        Set-Content -LiteralPath (Join-Path $profile ".gemini\GEMINI.md") -Value @("# External Gemini guidance", "", "Keep this user-authored instruction.")
        Set-Content -LiteralPath (Join-Path $profile ".gemini\config\mcp_config.json") -Value (@{
            mcpServers = @{
                "matlab-mcp" = @{
                    command = "matlab.exe"
                    args = @("--matlab-root=C:\Program Files\MATLAB")
                }
                markplane = @{
                    command = "old-markplane.exe"
                    args = @("mcp")
                }
            }
        } | ConvertTo-Json -Depth 10)

        $oldUserProfile = $env:USERPROFILE
        try {
            $env:USERPROFILE = $profile
            & $installer -InstallDir $installDir -SkillSourceRoot $skills -AgentsHintPath $hint -SkipTelemetry

            $pluginRoot = Join-Path $profile ".gemini\config\plugins\markplane"
            $staleSkill = Join-Path $pluginRoot "skills\stale-upstream-copy"
            New-Item -ItemType Directory -Force -Path $staleSkill | Out-Null
            Set-Content -LiteralPath (Join-Path $staleSkill "SKILL.md") -Value "stale"

            & $installer -InstallDir $installDir -SkillSourceRoot $skills -AgentsHintPath $hint -SkipTelemetry
            $LASTEXITCODE | Should Be 0

            (Test-Path -LiteralPath $staleSkill) | Should Be $false
            $mappingRulePath = Join-Path $pluginRoot "rules\superpowers-antigravity.md"
            (Test-Path -LiteralPath $mappingRulePath -PathType Leaf) | Should Be $true
            $mappingRule = Get-Content -Raw -LiteralPath $mappingRulePath
            $mappingRule | Should Match "invoke_subagent"
            $mappingRule | Should Match 'TypeName.*self'
            $mappingRule | Should Match 'TypeName.*research'
            $mappingRule | Should Match 'ArtifactType.*task'
            $mappingRule | Should Match "manage_task"

            (Test-Path -LiteralPath (Join-Path $pluginRoot "plugin.json") -PathType Leaf) | Should Be $true
            (Test-Path -LiteralPath (Join-Path $pluginRoot "skills\using-superpowers\SKILL.md") -PathType Leaf) | Should Be $true
            (Test-Path -LiteralPath (Join-Path $pluginRoot "rules\markplane-router.md") -PathType Leaf) | Should Be $true
            (Test-Path -LiteralPath (Join-Path $pluginRoot "rules\markplane-visuals.md") -PathType Leaf) | Should Be $true
            (Test-Path -LiteralPath (Join-Path $pluginRoot "rules\markplane-mcp.md") -PathType Leaf) | Should Be $true

            $visualsRule = Get-Content -Raw -LiteralPath (Join-Path $pluginRoot "rules\markplane-visuals.md")
            $visualsRule | Should Match "markplane-vscode-0\.1\.2\.vsix"
            $visualsRule | Should Match "--install-extension <vsix> --force"
            $visualsRule | Should Match "Developer: Reload Window"
            $visualsRule | Should Match "markplane serve"
            $visualsRule | Should Not Match "extension root"
            $visualsRule | Should Not Match "places the Markplane activity-bar extension"

            $authoritativeSuperpowersSection = @'
## Authoritative Superpowers bundle

Research With Coding Agents bundled customized Superpowers is authoritative for Gemini/Antigravity. The Superpowers skills bundled inside the Markplane plugin are authoritative. Load `using-superpowers` and every selected Superpowers skill from that plugin. Preserve any foreign Superpowers installation and same-named external copies, but do not prefer them over the Research With Coding Agents bundle. Preserve but do not prefer same-named external copies. You must not fetch, install, or upgrade Superpowers from the internet. Keep SUPERPOWERS_DISABLE_TELEMETRY=1 for managed sessions.
'@
            $routerRule = Get-Content -Raw -LiteralPath (Join-Path $pluginRoot "rules\markplane-router.md")
            $routerRule.Contains($authoritativeSuperpowersSection) | Should Be $true

            $gemini = Get-Content -Raw -LiteralPath (Join-Path $profile ".gemini\GEMINI.md")
            $gemini | Should Match "Keep this user-authored instruction"
            $gemini.Contains($authoritativeSuperpowersSection) | Should Be $true
            @([regex]::Matches($gemini, "At the start of every main-agent turn")).Count | Should Be 1
            $gemini | Should Match "Markplane visuals"
            $gemini | Should Match "markplane serve"
            $gemini | Should Match "Install-AntigravityWorkspace.ps1"
            $gemini | Should Match "Markplane plugin.*authoritative"
            $gemini | Should Match "must not fetch, install, or upgrade Superpowers"

            $sourceFiles = @(Get-ChildItem -LiteralPath $skills -Recurse -File)
            $installedFiles = @(Get-ChildItem -LiteralPath (Join-Path $pluginRoot "skills") -Recurse -File)
            $installedFiles.Count | Should Be $sourceFiles.Count
            foreach ($sourceFile in $sourceFiles) {
                $relative = $sourceFile.FullName.Substring($skills.Length).TrimStart('\')
                $installedFile = Join-Path (Join-Path $pluginRoot "skills") $relative
                (Test-Path -LiteralPath $installedFile -PathType Leaf) | Should Be $true
                (Get-FileHash -Algorithm SHA256 -LiteralPath $installedFile).Hash |
                    Should Be (Get-FileHash -Algorithm SHA256 -LiteralPath $sourceFile.FullName).Hash
            }


            $mcpRule = Get-Content -Raw -LiteralPath (Join-Path $pluginRoot "rules\markplane-mcp.md")
            $mcpRule | Should Match "Install-AntigravityWorkspace.ps1"
            $mcpRule | Should Match "\.agents\\mcp_config\.json"
            $mcpRule | Should Match "--project"


            $mcp = Get-Content -Raw -LiteralPath (Join-Path $profile ".gemini\config\mcp_config.json") | ConvertFrom-Json
            $mcp.mcpServers.PSObject.Properties["markplane"] | Should BeNullOrEmpty
            $mcp.mcpServers."matlab-mcp".command | Should Be "matlab.exe"

            $hooksJson = Get-Content -Raw -LiteralPath (Join-Path $profile ".gemini\config\hooks.json") | ConvertFrom-Json
            $hooksJson.markplane.PreInvocation.Count | Should Be 1
            $hooksJson.markplane.PostToolUse.Count | Should Be 1
            $hooksJson.markplane.Stop.Count | Should Be 1
            $hooksJson.markplane.PreInvocation[0].command | Should Match "Invoke-MarkplaneAntigravityHook.ps1"
            $hooksJson.markplane.PreInvocation[0].PSObject.Properties["hooks"] | Should BeNullOrEmpty
            $hooksJson.markplane.PostToolUse[0].matcher | Should Match "write_to_file"
            $hooksJson.markplane.PostToolUse[0].hooks[0].command | Should Match "Invoke-MarkplaneAntigravityHook.ps1"
            $hooksJson.markplane.Stop[0].command | Should Match "Invoke-MarkplaneAntigravityHook.ps1"
            $hooksJson.markplane.Stop[0].PSObject.Properties["hooks"] | Should BeNullOrEmpty

            $geminiRoot = Join-Path $profile ".gemini"
            & $healthCheck -SkipCodex -SkipClaude -GeminiRoot $geminiRoot -SkillSourceRoot $skills -SkipTelemetry
            $LASTEXITCODE | Should Be 0

            $geminiPath = Join-Path $geminiRoot "GEMINI.md"
            $healthyGemini = [System.IO.File]::ReadAllText($geminiPath)
            $driftedGemini = $healthyGemini.Replace(
                "The Superpowers skills bundled inside the Markplane plugin are authoritative.",
                "The Superpowers skills bundled inside the Markplane plugin are available."
            )
            [System.IO.File]::WriteAllText($geminiPath, $driftedGemini, [System.Text.UTF8Encoding]::new($false))
            $authoritativeDriftOutput = (& $healthCheck -SkipCodex -SkipClaude -GeminiRoot $geminiRoot -SkillSourceRoot $skills -SkipTelemetry 6>&1) | Out-String
            $LASTEXITCODE | Should Be 1
            $authoritativeDriftOutput | Should Match "authoritative"
            [System.IO.File]::WriteAllText($geminiPath, $healthyGemini, [System.Text.UTF8Encoding]::new($false))

            $hooksPath = Join-Path $geminiRoot "config\hooks.json"
            $healthyHooks = [System.IO.File]::ReadAllText($hooksPath)

            $driftedHooks = $healthyHooks | ConvertFrom-Json
            $preHandler = $driftedHooks.markplane.PreInvocation[0]
            $driftedHooks.markplane.PreInvocation = @([pscustomobject]@{ matcher = "*"; hooks = @($preHandler) })
            Set-Content -LiteralPath $hooksPath -Value ($driftedHooks | ConvertTo-Json -Depth 100)
            $preDriftOutput = (& $healthCheck -SkipCodex -SkipClaude -GeminiRoot $geminiRoot -SkillSourceRoot $skills -SkipTelemetry 6>&1) | Out-String
            $LASTEXITCODE | Should Be 1
            $preDriftOutput | Should Match "PreInvocation"
            [System.IO.File]::WriteAllText($hooksPath, $healthyHooks, [System.Text.UTF8Encoding]::new($false))

            $driftedHooks = $healthyHooks | ConvertFrom-Json
            $stopHandler = $driftedHooks.markplane.Stop[0]
            $driftedHooks.markplane.Stop = @([pscustomobject]@{ matcher = "*"; hooks = @($stopHandler) })
            Set-Content -LiteralPath $hooksPath -Value ($driftedHooks | ConvertTo-Json -Depth 100)
            $stopDriftOutput = (& $healthCheck -SkipCodex -SkipClaude -GeminiRoot $geminiRoot -SkillSourceRoot $skills -SkipTelemetry 6>&1) | Out-String
            $LASTEXITCODE | Should Be 1
            $stopDriftOutput | Should Match "Stop"
            [System.IO.File]::WriteAllText($hooksPath, $healthyHooks, [System.Text.UTF8Encoding]::new($false))

            $driftedHooks = $healthyHooks | ConvertFrom-Json
            $postHandler = $driftedHooks.markplane.PostToolUse[0].hooks[0]
            $driftedHooks.markplane.PostToolUse = @($postHandler)
            Set-Content -LiteralPath $hooksPath -Value ($driftedHooks | ConvertTo-Json -Depth 100)
            $postDriftOutput = (& $healthCheck -SkipCodex -SkipClaude -GeminiRoot $geminiRoot -SkillSourceRoot $skills -SkipTelemetry 6>&1) | Out-String
            $LASTEXITCODE | Should Be 1
            $postDriftOutput | Should Match "PostToolUse"
            [System.IO.File]::WriteAllText($hooksPath, $healthyHooks, [System.Text.UTF8Encoding]::new($false))

            $externalRoots = @(
                (Join-Path $geminiRoot "config\skills"),
                (Join-Path $geminiRoot "skills"),
                (Join-Path $geminiRoot "config\plugins\upstream-superpowers\skills")
            )
            foreach ($externalRoot in $externalRoots) {
                $externalRouter = Join-Path $externalRoot "using-superpowers"
                New-Item -ItemType Directory -Force -Path $externalRouter | Out-Null
                Set-Content -LiteralPath (Join-Path $externalRouter "SKILL.md") -Value "external"
            }

            $warningOutput = (& $healthCheck -SkipCodex -SkipClaude -GeminiRoot $geminiRoot -SkillSourceRoot $skills -SkipTelemetry) | Out-String
            $LASTEXITCODE | Should Be 0
            $warningOutput | Should Match "same-named external skill"
            foreach ($externalRoot in $externalRoots) {
                $warningOutput | Should Match ([regex]::Escape($externalRoot))
            }

            $installedRouter = Join-Path $geminiRoot "config\plugins\markplane\skills\using-superpowers\SKILL.md"
            Add-Content -LiteralPath $installedRouter -Value "drift"
            & powershell.exe -NoProfile -File $healthCheck -SkipCodex -SkipClaude -GeminiRoot $geminiRoot -SkillSourceRoot $skills -SkipTelemetry
            $LASTEXITCODE | Should Be 1

            & $installer -InstallDir $installDir -SkillSourceRoot $skills -AgentsHintPath $hint -SkipTelemetry
            $missingOwnedFile = Join-Path $geminiRoot "config\plugins\markplane\skills\using-superpowers\SKILL.md"
            Remove-Item -LiteralPath $missingOwnedFile
            $missingOutput = (& $healthCheck -SkipCodex -SkipClaude -GeminiRoot $geminiRoot -SkillSourceRoot $skills -SkipTelemetry 6>&1) | Out-String
            $LASTEXITCODE | Should Be 1
            $missingOutput | Should Match "Gemini Markplane plugin skills is missing file:"

            & $installer -InstallDir $installDir -SkillSourceRoot $skills -AgentsHintPath $hint -SkipTelemetry
            $extraOwnedFile = Join-Path $geminiRoot "config\plugins\markplane\skills\using-superpowers\external-owned-file.md"
            Set-Content -LiteralPath $extraOwnedFile -Value "extra"
            $extraOutput = (& $healthCheck -SkipCodex -SkipClaude -GeminiRoot $geminiRoot -SkillSourceRoot $skills -SkipTelemetry 6>&1) | Out-String
            $LASTEXITCODE | Should Be 1
            $extraOutput | Should Match "Gemini Markplane plugin skills has extra file:"

            & $installer -InstallDir $installDir -SkillSourceRoot $skills -AgentsHintPath $hint -SkipTelemetry
            $finalWarningOutput = (& $healthCheck -SkipCodex -SkipClaude -GeminiRoot $geminiRoot -SkillSourceRoot $skills -SkipTelemetry) | Out-String
            $LASTEXITCODE | Should Be 0
            foreach ($externalRoot in $externalRoots) {
                (Test-Path -LiteralPath (Join-Path $externalRoot "using-superpowers\SKILL.md") -PathType Leaf) | Should Be $true
                $finalWarningOutput | Should Match ([regex]::Escape($externalRoot))
            }
        } finally {
            $env:USERPROFILE = $oldUserProfile
        }
    }

    It "fails missing mapping preflight without mutating an existing plugin tree" {
        $profile = Join-Path $TestDrive "preflight-profile"
        $installDir = Join-Path $TestDrive "MarkplanePreflight"
        New-Item -ItemType Directory -Force -Path (Join-Path $installDir "hooks") | Out-Null
        Copy-Item -LiteralPath $hookScript -Destination (Join-Path $installDir "hooks\Invoke-MarkplaneAntigravityHook.ps1")
        Set-Content -LiteralPath (Join-Path $installDir "markplane.exe") -Value "fake"
        New-Item -ItemType Directory -Force -Path (Join-Path $profile ".gemini") | Out-Null
        Set-Content -LiteralPath (Join-Path $profile ".gemini\GEMINI.md") -Value "User-authored Gemini content."

        $oldUserProfile = $env:USERPROFILE
        try {
            $env:USERPROFILE = $profile
            & $installer -InstallDir $installDir -SkillSourceRoot $skills -AgentsHintPath $hint -SkipTelemetry
            $LASTEXITCODE | Should Be 0

            $pluginRoot = Join-Path $profile ".gemini\config\plugins\markplane"
            $manifestBefore = (Get-RecursiveHashManifest -Root $pluginRoot) -join [Environment]::NewLine
            $geminiPath = Join-Path $profile ".gemini\GEMINI.md"
            $geminiBefore = [System.IO.File]::ReadAllText($geminiPath)

            $brokenSkills = Join-Path $TestDrive "skills-without-mapping"
            Copy-Item -LiteralPath $skills -Destination $brokenSkills -Recurse
            $missingMapping = Join-Path $brokenSkills "using-superpowers\references\antigravity-tools.md"
            Remove-Item -LiteralPath $missingMapping -Force

            $thrown = $null
            try {
                & $installer -InstallDir $installDir -SkillSourceRoot $brokenSkills -AgentsHintPath $hint -SkipTelemetry
            } catch {
                $thrown = $_
            }

            $thrown | Should Not BeNullOrEmpty
            $thrown.Exception.Message | Should Match ([regex]::Escape($missingMapping))
            ((Get-RecursiveHashManifest -Root $pluginRoot) -join [Environment]::NewLine) | Should Be $manifestBefore
            [System.IO.File]::ReadAllText($geminiPath) | Should Be $geminiBefore
            $geminiBefore | Should Match "User-authored Gemini content"
        } finally {
            $env:USERPROFILE = $oldUserProfile
        }
    }

    It "uninstalls only Markplane Antigravity entries" {
        $profile = Join-Path $TestDrive "uninstall-profile"
        $installDir = Join-Path $TestDrive "Markplane2"
        New-Item -ItemType Directory -Force -Path (Join-Path $installDir "hooks") | Out-Null
        Copy-Item -LiteralPath $hookScript -Destination (Join-Path $installDir "hooks\Invoke-MarkplaneAntigravityHook.ps1")
        Set-Content -LiteralPath (Join-Path $installDir "markplane.exe") -Value "fake"
        New-Item -ItemType Directory -Force -Path (Join-Path $profile ".gemini\config") | Out-Null
        Set-Content -LiteralPath (Join-Path $profile ".gemini\GEMINI.md") -Value @("# External Gemini guidance", "", "Keep this user-authored instruction.")
        Set-Content -LiteralPath (Join-Path $profile ".gemini\config\mcp_config.json") -Value (@{
            mcpServers = @{
                foreign = @{
                    command = "foreign-mcp.exe"
                    args = @("serve")
                }
                markplane = @{
                    command = "old-markplane.exe"
                    args = @("mcp")
                }
            }
        } | ConvertTo-Json -Depth 10)

        $oldUserProfile = $env:USERPROFILE
        try {
            $env:USERPROFILE = $profile
            & $installer -InstallDir $installDir -SkillSourceRoot $skills -AgentsHintPath $hint -SkipTelemetry

            $hooksPath = Join-Path $profile ".gemini\config\hooks.json"
            $hooks = Get-Content -Raw -LiteralPath $hooksPath | ConvertFrom-Json
            Add-Member -InputObject $hooks -NotePropertyName "foreign" -NotePropertyValue ([pscustomobject]@{
                Stop = @([pscustomobject]@{ hooks = @([pscustomobject]@{ command = "foreign.exe" }) })
            }) -Force
            Set-Content -LiteralPath $hooksPath -Value ($hooks | ConvertTo-Json -Depth 100)

            & $installer -InstallDir $installDir -SkillSourceRoot $skills -AgentsHintPath $hint -Uninstall
            $LASTEXITCODE | Should Be 0

            (Test-Path -LiteralPath (Join-Path $profile ".gemini\config\plugins\markplane")) | Should Be $false
            $remainingHooks = Get-Content -Raw -LiteralPath $hooksPath | ConvertFrom-Json
            $remainingHooks.PSObject.Properties["markplane"] | Should BeNullOrEmpty
            $remainingHooks.foreign.Stop[0].hooks[0].command | Should Be "foreign.exe"
            $mcp = Get-Content -Raw -LiteralPath (Join-Path $profile ".gemini\config\mcp_config.json") | ConvertFrom-Json
            $mcp.mcpServers.PSObject.Properties["markplane"] | Should BeNullOrEmpty
            $mcp.mcpServers.foreign.command | Should Be "foreign-mcp.exe"
        } finally {
            $env:USERPROFILE = $oldUserProfile
        }
    }

    It "writes project-local Antigravity MCP with cwd and explicit --project" {
        $project = Join-Path $TestDrive "project"
        $installDir = Join-Path $TestDrive "Markplane3"
        New-Item -ItemType Directory -Force -Path (Join-Path $project ".markplane") | Out-Null
        New-Item -ItemType Directory -Force -Path (Join-Path $project ".agents") | Out-Null
        New-Item -ItemType Directory -Force -Path $installDir | Out-Null
        $markplaneExe = Join-Path $installDir "markplane.exe"
        Set-Content -LiteralPath $markplaneExe -Value "fake"
        Set-Content -LiteralPath (Join-Path $project ".agents\mcp_config.json") -Value (@{
            mcpServers = @{
                foreign = @{
                    command = "foreign.exe"
                    args = @("serve")
                }
            }
        } | ConvertTo-Json -Depth 10)

        & $workspaceInstaller -ProjectRoot $project -MarkplaneExe $markplaneExe
        & $workspaceInstaller -ProjectRoot $project -MarkplaneExe $markplaneExe
        $LASTEXITCODE | Should Be 0

        $config = Get-Content -Raw -LiteralPath (Join-Path $project ".agents\mcp_config.json") | ConvertFrom-Json
        $config.mcpServers.markplane.command | Should Be $markplaneExe
        @($config.mcpServers.markplane.args)[0] | Should Be "mcp"
        @($config.mcpServers.markplane.args)[1] | Should Be "--project"
        @($config.mcpServers.markplane.args)[2] | Should Be $project
        $config.mcpServers.markplane.cwd | Should Be $project
        $config.mcpServers.foreign.command | Should Be "foreign.exe"

        & $workspaceInstaller -ProjectRoot $project -MarkplaneExe $markplaneExe -Uninstall
        $LASTEXITCODE | Should Be 0
        $after = Get-Content -Raw -LiteralPath (Join-Path $project ".agents\mcp_config.json") | ConvertFrom-Json
        $after.mcpServers.PSObject.Properties["markplane"] | Should BeNullOrEmpty
        $after.mcpServers.foreign.command | Should Be "foreign.exe"
    }
}



