Describe "Research repository governance skill" {
    BeforeAll {
        $script:repoRoot = (Get-Location).Path
        if (-not (Test-Path -LiteralPath (Join-Path $script:repoRoot "README.md") -PathType Leaf)) {
            $script:repoRoot = Split-Path -Parent $PSScriptRoot
        }
        $script:fullGovernancePath = Join-Path $script:repoRoot "components\superpowers\skills\research-repo-governance\references\full-governance.md"
    }

    It "requires generated reports and tables to be self-contained for paper readers" {
        Test-Path -LiteralPath $script:fullGovernancePath -PathType Leaf | Should Be $true

        $fullGovernance = Get-Content -Raw -LiteralPath $script:fullGovernancePath

        $fullGovernance | Should Match "self-contained"
        $fullGovernance | Should Match "Table Notes"
        $fullGovernance | Should Match "variable definitions"
        $fullGovernance | Should Match "units"
        $fullGovernance | Should Match "sample"
        $fullGovernance | Should Match "time period"
        $fullGovernance | Should Match "source"
    }

    It "keeps renumbered rule references and generated AGENTS bullets readable" {
        $skillRoot = Join-Path $script:repoRoot "components\superpowers\skills\research-repo-governance"
        $fullGovernance = Get-Content -Raw -LiteralPath $script:fullGovernancePath
        $repositoryLayout = Get-Content -Raw -LiteralPath (Join-Path $skillRoot "references\repository-layout.md")
        $experimentProvenance = Get-Content -Raw -LiteralPath (Join-Path $skillRoot "references\experiment-provenance.md")

        $fullGovernance | Should Not Match "tables\.- \*\*Notebook boundary"
        $fullGovernance | Should Match "Rule 6's migration process"
        $repositoryLayout | Should Match "see Rule 7 in"
        $repositoryLayout | Should Match "sign-off process \(Rule 6\)"
        $experimentProvenance | Should Match "Migration/Restructuring \(Rule 6\)"
    }}
