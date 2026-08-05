Describe "Research With Coding Agents provenance" {
    BeforeAll {
        $script:repoRoot = (Get-Location).Path
        if (-not (Test-Path -LiteralPath (Join-Path $script:repoRoot "README.md") -PathType Leaf)) {
            $script:repoRoot = Split-Path -Parent $PSScriptRoot
        }
        $script:provenanceScript = Join-Path $script:repoRoot "scripts\Get-RwcaProvenance.ps1"
        $script:readinessScript = Join-Path $script:repoRoot "scripts\Test-RwcaDistributionReadiness.ps1"
    }
    It "provides a machine-readable provenance table for shipped components" {
        Test-Path -LiteralPath $script:provenanceScript -PathType Leaf | Should Be $true
        . $script:provenanceScript

        $items = Get-RwcaProvenance -RepoRoot $script:repoRoot
        $names = @($items | ForEach-Object { $_.Name })

        $names -contains "Markplane" | Should Be $true
        $names -contains "Superpowers" | Should Be $true
        $names -contains "Research Repository Governance Skill" | Should Be $true

        foreach ($item in $items) {
            [string]::IsNullOrWhiteSpace($item.UpstreamUrl) | Should Be $false
            [string]::IsNullOrWhiteSpace($item.License) | Should Be $false
            Test-Path -LiteralPath (Join-Path $script:repoRoot $item.LicenseFile) -PathType Leaf | Should Be $true
        }
    }

    It "keeps the required upstream and license declarations" {
        . $script:provenanceScript

        $items = @(Get-RwcaProvenance -RepoRoot $script:repoRoot)
        ($items | Where-Object { $_.Name -eq "Markplane" }).UpstreamUrl | Should Be "https://github.com/zerowand01/markplane"
        ($items | Where-Object { $_.Name -eq "Superpowers" }).UpstreamUrl | Should Be "https://github.com/obra/superpowers"
        ($items | Where-Object { $_.Name -eq "Superpowers" }).License | Should Be "MIT"
        ($items | Where-Object { $_.Name -eq "Markplane" }).PinnedCommit | Should Match "Vendored source snapshot"
        ($items | Where-Object { $_.Name -eq "Superpowers" }).PinnedCommit | Should Match "Vendored source snapshot"

        $superpowersLicense = Get-Content -Raw -LiteralPath (Join-Path $script:repoRoot "LICENSES\superpowers-MIT.txt")
        $superpowersLicense | Should Match "Copyright \(c\) 2025 Jesse Vincent"
    }

    It "passes the distribution readiness script" {
        Test-Path -LiteralPath $script:readinessScript -PathType Leaf | Should Be $true

        & $script:readinessScript -RepoRoot $script:repoRoot

        $LASTEXITCODE | Should Be 0
    }
}

