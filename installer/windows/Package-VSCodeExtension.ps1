[CmdletBinding()]
param(
    [string]$ExtensionSource,
    [string]$OutputPath,
    [string]$VsceCommand
)

$ErrorActionPreference = "Stop"

function Get-ScriptDirectory {
    if ($PSScriptRoot) { return $PSScriptRoot }
    return (Get-Location).Path
}

$scriptDirectory = Get-ScriptDirectory
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDirectory)
if (-not $ExtensionSource) {
    $ExtensionSource = Join-Path $repoRoot "packages\vscode-extension\source"
}
if (-not $OutputPath) {
    $OutputPath = Join-Path $scriptDirectory "vscode-extension\markplane-vscode-0.1.2.vsix"
}
$source = (Resolve-Path -LiteralPath $ExtensionSource -ErrorAction Stop).Path
$outputDirectory = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
$output = [System.IO.Path]::GetFullPath($OutputPath)


if (Test-Path -LiteralPath $output -PathType Leaf) {
    Remove-Item -LiteralPath $output -Force -ErrorAction Stop
}

$arguments = @("package", "--out", $output)
if (-not $VsceCommand) {
    $vsce = Get-Command vsce.cmd -ErrorAction SilentlyContinue
    if ($vsce) {
        $VsceCommand = $vsce.Source
    } else {
        $npx = Get-Command npx.cmd -ErrorAction SilentlyContinue
        if (-not $npx) {
            throw "Neither vsce.cmd nor npx.cmd was found in the build environment."
        }
        $VsceCommand = $npx.Source
        $arguments = @("--yes", "@vscode/vsce", "package", "--out", $output)
    }
}

Push-Location $source
try {
    $global:LASTEXITCODE = 0
    & $VsceCommand @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "VSIX packaging failed with exit code $LASTEXITCODE."
    }
} finally {
    Pop-Location
}

if (-not (Test-Path -LiteralPath $output -PathType Leaf)) {
    throw "VSIX was not created: $output"
}

Write-Host "Packaged VSIX: $output"
$global:LASTEXITCODE = 0