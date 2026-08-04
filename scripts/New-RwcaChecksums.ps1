[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Directory,
    [string]$OutputPath = (Join-Path $Directory "SHA256SUMS.txt")
)

$ErrorActionPreference = "Stop"

$resolvedDirectory = (Resolve-Path -LiteralPath $Directory -ErrorAction Stop).Path
$files = @(Get-ChildItem -LiteralPath $resolvedDirectory -File | Where-Object {
    $_.Name -ne (Split-Path -Leaf $OutputPath)
} | Sort-Object Name)

$lines = foreach ($file in $files) {
    $hash = Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName
    "$($hash.Hash.ToLowerInvariant())  $($file.Name)"
}

Set-Content -LiteralPath $OutputPath -Value $lines -Encoding utf8
Write-Host "Wrote checksums: $OutputPath"
$global:LASTEXITCODE = 0
