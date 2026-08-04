$repoRoot = Split-Path -Parent $PSScriptRoot

Describe "Research With Coding Agents public repository envelope" {
    $requiredFiles = @(
        "README.md",
        "CONTRIBUTING.md",
        "SECURITY.md",
        "UPSTREAM.md",
        "LICENSE",
        "THIRD_PARTY_NOTICES.md",
        ".gitignore",
        ".gitattributes",
        "CLAUDE.md",
        "components\README.md",
        "packages\README.md",
        "packages\project-skills\README.md",
        "packages\agent-adapters\README.md",
        "packages\vscode-extension\README.md",
        "extensions\README.md"
    )

    It "has all public repository files" {
        foreach ($relativePath in $requiredFiles) {
            Test-Path -LiteralPath (Join-Path $repoRoot $relativePath) -PathType Leaf | Should Be $true
        }
    }

    It "documents the product identity and supported first install path" {
        $readme = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "README.md")

        $readme | Should Match "Research With Coding Agents"
        $readme | Should Match "ResearchWithCodingAgentsSetup-v0\.1\.0\.exe"
        $readme | Should Match "git clone --recurse-submodules"
        $readme | Should Match "Windows"
        $readme | Should Match "experimental"
        $readme | Should Match "\.research-with-coding-agents\\extensions"
    }

    It "does not present the complete product as Markplane" {
        $readme = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "README.md")

        $readme | Should Not Match "^# Markplane"
        $readme | Should Match "Markplane is a core component"
    }
}
