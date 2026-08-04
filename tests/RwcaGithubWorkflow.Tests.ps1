$repoRoot = Split-Path -Parent $PSScriptRoot

Describe "Research With Coding Agents GitHub project files" {
    It "ships Windows release and repository hygiene workflows" {
        foreach ($relativePath in @(
            ".github\workflows\windows-release.yml",
            ".github\workflows\repo-hygiene.yml",
            ".github\ISSUE_TEMPLATE\bug_report.yml",
            ".github\ISSUE_TEMPLATE\feature_request.yml",
            ".github\pull_request_template.md"
        )) {
            Test-Path -LiteralPath (Join-Path $repoRoot $relativePath) -PathType Leaf | Should Be $true
        }
    }

    It "uses local release verification commands" {
        $releaseWorkflow = Get-Content -Raw -LiteralPath (Join-Path $repoRoot ".github\workflows\windows-release.yml")
        $hygieneWorkflow = Get-Content -Raw -LiteralPath (Join-Path $repoRoot ".github\workflows\repo-hygiene.yml")

        $releaseWorkflow | Should Match "Invoke-Pester"
        $releaseWorkflow | Should Match "Build-RwcaRelease.ps1"
        $releaseWorkflow | Should Match "windows-latest"
        $hygieneWorkflow | Should Match "Test-RwcaDistributionReadiness.ps1"
        $hygieneWorkflow | Should Match "THIRD_PARTY_NOTICES.md"
    }
}
