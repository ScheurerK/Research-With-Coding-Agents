$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$installer = Join-Path $root "Install-VSCodeExtension.ps1"

function New-FakeExtensionCli {
    param(
        [string]$Path,
        [string]$LogPath,
        [string]$Name,
        [string]$RegistrationOutput = "local.markplane-vscode@0.1.2",
        [string]$DiagnosticOutput,
        [int]$InstallExitCode = 0,
        [int]$ListExitCode = 0,
        [int]$UninstallExitCode = 0
    )

    $listOutput = if ($RegistrationOutput) { "echo $RegistrationOutput" } else { "rem no registration output" }
    $diagnostic = if ($DiagnosticOutput) { "echo $DiagnosticOutput 1>&2" } else { "rem no diagnostic output" }
    Set-Content -LiteralPath $Path -Value @"
@echo off
echo $Name^|%*>>"$LogPath"
if "%1"=="--install-extension" (
    $diagnostic
    exit /b $InstallExitCode
)
if "%1"=="--list-extensions" (
    $diagnostic
    $listOutput
    exit /b $ListExitCode
)
if "%1"=="--uninstall-extension" exit /b $UninstallExitCode
exit /b 0
"@
}

function New-TestVsix {
    $vsix = Join-Path $TestDrive "markplane-vscode-0.1.2.vsix"
    Set-Content -LiteralPath $vsix -Value "fake"
    return (Resolve-Path -LiteralPath $vsix).Path
}

