[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$RepoRoot,
    [Parameter(Mandatory = $true)][string]$OutputPath
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "Get-RwcaProvenance.ps1")

$packages = New-Object System.Collections.ArrayList
[void]$packages.Add([pscustomobject]@{
    name = "Research With Coding Agents"
    SPDXID = "SPDXRef-Package-ResearchWithCodingAgents"
    downloadLocation = "NOASSERTION"
    licenseConcluded = "Apache-2.0"
    licenseDeclared = "Apache-2.0"
    filesAnalyzed = $false
})

foreach ($item in @(Get-RwcaProvenance -RepoRoot $RepoRoot)) {
    [void]$packages.Add([pscustomobject]@{
        name = $item.Name
        SPDXID = "SPDXRef-Package-" + (($item.Name -replace '[^A-Za-z0-9]+', '') )
        downloadLocation = $item.UpstreamUrl
        licenseConcluded = $item.License
        licenseDeclared = $item.License
        filesAnalyzed = $false
        supplier = "Organization: upstream project"
        localPath = $item.LocalPath
        licenseFile = $item.LicenseFile
        pinnedCommit = $item.PinnedCommit
        modified = $item.Modified
    })
}

$document = [pscustomobject]@{
    spdxVersion = "SPDX-2.3"
    dataLicense = "CC0-1.0"
    SPDXID = "SPDXRef-DOCUMENT"
    name = "Research With Coding Agents SBOM"
    documentNamespace = "https://github.com/research-with-coding-agents/research-with-coding-agents/spdx/v0.1.0"
    creationInfo = [pscustomobject]@{
        created = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        creators = @("Tool: Research With Coding Agents release scripts")
    }
    packages = @($packages)
}

Set-Content -LiteralPath $OutputPath -Value ($document | ConvertTo-Json -Depth 20) -Encoding utf8
Write-Host "Wrote SBOM: $OutputPath"
$global:LASTEXITCODE = 0
