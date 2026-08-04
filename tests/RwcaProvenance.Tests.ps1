$repoRoot = Split-Path -Parent $PSScriptRoot
$provenanceScript = Join-Path $repoRoot "scripts\Get-RwcaProvenance.ps1"
$readinessScript = Join-Path $repoRoot "scripts\Test-RwcaDistributionReadiness.ps1"

Describe "Research With Coding Agents provenance" {
    It "provides a machine-readable provenance table for shipped components" {
        Test-Path -LiteralPath $provenanceScript -PathType Leaf | Should Be $true
        . $provenanceScript

        $items = Get-RwcaProvenance -RepoRoot $repoRoot
        $names = @($items | ForEach-Object { $_.Name })

        $names -contains "Markplane" | Should Be $true
        $names -contains "Superpowers" | Should Be $true
        $names -contains "Research Repository Governance Skill" | Should Be $true

        foreach ($item in $items) {
            [string]::IsNullOrWhiteSpace($item.UpstreamUrl) | Should Be $false
            [string]::IsNullOrWhiteSpace($item.License) | Should Be $false
            Test-Path -LiteralPath (Join-Path $repoRoot $item.LicenseFile) -PathType Leaf | Should Be $true
        }
    }

    It "keeps the required upstream and license declarations" {
        . $provenanceScript

        $items = @(Get-RwcaProvenance -RepoRoot $repoRoot)
        ($items | Where-Object { $_.Name -eq "Markplane" }).UpstreamUrl | Should Be "https://github.com/zerowand01/markplane"
        ($items | Where-Object { $_.Name -eq "Superpowers" }).UpstreamUrl | Should Be "https://github.com/obra/superpowers"
        ($items | Where-Object { $_.Name -eq "Superpowers" }).License | Should Be "MIT"

        $superpowersLicense = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "LICENSES\superpowers-MIT.txt")
        $superpowersLicense | Should Match "Copyright \(c\) 2025 Jesse Vincent"
    }

    It "passes the distribution readiness script" {
        Test-Path -LiteralPath $readinessScript -PathType Leaf | Should Be $true

        & $readinessScript -RepoRoot $repoRoot

        $LASTEXITCODE | Should Be 0
    }
}

