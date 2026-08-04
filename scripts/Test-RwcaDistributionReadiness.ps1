[CmdletBinding()]
param(
    [string]$RepoRoot = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "Get-RwcaProvenance.ps1")

$requiredFiles = @(
    "README.md",
    "CONTRIBUTING.md",
    "SECURITY.md",
    "UPSTREAM.md",
    "LICENSE",
    "THIRD_PARTY_NOTICES.md",
    ".gitignore",
    ".gitattributes",
    "CLAUDE.md"
)

foreach ($relativePath in $requiredFiles) {
    $path = Join-Path $RepoRoot $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required repository file missing: $relativePath"
    }
}

$items = @(Get-RwcaProvenance -RepoRoot $RepoRoot)
if ($items.Count -lt 3) {
    throw "Expected at least 3 provenance entries, found $($items.Count)."
}

foreach ($item in $items) {
    if ([string]::IsNullOrWhiteSpace($item.Name)) {
        throw "A provenance entry has no component name."
    }
    if ([string]::IsNullOrWhiteSpace($item.UpstreamUrl)) {
        throw "Provenance entry has no upstream URL: $($item.Name)"
    }
    if ([string]::IsNullOrWhiteSpace($item.License)) {
        throw "Provenance entry has no license: $($item.Name)"
    }
    if ([string]::IsNullOrWhiteSpace($item.LicenseFile)) {
        throw "Provenance entry has no license file: $($item.Name)"
    }

    $licensePath = Join-Path $RepoRoot $item.LicenseFile
    if (-not (Test-Path -LiteralPath $licensePath -PathType Leaf)) {
        throw "License file missing for $($item.Name): $($item.LicenseFile)"
    }
}

Write-Host "Research With Coding Agents distribution readiness checks passed."
$global:LASTEXITCODE = 0
