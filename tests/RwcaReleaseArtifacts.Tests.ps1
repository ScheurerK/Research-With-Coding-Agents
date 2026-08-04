$repoRoot = Split-Path -Parent $PSScriptRoot
$releaseScript = Join-Path $repoRoot "scripts\Build-RwcaRelease.ps1"

function New-RwcaReleaseFixture {
    $fixture = Join-Path $TestDrive "rwca-release-fixture"
    New-Item -ItemType Directory -Force -Path $fixture | Out-Null

    foreach ($file in @("README.md", "LICENSE", "THIRD_PARTY_NOTICES.md")) {
        Copy-Item -LiteralPath (Join-Path $repoRoot $file) -Destination (Join-Path $fixture $file)
    }
    Copy-Item -LiteralPath (Join-Path $repoRoot "LICENSES") -Destination (Join-Path $fixture "LICENSES") -Recurse
    Copy-Item -LiteralPath (Join-Path $repoRoot "docs") -Destination (Join-Path $fixture "docs") -Recurse

    $installerOutput = Join-Path $fixture "MarkplaneInstaller\Output"
    New-Item -ItemType Directory -Force -Path $installerOutput | Out-Null
    Set-Content -LiteralPath (Join-Path $installerOutput "ResearchWithCodingAgentsSetup-v0.1.0.exe") -Value "fake-installer"

    return $fixture
}

Describe "Research With Coding Agents release artifacts" {
    It "creates installer, portable archive, checksums, and SPDX SBOM" {
        Test-Path -LiteralPath $releaseScript -PathType Leaf | Should Be $true

        $fixture = New-RwcaReleaseFixture
        $dist = Join-Path $TestDrive "dist"

        & $releaseScript -RepoRoot $fixture -DistDir $dist -SkipInstallerBuild

        $LASTEXITCODE | Should Be 0
        Test-Path -LiteralPath (Join-Path $dist "ResearchWithCodingAgentsSetup-v0.1.0.exe") -PathType Leaf | Should Be $true
        Test-Path -LiteralPath (Join-Path $dist "ResearchWithCodingAgentsPortable-v0.1.0-win-x64.zip") -PathType Leaf | Should Be $true
        Test-Path -LiteralPath (Join-Path $dist "SHA256SUMS.txt") -PathType Leaf | Should Be $true
        Test-Path -LiteralPath (Join-Path $dist "SBOM.spdx.json") -PathType Leaf | Should Be $true

        $checksums = Get-Content -Raw -LiteralPath (Join-Path $dist "SHA256SUMS.txt")
        $checksums | Should Match "ResearchWithCodingAgentsSetup-v0\.1\.0\.exe"
        $checksums | Should Match "ResearchWithCodingAgentsPortable-v0\.1\.0-win-x64\.zip"

        $sbom = Get-Content -Raw -LiteralPath (Join-Path $dist "SBOM.spdx.json") | ConvertFrom-Json
        @($sbom.packages | Where-Object { $_.name -eq "Research With Coding Agents" }).Count | Should Be 1
        @($sbom.packages | Where-Object { $_.name -eq "Markplane" }).Count | Should Be 1
        @($sbom.packages | Where-Object { $_.name -eq "Superpowers" }).Count | Should Be 1
    }
}
