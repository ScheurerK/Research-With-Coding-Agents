[CmdletBinding()]
param(
    [string]$InnoSetupCompiler
)

$ErrorActionPreference = "Stop"
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$issPath = Join-Path $scriptDir "MarkplaneInstaller.iss"
$output = Join-Path $scriptDir "Output\ResearchWithCodingAgentsSetup-v0.1.0.exe"

if (-not (Test-Path -LiteralPath $issPath -PathType Leaf)) {
    throw "Installer definition not found: $issPath"
}

if (-not $InnoSetupCompiler) {
    $command = Get-Command iscc.exe -ErrorAction SilentlyContinue
    if ($command) {
        $InnoSetupCompiler = $command.Source
    }
}

if (-not $InnoSetupCompiler) {
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
        "$env:LOCALAPPDATA\Programs\Inno Setup 5\ISCC.exe",
        "${env:ProgramFiles(x86)}\Inno Setup 5\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 5\ISCC.exe"
    )

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            $InnoSetupCompiler = $candidate
            break
        }
    }
}

if (-not $InnoSetupCompiler) {
    throw "Inno Setup compiler (ISCC.exe) was not found. Install Inno Setup 6, then re-run this script."
}

Push-Location $scriptDir
try {
    & (Join-Path $scriptDir "Package-VSCodeExtension.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "VSIX packaging failed with exit code $LASTEXITCODE."
    }

    if (Test-Path -LiteralPath $output -PathType Leaf) {
        Remove-Item -LiteralPath $output -Force -ErrorAction Stop
    }
    & $InnoSetupCompiler $issPath
    if ($LASTEXITCODE -ne 0) {
        throw "Inno Setup failed with exit code $LASTEXITCODE."
    }
    if (-not (Test-Path -LiteralPath $output -PathType Leaf)) {
        throw "Inno Setup reported success but did not create the expected installer: $output"
    }
} finally {
    Pop-Location
}

Write-Host "Built installer: $output"
$global:LASTEXITCODE = 0

