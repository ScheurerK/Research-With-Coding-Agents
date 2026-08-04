[CmdletBinding()]
param(
    [string]$VsixPath,
    [string]$ExtensionId = "local.markplane-vscode",
    [string]$VSCodeCli,
    [string]$AntigravityCli,
    [switch]$SkipVSCode,
    [switch]$SkipAntigravity,
    [switch]$Uninstall,
    [switch]$ShowSummary,
    [scriptblock]$SummaryPresenter
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message"
}

function Resolve-Cli {
    param([string]$ExplicitPath, [string[]]$CommandNames, [string[]]$Candidates)

    if ($ExplicitPath) {
        if (Test-Path -LiteralPath $ExplicitPath -PathType Leaf) {
            return (Resolve-Path -LiteralPath $ExplicitPath).Path
        }
        return $null
    }

    foreach ($name in $CommandNames) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command) {
            return $command.Source
        }
    }

    foreach ($candidate in $Candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    return $null
}

function Invoke-ExtensionCli {
    param([string]$Label, [string]$Cli, [string[]]$Arguments)

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        # Native stderr is diagnostic output unless the process reports a failed exit code.
        $ErrorActionPreference = "Continue"
        $output = @(& $Cli @Arguments 2>&1)
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
    if ($exitCode -ne 0) {
        throw "$Label CLI failed with exit code ${exitCode}: $($output -join [Environment]::NewLine)"
    }
    return $output
}

function New-IntegrationSummaryText {
    param([string[]]$Items)

    $lines = @("Markplane IDE integration")
    if (@($Items).Count -gt 0) {
        $lines += ""
        $lines += @($Items)
    }
    return ($lines -join [Environment]::NewLine)
}

function Show-IntegrationSummary {
    param(
        [Parameter(Mandatory = $true)][string]$SummaryText,
        [scriptblock]$Presenter
    )

    if ($Presenter) {
        & $Presenter $SummaryText
        return
    }

    $shell = New-Object -ComObject "WScript.Shell"
    [void]$shell.Popup($SummaryText, 0, "Markplane IDE integration", 64)
}

$vsCodeCandidates = @()
if ($env:LOCALAPPDATA) {
    $vsCodeCandidates += Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\bin\code.cmd"
}

$antigravityCandidates = @()
if ($env:LOCALAPPDATA) {
    $antigravityCandidates += Join-Path $env:LOCALAPPDATA "Programs\Antigravity IDE\bin\antigravity-ide.cmd"
}

$targets = @()
if (-not $SkipVSCode) {
    $targets += [pscustomobject]@{
        Label = "VS Code"
        Cli = Resolve-Cli -ExplicitPath $VSCodeCli -CommandNames @("code.cmd", "code") -Candidates $vsCodeCandidates
    }
}
if (-not $SkipAntigravity) {
    $targets += [pscustomobject]@{
        Label = "Antigravity IDE"
        Cli = Resolve-Cli -ExplicitPath $AntigravityCli -CommandNames @("antigravity-ide.cmd", "agy-ide.cmd") -Candidates $antigravityCandidates
    }
}

$summaryItems = New-Object System.Collections.ArrayList
$operationError = $null
try {
    if (-not $Uninstall) {
        if (-not $VsixPath -or -not (Test-Path -LiteralPath $VsixPath -PathType Leaf)) {
            throw "VSIX file was not found: $VsixPath"
        }
        $resolvedVsix = (Resolve-Path -LiteralPath $VsixPath).Path
    }

    foreach ($target in $targets) {
        if (-not $target.Cli) {
            $message = "$($target.Label) CLI was not found. Markplane extension installation was skipped."
            [void]$summaryItems.Add($message)
            Write-Warning $message
            continue
        }

        if ($Uninstall) {
            [void](Invoke-ExtensionCli -Label $target.Label -Cli $target.Cli -Arguments @("--uninstall-extension", $ExtensionId))
            $message = "Uninstalled $ExtensionId from $($target.Label)"
            [void]$summaryItems.Add($message)
            Write-Step $message
            continue
        }

        [void](Invoke-ExtensionCli -Label $target.Label -Cli $target.Cli -Arguments @("--install-extension", $resolvedVsix, "--force"))
        $registered = @(Invoke-ExtensionCli -Label $target.Label -Cli $target.Cli -Arguments @("--list-extensions", "--show-versions"))
        if (-not ($registered -match "^$([regex]::Escape($ExtensionId))(@|$)")) {
            throw "$ExtensionId was not registered by $($target.Label)."
        }
        $message = "Installed and verified $ExtensionId in $($target.Label)"
        [void]$summaryItems.Add($message)
        Write-Step $message
    }
} catch {
    $operationError = $_
    [void]$summaryItems.Add("Integration failed: $($_.Exception.Message)")
}

if (-not $Uninstall) {
    $reloadMessage = "Run Developer: Reload Window in each open IDE window to activate the Markplane interface."
    [void]$summaryItems.Add($reloadMessage)
    Write-Host $reloadMessage
}

$summaryText = New-IntegrationSummaryText -Items @($summaryItems)
if ($ShowSummary) {
    try {
        Show-IntegrationSummary -SummaryText $summaryText -Presenter $SummaryPresenter
    } catch {
        Write-Warning "Could not display the Markplane integration summary: $($_.Exception.Message)"
    }
}

if ($null -ne $operationError) {
    throw $operationError
}

$global:LASTEXITCODE = 0
