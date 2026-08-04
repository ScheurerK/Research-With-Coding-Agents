$repoRoot = Split-Path -Parent $PSScriptRoot
$installerRoot = Join-Path $repoRoot "MarkplaneInstaller"

Describe "Research With Coding Agents installer identity" {
    It "uses the public product identity in the Inno Setup definition" {
        $iss = Get-Content -Raw -LiteralPath (Join-Path $installerRoot "MarkplaneInstaller.iss")

        $iss | Should Match '#define MyAppName "Research With Coding Agents"'
        $iss | Should Match '#define MyAppVersion "0\.1\.0"'
        $iss | Should Match 'DefaultDirName=\{localappdata\}\\Programs\\ResearchWithCodingAgents'
        $iss | Should Match 'DefaultGroupName=Research With Coding Agents'
        $iss | Should Match 'OutputBaseFilename=ResearchWithCodingAgentsSetup-v0\.1\.0'
    }

    It "expects the unified setup executable from the build script" {
        $buildScript = Get-Content -Raw -LiteralPath (Join-Path $installerRoot "Build-Installer.ps1")

        $buildScript | Should Match 'ResearchWithCodingAgentsSetup-v0\.1\.0\.exe'
        $buildScript | Should Not Match 'MarkplaneSetup-0\.1\.2\.exe'
    }
}