Describe "Markplane VS Code family extension installer" {
    It "installs verifies and uninstalls through both IDE CLIs with exact arguments" {
        $vsix = New-TestVsix
        $log = Join-Path $TestDrive "cli.log"
        $codeCli = Join-Path $TestDrive "code.cmd"
        $antigravityCli = Join-Path $TestDrive "antigravity-ide.cmd"
        New-FakeExtensionCli -Path $codeCli -LogPath $log -Name "code"
        New-FakeExtensionCli -Path $antigravityCli -LogPath $log -Name "antigravity"

        & $installer -VsixPath $vsix -VSCodeCli $codeCli -AntigravityCli $antigravityCli
        $LASTEXITCODE | Should Be 0
        (Get-Content -Raw -LiteralPath $log).Trim() | Should Be @"
code|--install-extension $vsix --force
code|--list-extensions --show-versions
antigravity|--install-extension $vsix --force
antigravity|--list-extensions --show-versions
"@.Trim()

        & $installer -VSCodeCli $codeCli -AntigravityCli $antigravityCli -Uninstall
        $LASTEXITCODE | Should Be 0
        (Get-Content -Raw -LiteralPath $log).Trim() | Should Be @"
code|--install-extension $vsix --force
code|--list-extensions --show-versions
antigravity|--install-extension $vsix --force
antigravity|--list-extensions --show-versions
code|--uninstall-extension local.markplane-vscode
antigravity|--uninstall-extension local.markplane-vscode
"@.Trim()
    }

    It "fails when installation exits nonzero" {
        $vsix = New-TestVsix
        $codeCli = Join-Path $TestDrive "code.cmd"
        New-FakeExtensionCli -Path $codeCli -LogPath (Join-Path $TestDrive "cli.log") -Name "code" -InstallExitCode 17

        { & $installer -VsixPath $vsix -VSCodeCli $codeCli -SkipAntigravity } | Should Throw
    }

    It "fails when registration listing exits nonzero" {
        $vsix = New-TestVsix
        $codeCli = Join-Path $TestDrive "code.cmd"
        New-FakeExtensionCli -Path $codeCli -LogPath (Join-Path $TestDrive "cli.log") -Name "code" -ListExitCode 18

        { & $installer -VsixPath $vsix -VSCodeCli $codeCli -SkipAntigravity } | Should Throw
    }

    It "accepts successful CLI diagnostics on stderr and verifies registration" {
        $vsix = New-TestVsix
        $codeCli = Join-Path $TestDrive "code.cmd"
        New-FakeExtensionCli -Path $codeCli -LogPath (Join-Path $TestDrive "cli.log") -Name "code" -DiagnosticOutput "internal diagnostic"

        { & $installer -VsixPath $vsix -VSCodeCli $codeCli -SkipAntigravity } | Should Not Throw
        $LASTEXITCODE | Should Be 0
    }
    It "fails when the extension is absent from registration output" {
        $vsix = New-TestVsix
        $codeCli = Join-Path $TestDrive "code.cmd"
        New-FakeExtensionCli -Path $codeCli -LogPath (Join-Path $TestDrive "cli.log") -Name "code" -RegistrationOutput "other.extension@1.0.0"

        { & $installer -VsixPath $vsix -VSCodeCli $codeCli -SkipAntigravity } | Should Throw
    }

    It "fails when uninstallation exits nonzero" {
        $codeCli = Join-Path $TestDrive "code.cmd"
        New-FakeExtensionCli -Path $codeCli -LogPath (Join-Path $TestDrive "cli.log") -Name "code" -UninstallExitCode 19

        { & $installer -VSCodeCli $codeCli -SkipAntigravity -Uninstall } | Should Throw
    }

    It "resolves the default VS Code CLI from PATH" {
        $vsix = New-TestVsix
        $log = Join-Path $TestDrive "default-cli.log"
        New-FakeExtensionCli -Path (Join-Path $TestDrive "code.cmd") -LogPath $log -Name "code"
        $originalPath = $env:Path

        try {
            $env:Path = "$TestDrive;$originalPath"
            & $installer -VsixPath $vsix -SkipAntigravity
            $LASTEXITCODE | Should Be 0
        }
        finally {
            $env:Path = $originalPath
        }

        (Get-Content -Raw -LiteralPath $log).Trim() | Should Be @"
code|--install-extension $vsix --force
code|--list-extensions --show-versions
"@.Trim()
    }

    It "honors both skip switches and prints the reload instruction" {
        $vsix = New-TestVsix
        $log = Join-Path $TestDrive "skipped-cli.log"
        $codeCli = Join-Path $TestDrive "code.cmd"
        $antigravityCli = Join-Path $TestDrive "antigravity-ide.cmd"
        New-FakeExtensionCli -Path $codeCli -LogPath $log -Name "code"
        New-FakeExtensionCli -Path $antigravityCli -LogPath $log -Name "antigravity"

        $output = (& $installer -VsixPath $vsix -VSCodeCli $codeCli -AntigravityCli $antigravityCli -SkipVSCode -SkipAntigravity 6>&1) | Out-String

        $LASTEXITCODE | Should Be 0
        $output | Should Match "Developer: Reload Window"
        (Test-Path -LiteralPath $log) | Should Be $false
    }

    It "warns when Antigravity IDE is absent without copying folders" {
        $vsix = New-TestVsix
        $log = Join-Path $TestDrive "code.log"
        $codeCli = Join-Path $TestDrive "code.cmd"
        New-FakeExtensionCli -Path $codeCli -LogPath $log -Name "code"

        $output = (& $installer -VsixPath $vsix -VSCodeCli $codeCli -AntigravityCli (Join-Path $TestDrive "missing.cmd") 3>&1) | Out-String

        $LASTEXITCODE | Should Be 0
        $output | Should Match "Antigravity IDE CLI was not found"
        (Test-Path -LiteralPath (Join-Path $TestDrive "extensions")) | Should Be $false
    }

    It "builds modal summary content for successes warnings and reload guidance without opening UI" {
        $vsix = New-TestVsix
        $log = Join-Path $TestDrive "summary-cli.log"
        $codeCli = Join-Path $TestDrive "code.cmd"
        $summaryPath = Join-Path $TestDrive "summary.txt"
        New-FakeExtensionCli -Path $codeCli -LogPath $log -Name "code"

        $presenter = {
            param([string]$SummaryText)
            [System.IO.File]::WriteAllText($summaryPath, $SummaryText, [System.Text.UTF8Encoding]::new($false))
        }.GetNewClosure()
        & $installer -VsixPath $vsix -VSCodeCli $codeCli -AntigravityCli (Join-Path $TestDrive "missing-antigravity.cmd") -ShowSummary -SummaryPresenter $presenter

        $LASTEXITCODE | Should Be 0
        $summary = Get-Content -Raw -LiteralPath $summaryPath
        $summary | Should Match "Installed and verified local.markplane-vscode in VS Code"
        $summary | Should Match "Antigravity IDE CLI was not found"
        $summary | Should Match "Developer: Reload Window"
    }

    It "warns when the optional summary presenter fails" {
        $vsix = New-TestVsix
        $codeCli = Join-Path $TestDrive "code.cmd"
        New-FakeExtensionCli -Path $codeCli -LogPath (Join-Path $TestDrive "popup-warning.log") -Name "code"

        $output = (& $installer -VsixPath $vsix -VSCodeCli $codeCli -SkipAntigravity -ShowSummary -SummaryPresenter { throw "popup unavailable" } 3>&1) | Out-String

        $LASTEXITCODE | Should Be 0
        $output | Should Match "Could not display the Markplane integration summary"
        $output | Should Match "popup unavailable"
    }

    It "does not let summary presenter failure hide a CLI failure" {
        $vsix = New-TestVsix
        $codeCli = Join-Path $TestDrive "code.cmd"
        New-FakeExtensionCli -Path $codeCli -LogPath (Join-Path $TestDrive "cli-and-popup-failure.log") -Name "code" -InstallExitCode 17
        $popupWarnings = @()
        $caught = $null

        try {
            & $installer -VsixPath $vsix -VSCodeCli $codeCli -SkipAntigravity -ShowSummary -SummaryPresenter { throw "popup unavailable" } -WarningVariable popupWarnings
        } catch {
            $caught = $_
        }

        $caught | Should Not BeNullOrEmpty
        $caught.Exception.Message | Should Match "VS Code CLI failed with exit code 17"
        ($popupWarnings | Out-String) | Should Match "Could not display the Markplane integration summary"
    }

    It "keeps both packaged extension runs hidden and requests the modal summary" {
        foreach ($iss in @("MarkplaneInstaller.iss", "MarkplaneAgentInstaller.iss")) {
            $issText = Get-Content -Raw -LiteralPath (Join-Path $root $iss)
            $runLines = @(
                $issText -split "\r?\n" |
                    Where-Object { $_ -match 'Install-VSCodeExtension\.ps1.*-VsixPath' }
            )
            $runLines.Count | Should Be 1
            $runLines[0] | Should Match '(?:^|\s)-ShowSummary(?:\s|")'
            $runLines[0] | Should Match 'Flags: runhidden waituntilterminated'
        }
    }
}
