Describe "Research With Coding Agents public repository envelope" {
    BeforeAll {
        $script:repoRoot = (Get-Location).Path
        if (-not (Test-Path -LiteralPath (Join-Path $script:repoRoot "README.md") -PathType Leaf)) {
            $script:repoRoot = Split-Path -Parent $PSScriptRoot
        }
        $script:requiredFiles = @(
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
        "extensions\README.md",
        "assets\brand\README.md",
        "assets\brand\rwca-logo.png",
        "assets\brand\rwca-logo-transparent.png",
        "assets\brand\rwca-icon.png"
        )
    }

    It "has all public repository files" {
        foreach ($relativePath in $script:requiredFiles) {
            Test-Path -LiteralPath (Join-Path $script:repoRoot $relativePath) -PathType Leaf | Should Be $true
        }
    }

    It "documents the product identity and supported first install path" {
        $readme = Get-Content -Raw -LiteralPath (Join-Path $script:repoRoot "README.md")

        $readme | Should Match "Research With Coding Agents"
        $readme | Should Match "assets/brand/rwca-logo\.png"
        $readme | Should Match "ResearchWithCodingAgentsSetup-v0\.1\.0\.exe"
        $readme | Should Match "git clone https://github.com/<owner>/research-with-coding-agents.git"
        $readme | Should Match "Windows"
        $readme | Should Match "experimental"
        $readme | Should Match "\.research-with-coding-agents\\extensions"
    }

    It "does not present the complete product as Markplane" {
        $readme = Get-Content -Raw -LiteralPath (Join-Path $script:repoRoot "README.md")

        $readme | Should Not Match "^# Markplane"
        $readme | Should Match "Markplane is a core component"
    }

    It "uses the public source layout rather than legacy staging directories" {
        foreach ($relativePath in @(
            "components\markplane\Cargo.toml",
            "components\superpowers\skills\using-superpowers\SKILL.md",
            "packages\vscode-extension\source\package.json",
            "packages\agent-adapters\hooks\Invoke-MarkplaneAntigravityHook.ps1",
            "installer\windows\MarkplaneInstaller.iss"
        )) {
            Test-Path -LiteralPath (Join-Path $script:repoRoot $relativePath) -PathType Leaf | Should Be $true
        }

        Test-Path -LiteralPath (Join-Path $script:repoRoot "markplane-master") -PathType Container | Should Be $false
        Test-Path -LiteralPath (Join-Path $script:repoRoot "MarkplaneInstaller") -PathType Container | Should Be $false
        Test-Path -LiteralPath (Join-Path $script:repoRoot "Skills") -PathType Container | Should Be $false
    }

    It "does not contain local workspace metadata or component build artifacts" {
        foreach ($relativePath in @(
            ".agents\mcp_config.json",
            "components\markplane\.markplane",
            "components\markplane\.claude",
            "components\markplane\.github",
            "components\markplane\Install-MarkplaneForCodex.ps1",
            "components\markplane\rustup-init.exe",
            "components\markplane\target",
            "installer\windows\Output"
        )) {
            Test-Path -LiteralPath (Join-Path $script:repoRoot $relativePath) | Should Be $false
        }
    }

    It "does not contain local absolute machine paths in public files" {
        $publicRoots = @("README.md", "CONTRIBUTING.md", "SECURITY.md", "UPSTREAM.md", "THIRD_PARTY_NOTICES.md", "docs", "packages", "installer", "tests", "scripts")
        $files = foreach ($relativePath in $publicRoots) {
            $path = Join-Path $script:repoRoot $relativePath
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                Get-Item -LiteralPath $path
            } elseif (Test-Path -LiteralPath $path -PathType Container) {
                Get-ChildItem -LiteralPath $path -Recurse -File |
                    Where-Object {
                        $_.FullName -notmatch '\\(Output|target|node_modules|dist)\\' -and
                        $_.Name -match '(\.md|\.txt|\.ps1|\.psm1|\.iss|\.yml|\.yaml|\.json|\.toml|\.sh|\.rs|\.ts|\.tsx|\.js|\.css|\.html|\.gitignore|\.gitattributes)$'
                    }
            }
        }

        foreach ($file in $files) {
            $content = [System.IO.File]::ReadAllText($file.FullName)
            $content | Should Not Match "C:\\Users\\"
            $content | Should Not Match "Downloads\\markplane-master"
        }
    }
}
