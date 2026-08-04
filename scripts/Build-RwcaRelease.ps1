[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$DistDir,
    [switch]$SkipInstallerBuild
)

$ErrorActionPreference = "Stop"

$resolvedRepoRoot = (Resolve-Path -LiteralPath $RepoRoot -ErrorAction Stop).Path
if (-not $DistDir) {
    $DistDir = Join-Path $resolvedRepoRoot "dist"
}

$installerScript = Join-Path $resolvedRepoRoot "installer\windows\Build-Installer.ps1"
$installerOutput = Join-Path $resolvedRepoRoot "installer\windows\Output\ResearchWithCodingAgentsSetup-v0.1.0.exe"
$portableName = "ResearchWithCodingAgentsPortable-v0.1.0-win-x64.zip"

if (-not $SkipInstallerBuild) {
    if (-not (Test-Path -LiteralPath $installerScript -PathType Leaf)) {
        throw "Installer build script not found: $installerScript"
    }
    & $installerScript
    if ($LASTEXITCODE -ne 0) {
        throw "Installer build failed with exit code $LASTEXITCODE."
    }
}

if (-not (Test-Path -LiteralPath $installerOutput -PathType Leaf)) {
    throw "Unified installer output not found: $installerOutput"
}

if (Test-Path -LiteralPath $DistDir) {
    Remove-Item -LiteralPath $DistDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

Copy-Item -LiteralPath $installerOutput -Destination (Join-Path $DistDir "ResearchWithCodingAgentsSetup-v0.1.0.exe")

$staging = Join-Path ([System.IO.Path]::GetTempPath()) ("rwca-portable-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $staging | Out-Null
try {
    foreach ($relativePath in @("README.md", "LICENSE", "THIRD_PARTY_NOTICES.md")) {
        Copy-Item -LiteralPath (Join-Path $resolvedRepoRoot $relativePath) -Destination (Join-Path $staging $relativePath)
    }
    Copy-Item -LiteralPath (Join-Path $resolvedRepoRoot "LICENSES") -Destination (Join-Path $staging "LICENSES") -Recurse
    if (Test-Path -LiteralPath (Join-Path $resolvedRepoRoot "docs") -PathType Container) {
        Copy-Item -LiteralPath (Join-Path $resolvedRepoRoot "docs") -Destination (Join-Path $staging "docs") -Recurse
    }

    $portablePath = Join-Path $DistDir $portableName
    if (Test-Path -LiteralPath $portablePath -PathType Leaf) {
        Remove-Item -LiteralPath $portablePath -Force
    }
    Compress-Archive -Path (Join-Path $staging "*") -DestinationPath $portablePath -Force
}
finally {
    Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
}

& (Join-Path $PSScriptRoot "New-RwcaSbom.ps1") -RepoRoot $resolvedRepoRoot -OutputPath (Join-Path $DistDir "SBOM.spdx.json")
if ($LASTEXITCODE -ne 0) {
    throw "SBOM generation failed with exit code $LASTEXITCODE."
}

& (Join-Path $PSScriptRoot "New-RwcaChecksums.ps1") -Directory $DistDir -OutputPath (Join-Path $DistDir "SHA256SUMS.txt")
if ($LASTEXITCODE -ne 0) {
    throw "Checksum generation failed with exit code $LASTEXITCODE."
}

Write-Host "Built Research With Coding Agents release artifacts in $DistDir"
$global:LASTEXITCODE = 0
