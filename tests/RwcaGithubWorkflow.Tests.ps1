Describe "Research With Coding Agents GitHub project files" {
    BeforeAll {
        $script:repoRoot = (Get-Location).Path
        if (-not (Test-Path -LiteralPath (Join-Path $script:repoRoot "README.md") -PathType Leaf)) {
            $script:repoRoot = Split-Path -Parent $PSScriptRoot
        }
    }
    It "ships Windows release and repository hygiene workflows" {
        foreach ($relativePath in @(
            ".github\workflows\windows-release.yml",
            ".github\workflows\repo-hygiene.yml",
            ".github\dependabot.yml",
            ".github\ISSUE_TEMPLATE\bug_report.yml",
            ".github\ISSUE_TEMPLATE\feature_request.yml",
            ".github\pull_request_template.md"
        )) {
            Test-Path -LiteralPath (Join-Path $script:repoRoot $relativePath) -PathType Leaf | Should Be $true
        }
    }

    It "uses local release verification commands" {
        $releaseWorkflow = Get-Content -Raw -LiteralPath (Join-Path $script:repoRoot ".github\workflows\windows-release.yml")
        $hygieneWorkflow = Get-Content -Raw -LiteralPath (Join-Path $script:repoRoot ".github\workflows\repo-hygiene.yml")

        $releaseWorkflow | Should Match "Install-Module Pester -RequiredVersion 3\.4\.0"
        $releaseWorkflow | Should Match "Import-Module Pester -RequiredVersion 3\.4\.0"
        $releaseWorkflow | Should Match "Invoke-Pester"
        $releaseWorkflow | Should Match "-PassThru"
        $releaseWorkflow | Should Match "FailedCount"
        $releaseWorkflow | Should Match "Build-RwcaRelease.ps1"
        $releaseWorkflow | Should Match "windows-latest"
        $hygieneWorkflow | Should Match "Install-Module Pester -RequiredVersion 3\.4\.0"
        $hygieneWorkflow | Should Match "Import-Module Pester -RequiredVersion 3\.4\.0"
        $hygieneWorkflow | Should Match "-PassThru"
        $hygieneWorkflow | Should Match "FailedCount"
        $hygieneWorkflow | Should Match "Test-RwcaDistributionReadiness.ps1"
        $hygieneWorkflow | Should Match "THIRD_PARTY_NOTICES.md"
    }

    It "configures Dependabot for active dependency manifests" {
        $dependabotPath = Join-Path $script:repoRoot ".github\dependabot.yml"
        Test-Path -LiteralPath $dependabotPath -PathType Leaf | Should Be $true

        $dependabot = Get-Content -Raw -LiteralPath $dependabotPath
        $dependabot | Should Match "version:\s+2"
        $dependabot | Should Match 'package-ecosystem:\s+"npm"'
        $dependabot | Should Match 'directory:\s+"/components/markplane/crates/markplane-web/ui"'
        $dependabot | Should Match 'package-ecosystem:\s+"cargo"'
        $dependabot | Should Match 'directory:\s+"/components/markplane"'
        $dependabot | Should Match 'package-ecosystem:\s+"github-actions"'
        $dependabot | Should Match 'directory:\s+"/"'
        $dependabot | Should Match "security-updates"
    }
}
