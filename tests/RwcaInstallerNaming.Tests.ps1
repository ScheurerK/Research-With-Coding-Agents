Describe "Research With Coding Agents installer identity" {
    BeforeAll {
        $script:repoRoot = (Get-Location).Path
        if (-not (Test-Path -LiteralPath (Join-Path $script:repoRoot "README.md") -PathType Leaf)) {
            $script:repoRoot = Split-Path -Parent $PSScriptRoot
        }
        $script:installerRoot = Join-Path $script:repoRoot "installer\windows"
    }
    It "uses the public product identity in the Inno Setup definition" {
        $iss = Get-Content -Raw -LiteralPath (Join-Path $script:installerRoot "MarkplaneInstaller.iss")

        $iss | Should Match '#define MyAppName "Research With Coding Agents"'
        $iss | Should Match '#define MyAppVersion "0\.1\.0"'
        $iss | Should Match 'DefaultDirName=\{localappdata\}\\Programs\\ResearchWithCodingAgents'
        $iss | Should Match 'DefaultGroupName=Research With Coding Agents'
        $iss | Should Match 'OutputBaseFilename=ResearchWithCodingAgentsSetup-v0\.1\.0'
    }

    It "expects the unified setup executable from the build script" {
        $buildScript = Get-Content -Raw -LiteralPath (Join-Path $script:installerRoot "Build-Installer.ps1")

        $buildScript | Should Match 'ResearchWithCodingAgentsSetup-v0\.1\.0\.exe'
        $buildScript | Should Not Match 'MarkplaneSetup-0\.1\.2\.exe'
    }
}
