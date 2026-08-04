$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$repoRoot = Split-Path -Parent (Split-Path -Parent $root)
$packager = Join-Path $root "Package-VSCodeExtension.ps1"

Describe "VSIX packaging" {
    It "uses the public default extension source with an injected VSCE command" {
        $fixtureOutput = Join-Path $TestDrive "markplane-vscode-0.1.2.vsix"
        $fakeVsce = Join-Path $TestDrive "fake-default-vsce.ps1"
        Set-Content -LiteralPath $fakeVsce -Value 'param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Remaining)
$index = [Array]::IndexOf($Remaining, "--out")
if ($index -lt 0) { exit 2 }
[System.IO.File]::WriteAllText($Remaining[$index + 1], "fake-default-vsix")'

        & $packager -OutputPath $fixtureOutput -VsceCommand $fakeVsce

        $LASTEXITCODE | Should Be 0
        (Test-Path -LiteralPath $fixtureOutput -PathType Leaf) | Should Be $true
    }

    It "packages the deterministic VSIX path through an injected vsce command" {
        $source = Join-Path $TestDrive "extension"
        New-Item -ItemType Directory -Force -Path $source | Out-Null
        Set-Content -LiteralPath (Join-Path $source "package.json") -Value '{"name":"markplane-vscode","publisher":"local","version":"0.1.2","engines":{"vscode":"^1.85.0"}}'
        $fakeVsce = Join-Path $TestDrive "fake-vsce.ps1"
        Set-Content -LiteralPath $fakeVsce -Value 'param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Remaining)
$index = [Array]::IndexOf($Remaining, "--out")
if ($index -lt 0) { exit 2 }
[System.IO.File]::WriteAllText($Remaining[$index + 1], "fake-vsix")'
        $output = Join-Path $TestDrive "markplane-vscode-0.1.2.vsix"

        & $packager -ExtensionSource $source -OutputPath $output -VsceCommand $fakeVsce

        $LASTEXITCODE | Should Be 0
        (Test-Path -LiteralPath $output -PathType Leaf) | Should Be $true
    }

    It "fails when the packaging command exits nonzero" {
        $source = Join-Path $TestDrive "extension"
        New-Item -ItemType Directory -Force -Path $source | Out-Null
        $fakeVsce = Join-Path $TestDrive "failing-vsce.ps1"
        Set-Content -LiteralPath $fakeVsce -Value "exit 7"

        { & $packager -ExtensionSource $source -OutputPath (Join-Path $TestDrive "output.vsix") -VsceCommand $fakeVsce } | Should Throw
    }

    It "fails when the packaging command creates no output" {
        $source = Join-Path $TestDrive "extension"
        New-Item -ItemType Directory -Force -Path $source | Out-Null
        $fakeVsce = Join-Path $TestDrive "no-output-vsce.ps1"
        Set-Content -LiteralPath $fakeVsce -Value "exit 0"

        { & $packager -ExtensionSource $source -OutputPath (Join-Path $TestDrive "output.vsix") -VsceCommand $fakeVsce } | Should Throw
    }

    It "does not accept a stale VSIX when the packaging command creates no output" {
        $source = Join-Path $TestDrive "extension"
        New-Item -ItemType Directory -Force -Path $source | Out-Null
        $fakeVsce = Join-Path $TestDrive "no-output-vsce.ps1"
        Set-Content -LiteralPath $fakeVsce -Value "exit 0"
        $output = Join-Path $TestDrive "output.vsix"
        Set-Content -LiteralPath $output -Value "stale-vsix"

        { & $packager -ExtensionSource $source -OutputPath $output -VsceCommand $fakeVsce } | Should Throw
        (Test-Path -LiteralPath $output -PathType Leaf) | Should Be $false
    }

    It "wires both installer builds and payloads to the VSIX" {
        foreach ($build in @("Build-Installer.ps1", "Build-AgentInstaller.ps1")) {
            $text = Get-Content -Raw -LiteralPath (Join-Path $root $build)
            $packagerIndex = $text.IndexOf("Package-VSCodeExtension.ps1")
            $isccIndex = $text.IndexOf('& $InnoSetupCompiler $issPath')

            $packagerIndex | Should BeGreaterThan -1
            $isccIndex | Should BeGreaterThan -1
            $packagerIndex | Should BeLessThan $isccIndex
        }
        foreach ($iss in @("MarkplaneInstaller.iss", "MarkplaneAgentInstaller.iss")) {
            $text = Get-Content -Raw -LiteralPath (Join-Path $root $iss)
            $text | Should Match 'Source: "vscode-extension\\markplane-vscode-0\.1\.2\.vsix"; DestDir: "\{app\}\\vscode-extension"; Flags: ignoreversion'
            $text | Should Not Match '(?m)^Source: "vscode-extension\\(?!markplane-vscode-0\.1\.2\.vsix")'
        }
    }
}