$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function New-BuildFixture {
    param(
        [Parameter(Mandatory = $true)][string]$BuildScriptName,
        [Parameter(Mandatory = $true)][string]$IssName,
        [Parameter(Mandatory = $true)][string]$OutputName
    )

    $fixtureRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Force -Path (Join-Path $fixtureRoot "Output") | Out-Null
    Copy-Item -LiteralPath (Join-Path $root $BuildScriptName) -Destination (Join-Path $fixtureRoot $BuildScriptName)
    Set-Content -LiteralPath (Join-Path $fixtureRoot $IssName) -Value "; fixture"
    Set-Content -LiteralPath (Join-Path $fixtureRoot "Package-VSCodeExtension.ps1") -Value '$global:LASTEXITCODE = 0'

    return [pscustomobject]@{
        Root = $fixtureRoot
        BuildScript = Join-Path $fixtureRoot $BuildScriptName
        ExpectedOutput = Join-Path $fixtureRoot ("Output\" + $OutputName)
    }
}

function New-FakeInnoCompiler {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ExpectedOutput,
        [Parameter(Mandatory = $true)][string]$ObservationPath,
        [switch]$CreateOutput
    )

    $createOutputText = if ($CreateOutput) {
        "[System.IO.File]::WriteAllText('$ExpectedOutput', 'fresh-installer')"
    } else {
        "# no output"
    }
    Set-Content -LiteralPath $Path -Value @"
param([string]`$IssPath)
`$observation = if (Test-Path -LiteralPath '$ExpectedOutput' -PathType Leaf) { 'present' } else { 'absent' }
[System.IO.File]::WriteAllText('$ObservationPath', `$observation)
$createOutputText
`$global:LASTEXITCODE = 0
"@
}

$buildCases = @(
    @{
        BuildScriptName = "Build-Installer.ps1"
        IssName = "MarkplaneInstaller.iss"
        OutputName = "ResearchWithCodingAgentsSetup-v0.1.0.exe"
    },
    @{
        BuildScriptName = "Build-AgentInstaller.ps1"
        IssName = "MarkplaneAgentInstaller.iss"
        OutputName = "ResearchWithCodingAgentsAgentSetup-v0.1.0.exe"
    }
)

Describe "Fresh Inno installer outputs" {
    It "removes each exact stale output before invoking ISCC" {
        foreach ($case in $buildCases) {
            $fixture = New-BuildFixture @case
            Set-Content -LiteralPath $fixture.ExpectedOutput -Value "stale-installer"
            $observation = Join-Path $fixture.Root "compiler-observation.txt"
            $compiler = Join-Path $fixture.Root "fake-iscc.ps1"
            New-FakeInnoCompiler -Path $compiler -ExpectedOutput $fixture.ExpectedOutput -ObservationPath $observation -CreateOutput

            & $fixture.BuildScript -InnoSetupCompiler $compiler

            (Get-Content -Raw -LiteralPath $observation).Trim() | Should Be "absent"
            (Get-Content -Raw -LiteralPath $fixture.ExpectedOutput).Trim() | Should Be "fresh-installer"
        }
    }

    It "rejects compiler success when no fresh expected output is created" {
        foreach ($case in $buildCases) {
            $fixture = New-BuildFixture @case
            Set-Content -LiteralPath $fixture.ExpectedOutput -Value "stale-installer"
            $observation = Join-Path $fixture.Root "compiler-observation.txt"
            $compiler = Join-Path $fixture.Root "fake-iscc-no-output.ps1"
            New-FakeInnoCompiler -Path $compiler -ExpectedOutput $fixture.ExpectedOutput -ObservationPath $observation

            { & $fixture.BuildScript -InnoSetupCompiler $compiler } | Should Throw

            (Get-Content -Raw -LiteralPath $observation).Trim() | Should Be "absent"
            (Test-Path -LiteralPath $fixture.ExpectedOutput -PathType Leaf) | Should Be $false
        }
    }

    It "reports the exact fresh output path after successful compilation" {
        foreach ($case in $buildCases) {
            $fixture = New-BuildFixture @case
            $observation = Join-Path $fixture.Root "compiler-observation.txt"
            $compiler = Join-Path $fixture.Root "fake-iscc-success.ps1"
            New-FakeInnoCompiler -Path $compiler -ExpectedOutput $fixture.ExpectedOutput -ObservationPath $observation -CreateOutput

            $output = (& $fixture.BuildScript -InnoSetupCompiler $compiler 6>&1) | Out-String -Width 4096

            $LASTEXITCODE | Should Be 0
            (Test-Path -LiteralPath $fixture.ExpectedOutput -PathType Leaf) | Should Be $true
            $output | Should Match ([regex]::Escape("Built installer: $($fixture.ExpectedOutput)"))
        }
    }
}

