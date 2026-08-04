# Antigravity Superpowers And VSIX Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Markplane's customized Superpowers bundle authoritative and fully usable in Antigravity, migrate hooks to the current schema, and install the Markplane interface through a bundled VSIX and official IDE CLIs.

**Architecture:** Keep `MarkplaneInstaller/skills` as the only Superpowers source and reconcile the namespaced Antigravity plugin exactly against it. Translate portable workflows through an always-available Antigravity mapping rule, validate the complete installed tree, generate current hook JSON, and replace source-folder extension copies with build-time VSIX packaging plus CLI installation and registration checks.

**Tech Stack:** Windows PowerShell 5.1, Pester 3.4.0, Inno Setup, `@vscode/vsce`, VS Code-compatible extension CLIs, Markdown agent skills.

**Spec:** `docs/superpowers/specs/2026-08-04-antigravity-superpowers-parity-design.md`

**Markplane:** `TASK-cv9gy`, linked implementation plan `PLAN-48fdt`

## Global Constraints

- `MarkplaneInstaller/skills` is the sole authoritative Superpowers source.
- End-user installation must not download or update Superpowers or require Node.js, npm, or `npx`.
- Same-named external skills are preserved and warned about, never deleted.
- Markplane plugin drift fails the health check; unrelated configuration is preserved.
- Markplane MCP remains workspace-local with explicit `--project` and `cwd`.
- Antigravity `PreInvocation` and `Stop` use direct handlers; `PostToolUse` retains matcher wrappers.
- The Markplane extension is installed only from a bundled VSIX through IDE CLIs; direct extension-folder copies are unsupported.
- Hook runtime failures remain fail-open, and `SUPERPOWERS_DISABLE_TELEMETRY=1` remains required.
- This workspace has no `.git` directory. Commit steps become Markplane sync checkpoints unless execution moves to a Git checkout.

---

## File Structure

- `MarkplaneInstaller/Install-AntigravityIntegration.ps1`: owns plugin reconciliation, priority instructions, mapping rule, and Antigravity hook registration.
- `MarkplaneInstaller/skills/using-superpowers/references/antigravity-tools.md`: canonical Antigravity action mapping.
- `MarkplaneInstaller/Test-MarkplaneAgentSkills.ps1`: validates exact skill parity, priority rules, mappings, hooks, and conflict warnings.
- `MarkplaneInstaller/Package-VSCodeExtension.ps1`: packages the extension source into the deterministic VSIX payload.
- `MarkplaneInstaller/Install-VSCodeExtension.ps1`: installs, verifies, and uninstalls the VSIX through available IDE CLIs.
- `MarkplaneInstaller/Build-Installer.ps1` and `MarkplaneInstaller/Build-AgentInstaller.ps1`: package the VSIX before invoking Inno Setup.
- `MarkplaneInstaller/MarkplaneInstaller.iss` and `MarkplaneInstaller/MarkplaneAgentInstaller.iss`: include and pass the VSIX payload.
- `MarkplaneInstaller/tests/Install-AntigravityIntegration.Tests.ps1`: integration and health-check regression coverage.
- `MarkplaneInstaller/tests/Invoke-MarkplaneAntigravityHook.Tests.ps1`: hook adapter contract smoke tests.
- `MarkplaneInstaller/tests/Package-VSCodeExtension.Tests.ps1`: deterministic packaging tests.
- `MarkplaneInstaller/tests/Install-VSCodeExtension.Tests.ps1`: fake-CLI installation, verification, warning, and uninstall tests.
- `MarkplaneInstaller/README.md`: documents authoritative skills, current hooks, VSIX installation, reload, and build prerequisites.

### Task 1: Authoritative Plugin Reconciliation And Tool Mapping

**Files:**
- Modify: `MarkplaneInstaller/tests/Install-AntigravityIntegration.Tests.ps1`
- Modify: `MarkplaneInstaller/Install-AntigravityIntegration.ps1`
- Modify: `MarkplaneInstaller/skills/using-superpowers/references/antigravity-tools.md`

**Interfaces:**
- Consumes: `-SkillSourceRoot`, `-AgentsHintPath`, and the existing `markplane` plugin layout.
- Produces: exact `skills` tree, `rules/superpowers-antigravity.md`, and authoritative-version instructions in `GEMINI.md`.

- [x] **Step 1: Add failing integration assertions**

In the existing install test, split the two installer calls. After the first call, create a stale plugin skill, run the installer again, and add these assertions:

```powershell
& $installer -InstallDir $installDir -SkillSourceRoot $skills -AgentsHintPath $hint -SkipTelemetry
$pluginRoot = Join-Path $profile ".gemini\config\plugins\markplane"
$staleSkill = Join-Path $pluginRoot "skills\stale-upstream-copy"
New-Item -ItemType Directory -Force -Path $staleSkill | Out-Null
Set-Content -LiteralPath (Join-Path $staleSkill "SKILL.md") -Value "stale"

& $installer -InstallDir $installDir -SkillSourceRoot $skills -AgentsHintPath $hint -SkipTelemetry
$LASTEXITCODE | Should Be 0

(Test-Path -LiteralPath $staleSkill) | Should Be $false
$mappingRulePath = Join-Path $pluginRoot "rules\superpowers-antigravity.md"
(Test-Path -LiteralPath $mappingRulePath -PathType Leaf) | Should Be $true
$mappingRule = Get-Content -Raw -LiteralPath $mappingRulePath
$mappingRule | Should Match "invoke_subagent"
$mappingRule | Should Match 'TypeName.*self'
$mappingRule | Should Match 'TypeName.*research'
$mappingRule | Should Match 'ArtifactType.*task'
$mappingRule | Should Match "manage_task"

$gemini = Get-Content -Raw -LiteralPath (Join-Path $profile ".gemini\GEMINI.md")
$gemini | Should Match "Markplane plugin.*authoritative"
$gemini | Should Match "must not fetch, install, or upgrade Superpowers"

$sourceFiles = @(Get-ChildItem -LiteralPath $skills -Recurse -File)
$installedFiles = @(Get-ChildItem -LiteralPath (Join-Path $pluginRoot "skills") -Recurse -File)
$installedFiles.Count | Should Be $sourceFiles.Count
foreach ($sourceFile in $sourceFiles) {
    $relative = $sourceFile.FullName.Substring($skills.Length).TrimStart('\')
    $installedFile = Join-Path (Join-Path $pluginRoot "skills") $relative
    (Test-Path -LiteralPath $installedFile -PathType Leaf) | Should Be $true
    (Get-FileHash -Algorithm SHA256 -LiteralPath $installedFile).Hash |
        Should Be (Get-FileHash -Algorithm SHA256 -LiteralPath $sourceFile.FullName).Hash
}
```

- [x] **Step 2: Run the focused test and confirm RED**

Run:

```powershell
powershell -NoProfile -Command "Import-Module Pester -RequiredVersion 3.4.0; Invoke-Pester '.\MarkplaneInstaller\tests\Install-AntigravityIntegration.Tests.ps1' -PassThru"
```

Expected: at least one failure for the stale skill, missing `superpowers-antigravity.md`, or missing authoritative instruction.

- [x] **Step 3: Reconcile the complete owned tree and install the mapping rule**

Replace `Copy-BundledSkills` with validation followed by complete destination replacement:

```powershell
function Copy-BundledSkills {
    param(
        [Parameter(Mandatory = $true)][string]$SourceRoot,
        [Parameter(Mandatory = $true)][string]$DestinationRoot
    )

    $skills = @(Get-ChildItem -LiteralPath $SourceRoot -Directory)
    if ($skills.Count -eq 0) { throw "No bundled skills found in $SourceRoot" }
    foreach ($skill in $skills) {
        $skillFile = Join-Path $skill.FullName "SKILL.md"
        if (-not (Test-Path -LiteralPath $skillFile -PathType Leaf)) {
            throw "Bundled skill is missing SKILL.md: $skillFile"
        }
    }

    if (Test-Path -LiteralPath $DestinationRoot) {
        Remove-Item -LiteralPath $DestinationRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $DestinationRoot | Out-Null
    foreach ($skill in $skills) {
        Copy-Item -LiteralPath $skill.FullName -Destination (Join-Path $DestinationRoot $skill.Name) -Recurse -Force
    }
}
```

After copying skills, resolve the canonical mapping and write it as a plugin rule:

```powershell
$antigravityMappingPath = Join-Path $sourceRoot "using-superpowers\references\antigravity-tools.md"
if (-not (Test-Path -LiteralPath $antigravityMappingPath -PathType Leaf)) {
    throw "Antigravity Superpowers mapping was not found: $antigravityMappingPath"
}
[System.IO.File]::WriteAllText(
    (Join-Path $pluginRoot "rules\superpowers-antigravity.md"),
    [System.IO.File]::ReadAllText($antigravityMappingPath, [System.Text.UTF8Encoding]::new($false)),
    [System.Text.UTF8Encoding]::new($false)
)
```

Add this exact section to `$geminiBlock` and to the generated router rule text:

```markdown
## Authoritative Superpowers bundle

The Superpowers skills bundled inside the Markplane plugin are authoritative. Load `using-superpowers` and every selected Superpowers skill from that plugin. Preserve but do not prefer same-named external copies. You must not fetch, install, or upgrade Superpowers from the internet.
```

- [x] **Step 4: Complete the canonical subagent mapping**

Add this missing section before `## Task tracking` in `antigravity-tools.md`:

```markdown
## Subagent support

Use `invoke_subagent` with a `Subagents` array. Each entry provides `Prompt`, `Role`, and `TypeName`; use `self` for full-capability implementation or review work and `research` for read-only investigation. Keep prompts self-contained and pass `Workspace` only when the subagent needs a specific mounted workspace. Results return through the invocation; use `manage_subagents` only to list or terminate active subagents.
```

- [x] **Step 5: Run the focused test and confirm GREEN**

Run the Step 2 command again.

Expected: all tests in `Install-AntigravityIntegration.Tests.ps1` pass.

- [x] **Step 6: Record the task checkpoint**

```powershell
.\MarkplaneInstaller\markplane.exe sync
.\MarkplaneInstaller\markplane.exe check
```

Expected: sync succeeds and check reports no broken references. In a Git checkout, additionally commit these three files with `feat: prioritize bundled superpowers in antigravity`.

### Task 2: Exact Health Check And Non-Destructive Conflict Warning

**Files:**
- Modify: `MarkplaneInstaller/tests/Install-AntigravityIntegration.Tests.ps1`
- Modify: `MarkplaneInstaller/Test-MarkplaneAgentSkills.ps1`

**Interfaces:**
- Consumes: package `skills` root, Gemini root, and installed `markplane` plugin.
- Produces: exit code `1` for owned drift, exit code `0` plus warning for intact owned files with same-named external copies.

- [x] **Step 1: Add failing drift and conflict tests**

After the initial health-check success in the installer test, append:

```powershell
$geminiRoot = Join-Path $profile ".gemini"
$externalRouter = Join-Path $geminiRoot "config\skills\using-superpowers"
New-Item -ItemType Directory -Force -Path $externalRouter | Out-Null
Set-Content -LiteralPath (Join-Path $externalRouter "SKILL.md") -Value "external"

$warningOutput = (& $healthCheck -SkipCodex -SkipClaude -GeminiRoot $geminiRoot -SkillSourceRoot $skills -SkipTelemetry) | Out-String
$LASTEXITCODE | Should Be 0
$warningOutput | Should Match "same-named external skill"

$installedRouter = Join-Path $geminiRoot "config\plugins\markplane\skills\using-superpowers\SKILL.md"
Add-Content -LiteralPath $installedRouter -Value "drift"
& $healthCheck -SkipCodex -SkipClaude -GeminiRoot $geminiRoot -SkillSourceRoot $skills -SkipTelemetry
$LASTEXITCODE | Should Be 1

& $installer -InstallDir $installDir -SkillSourceRoot $skills -AgentsHintPath $hint -SkipTelemetry
& $healthCheck -SkipCodex -SkipClaude -GeminiRoot $geminiRoot -SkillSourceRoot $skills -SkipTelemetry
$LASTEXITCODE | Should Be 0
```

- [x] **Step 2: Run the integration test and confirm RED**

Run the Task 1 Step 2 command.

Expected: failure because `-SkillSourceRoot` and recursive parity validation do not exist.

- [x] **Step 3: Implement deterministic manifests and warnings**

Add `[string]$SkillSourceRoot = (Join-Path $PSScriptRoot "skills")` to the health-check parameters. Add a warning collection and these helpers:

```powershell
function Get-TreeManifest {
    param([Parameter(Mandatory = $true)][string]$Root)
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) { return $null }
    $resolved = (Resolve-Path -LiteralPath $Root).Path
    $manifest = @{}
    foreach ($file in Get-ChildItem -LiteralPath $resolved -Recurse -File) {
        $relative = $file.FullName.Substring($resolved.Length).TrimStart('\')
        $manifest[$relative] = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
    }
    return $manifest
}

function Add-TreeParityIssues {
    param([string]$Label, [string]$ExpectedRoot, [string]$ActualRoot, [System.Collections.ArrayList]$Issues)
    $expected = Get-TreeManifest -Root $ExpectedRoot
    $actual = Get-TreeManifest -Root $ActualRoot
    if ($null -eq $expected) { [void]$Issues.Add("Missing $Label source: $ExpectedRoot"); return }
    if ($null -eq $actual) { [void]$Issues.Add("Missing $Label installation: $ActualRoot"); return }
    foreach ($path in @($expected.Keys + $actual.Keys | Sort-Object -Unique)) {
        if (-not $expected.ContainsKey($path)) { [void]$Issues.Add("$Label has extra file: $path") }
        elseif (-not $actual.ContainsKey($path)) { [void]$Issues.Add("$Label is missing file: $path") }
        elseif ($expected[$path] -ne $actual[$path]) { [void]$Issues.Add("$Label differs: $path") }
    }
}
```

Under the Antigravity branch, compare `$SkillSourceRoot` with the plugin skills, validate `superpowers-antigravity.md`, and inspect canonical and legacy external roots for bundled skill names. Write warnings before the failure block:

```powershell
Add-TreeParityIssues -Label "Gemini Markplane plugin skills" -ExpectedRoot $SkillSourceRoot -ActualRoot (Join-Path $GeminiRoot "config\plugins\markplane\skills") -Issues $issues

$warnings = New-Object System.Collections.ArrayList
foreach ($externalRoot in @((Join-Path $GeminiRoot "config\skills"), (Join-Path $GeminiRoot "skills"))) {
    foreach ($skill in Get-ChildItem -LiteralPath $SkillSourceRoot -Directory -ErrorAction SilentlyContinue) {
        if (Test-Path -LiteralPath (Join-Path $externalRoot $skill.Name) -PathType Container) {
            [void]$warnings.Add("Found same-named external skill '$($skill.Name)' in $externalRoot; the Markplane plugin copy remains authoritative.")
        }
    }
}
foreach ($warning in $warnings) { Write-Host "WARNING: $warning" }
```

- [x] **Step 4: Run the test and confirm GREEN**

Run the Task 1 Step 2 command.

Expected: all tests pass; deliberate drift produces the expected temporary health-check failure and the repaired final check passes.

- [x] **Step 5: Record the task checkpoint**

Run Markplane sync and check. In a Git checkout, commit with `test: verify antigravity skill bundle integrity`.

### Task 3: Current Antigravity Hook Schema And Adapter Contracts

**Files:**
- Modify: `MarkplaneInstaller/tests/Install-AntigravityIntegration.Tests.ps1`
- Create: `MarkplaneInstaller/tests/Invoke-MarkplaneAntigravityHook.Tests.ps1`
- Modify: `MarkplaneInstaller/Install-AntigravityIntegration.ps1`

**Interfaces:**
- Consumes: documented Antigravity camelCase hook payloads.
- Produces: direct `PreInvocation`/`Stop` handlers, matched `PostToolUse`, `{}` for non-injecting events, and `allow`/`continue` Stop decisions.

- [x] **Step 1: Change installer assertions to the current schema**

Replace the old nested `PreInvocation` assertion with:

```powershell
$hooksJson.markplane.PreInvocation[0].command | Should Match "Invoke-MarkplaneAntigravityHook.ps1"
$hooksJson.markplane.PreInvocation[0].PSObject.Properties["hooks"] | Should BeNullOrEmpty
$hooksJson.markplane.PostToolUse[0].matcher | Should Match "write_to_file"
$hooksJson.markplane.PostToolUse[0].hooks[0].command | Should Match "Invoke-MarkplaneAntigravityHook.ps1"
$hooksJson.markplane.Stop[0].command | Should Match "Invoke-MarkplaneAntigravityHook.ps1"
$hooksJson.markplane.Stop[0].PSObject.Properties["hooks"] | Should BeNullOrEmpty
```

Create `Invoke-MarkplaneAntigravityHook.Tests.ps1` with:

```powershell
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$adapter = Join-Path $root "hooks\Invoke-MarkplaneAntigravityHook.ps1"
$markplane = Join-Path $root "markplane.exe"

Describe "Antigravity hook adapter contract" {
    It "returns empty output for later PreInvocation calls" {
        $json = '{"invocationNum":1,"conversationId":"later","workspacePaths":[]}' |
            powershell -NoProfile -ExecutionPolicy Bypass -File $adapter -Event PreInvocation -MarkplaneExe $markplane
        ($json | ConvertFrom-Json).PSObject.Properties.Count | Should Be 0
    }

    It "returns an empty object for PostToolUse outside a Markplane project" {
        $json = ('{"stepIdx":2,"conversationId":"post","workspacePaths":["' + ($TestDrive -replace '\\','\\') + '"]}') |
            powershell -NoProfile -ExecutionPolicy Bypass -File $adapter -Event PostToolUse -MarkplaneExe $markplane
        ($json | ConvertFrom-Json).PSObject.Properties.Count | Should Be 0
    }

    It "allows Stop outside a Markplane project" {
        $json = ('{"executionNum":1,"terminationReason":"model_stop","fullyIdle":true,"conversationId":"stop","workspacePaths":["' + ($TestDrive -replace '\\','\\') + '"]}') |
            powershell -NoProfile -ExecutionPolicy Bypass -File $adapter -Event Stop -MarkplaneExe $markplane
        ($json | ConvertFrom-Json).decision | Should Be "allow"
    }
}
```

- [x] **Step 2: Run both focused files and confirm RED**

```powershell
powershell -NoProfile -Command "Import-Module Pester -RequiredVersion 3.4.0; Invoke-Pester @('.\MarkplaneInstaller\tests\Install-AntigravityIntegration.Tests.ps1','.\MarkplaneInstaller\tests\Invoke-MarkplaneAntigravityHook.Tests.ps1') -PassThru"
```

Expected: installer test fails because direct handlers are not present.

- [x] **Step 3: Separate direct handlers from matched entries**

Replace `New-AntigravityHookEntry` with a handler-only function:

```powershell
function New-AntigravityHookHandler {
    param(
        [Parameter(Mandatory = $true)][string]$Event,
        [Parameter(Mandatory = $true)][string]$HookScriptPath,
        [Parameter(Mandatory = $true)][string]$MarkplaneExePath,
        [int]$MaxContextChars
    )
    $arguments = @("-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", $HookScriptPath, "-Event", $Event, "-MarkplaneExe", $MarkplaneExePath, "-MaxContextChars", [string]$MaxContextChars)
    $command = "powershell.exe " + (($arguments | ForEach-Object { Quote-HookArgument -Argument $_ }) -join " ")
    return [pscustomobject]@{ type = "command"; command = $command; timeout = 15 }
}
```

Build the event object with the documented shapes:

```powershell
$preInvocation = New-AntigravityHookHandler -Event "PreInvocation" -HookScriptPath $HookScriptPath -MarkplaneExePath $MarkplaneExePath -MaxContextChars $MaxContextChars
$postToolUse = New-AntigravityHookHandler -Event "PostToolUse" -HookScriptPath $HookScriptPath -MarkplaneExePath $MarkplaneExePath -MaxContextChars $MaxContextChars
$stop = New-AntigravityHookHandler -Event "Stop" -HookScriptPath $HookScriptPath -MarkplaneExePath $MarkplaneExePath -MaxContextChars $MaxContextChars
Add-Member -InputObject $settings -NotePropertyName "markplane" -NotePropertyValue ([pscustomobject]@{
    PreInvocation = @($preInvocation)
    PostToolUse = @([pscustomobject]@{
        matcher = "write_to_file|replace_file_content|multi_replace_file_content|run_command|mcp_.*markplane.*"
        hooks = @($postToolUse)
    })
    Stop = @($stop)
}) -Force
```

- [x] **Step 4: Run both focused files and confirm GREEN**

Run the Step 2 command.

Expected: both files pass with zero failures.

- [x] **Step 5: Record the task checkpoint**

Run Markplane sync and check. In a Git checkout, commit with `fix: update antigravity hook schema`.

### Task 4: Deterministic Build-Time VSIX Packaging

**Files:**
- Create: `MarkplaneInstaller/Package-VSCodeExtension.ps1`
- Create: `MarkplaneInstaller/tests/Package-VSCodeExtension.Tests.ps1`
- Modify: `MarkplaneInstaller/Build-Installer.ps1`
- Modify: `MarkplaneInstaller/Build-AgentInstaller.ps1`
- Modify: `MarkplaneInstaller/MarkplaneInstaller.iss`
- Modify: `MarkplaneInstaller/MarkplaneAgentInstaller.iss`

**Interfaces:**
- Consumes: `vscode-extension/package.json` version `0.1.2` and either `vsce` or `npx` in the build environment.
- Produces: `MarkplaneInstaller/vscode-extension/markplane-vscode-0.1.2.vsix` before Inno compilation.

- [x] **Step 1: Write a failing packaging test**

Create `Package-VSCodeExtension.Tests.ps1`:

```powershell
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$packager = Join-Path $root "Package-VSCodeExtension.ps1"

Describe "VSIX packaging" {
    It "packages the deterministic VSIX path through an injected vsce command" {
        $source = Join-Path $TestDrive "extension"
        New-Item -ItemType Directory -Force -Path $source | Out-Null
        Set-Content -LiteralPath (Join-Path $source "package.json") -Value '{"name":"markplane-vscode","publisher":"local","version":"0.1.2","engines":{"vscode":"^1.85.0"}}'
        $fakeVsce = Join-Path $TestDrive "fake-vsce.ps1"
        Set-Content -LiteralPath $fakeVsce -Value @'
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Remaining)
$index = [Array]::IndexOf($Remaining, "--out")
if ($index -lt 0) { exit 2 }
[System.IO.File]::WriteAllText($Remaining[$index + 1], "fake-vsix")
'@
        $output = Join-Path $TestDrive "markplane-vscode-0.1.2.vsix"

        & $packager -ExtensionSource $source -OutputPath $output -VsceCommand $fakeVsce

        $LASTEXITCODE | Should Be 0
        (Test-Path -LiteralPath $output -PathType Leaf) | Should Be $true
    }

    It "wires both installer builds and payloads to the VSIX" {
        foreach ($build in @("Build-Installer.ps1", "Build-AgentInstaller.ps1")) {
            (Get-Content -Raw -LiteralPath (Join-Path $root $build)) | Should Match "Package-VSCodeExtension.ps1"
        }
        foreach ($iss in @("MarkplaneInstaller.iss", "MarkplaneAgentInstaller.iss")) {
            $text = Get-Content -Raw -LiteralPath (Join-Path $root $iss)
            $text | Should Match "markplane-vscode-0.1.2.vsix"
            $text | Should Not Match 'Source: "vscode-extension\\\*"'
        }
    }
}
```

- [x] **Step 2: Run the packaging test and confirm RED**

```powershell
powershell -NoProfile -Command "Import-Module Pester -RequiredVersion 3.4.0; Invoke-Pester '.\MarkplaneInstaller\tests\Package-VSCodeExtension.Tests.ps1' -PassThru"
```

Expected: failures because the packager and VSIX wiring do not exist.

- [x] **Step 3: Implement the packager**

Create `Package-VSCodeExtension.ps1` with explicit source, output, and optional command resolution:

```powershell
[CmdletBinding()]
param(
    [string]$ExtensionSource = (Join-Path $PSScriptRoot "vscode-extension"),
    [string]$OutputPath = (Join-Path $PSScriptRoot "vscode-extension\markplane-vscode-0.1.2.vsix"),
    [string]$VsceCommand
)
$ErrorActionPreference = "Stop"
$source = (Resolve-Path -LiteralPath $ExtensionSource -ErrorAction Stop).Path
$outputDirectory = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
$output = [System.IO.Path]::GetFullPath($OutputPath)

$arguments = @("package", "--out", $output)
if (-not $VsceCommand) {
    $vsce = Get-Command vsce.cmd -ErrorAction SilentlyContinue
    if ($vsce) { $VsceCommand = $vsce.Source }
    else {
        $npx = Get-Command npx.cmd -ErrorAction SilentlyContinue
        if (-not $npx) { throw "Neither vsce.cmd nor npx.cmd was found in the build environment." }
        $VsceCommand = $npx.Source
        $arguments = @("--yes", "@vscode/vsce", "package", "--out", $output)
    }
}

Push-Location $source
try {
    $global:LASTEXITCODE = 0
    & $VsceCommand @arguments
    if ($LASTEXITCODE -ne 0) { throw "VSIX packaging failed with exit code $LASTEXITCODE." }
} finally { Pop-Location }
if (-not (Test-Path -LiteralPath $output -PathType Leaf)) { throw "VSIX was not created: $output" }
Write-Host "Packaged VSIX: $output"
$global:LASTEXITCODE = 0
```

- [x] **Step 4: Wire both builds and Inno payloads**

Before invoking `ISCC.exe` in both build scripts, run:

```powershell
& (Join-Path $scriptDir "Package-VSCodeExtension.ps1")
if ($LASTEXITCODE -ne 0) { throw "VSIX packaging failed with exit code $LASTEXITCODE." }
```

In both `.iss` files replace the recursive source-folder line with:

```text
Source: "vscode-extension\markplane-vscode-0.1.2.vsix"; DestDir: "{app}\vscode-extension"; Flags: ignoreversion
```

- [x] **Step 5: Run the packaging test and confirm GREEN**

Run the Step 2 command.

Expected: both tests pass.

- [x] **Step 6: Record the task checkpoint**

Run Markplane sync and check. In a Git checkout, commit with `build: package markplane extension as vsix`.

### Task 5: CLI-Based Extension Install, Verification, And Uninstall

**Files:**
- Modify: `MarkplaneInstaller/tests/Install-VSCodeExtension.Tests.ps1`
- Modify: `MarkplaneInstaller/Install-VSCodeExtension.ps1`
- Modify: `MarkplaneInstaller/MarkplaneInstaller.iss`
- Modify: `MarkplaneInstaller/MarkplaneAgentInstaller.iss`

**Interfaces:**
- Consumes: `-VsixPath`, optional `-VSCodeCli` and `-AntigravityCli`, skip switches, and `-Uninstall`.
- Produces: registered `local.markplane-vscode` extension or a visible missing-CLI warning without folder-copy fallback.

- [x] **Step 1: Replace copy-based tests with fake CLI tests**

Use a helper inside `Install-VSCodeExtension.Tests.ps1`:

```powershell
function New-FakeExtensionCli {
    param([string]$Path, [string]$LogPath)
    Set-Content -LiteralPath $Path -Value @"
@echo off
echo %*>>"$LogPath"
if "%1"=="--list-extensions" echo local.markplane-vscode@0.1.2
exit /b 0
"@
}
```

Replace the existing tests with install/verify/uninstall coverage:

```powershell
Describe "Markplane VS Code family extension installer" {
    It "installs verifies and uninstalls through both IDE CLIs" {
        $vsix = Join-Path $TestDrive "markplane-vscode-0.1.2.vsix"
        Set-Content -LiteralPath $vsix -Value "fake"
        $log = Join-Path $TestDrive "cli.log"
        $codeCli = Join-Path $TestDrive "code.cmd"
        $antigravityCli = Join-Path $TestDrive "antigravity-ide.cmd"
        New-FakeExtensionCli -Path $codeCli -LogPath $log
        New-FakeExtensionCli -Path $antigravityCli -LogPath $log

        & $installer -VsixPath $vsix -VSCodeCli $codeCli -AntigravityCli $antigravityCli
        $LASTEXITCODE | Should Be 0
        $calls = Get-Content -Raw -LiteralPath $log
        @([regex]::Matches($calls, "--install-extension")).Count | Should Be 2
        @([regex]::Matches($calls, "--force")).Count | Should Be 2
        @([regex]::Matches($calls, "--list-extensions")).Count | Should Be 2

        & $installer -VSCodeCli $codeCli -AntigravityCli $antigravityCli -Uninstall
        $LASTEXITCODE | Should Be 0
        $calls = Get-Content -Raw -LiteralPath $log
        @([regex]::Matches($calls, "--uninstall-extension local.markplane-vscode")).Count | Should Be 2
    }

    It "warns when Antigravity IDE is absent without copying folders" {
        $vsix = Join-Path $TestDrive "markplane-vscode-0.1.2.vsix"
        Set-Content -LiteralPath $vsix -Value "fake"
        $log = Join-Path $TestDrive "code.log"
        $codeCli = Join-Path $TestDrive "code.cmd"
        New-FakeExtensionCli -Path $codeCli -LogPath $log

        $output = (& $installer -VsixPath $vsix -VSCodeCli $codeCli -AntigravityCli (Join-Path $TestDrive "missing.cmd")) | Out-String

        $LASTEXITCODE | Should Be 0
        $output | Should Match "Antigravity IDE CLI was not found"
        (Test-Path -LiteralPath (Join-Path $TestDrive "extensions")) | Should Be $false
    }
}
```

- [x] **Step 2: Run the extension test and confirm RED**

```powershell
powershell -NoProfile -Command "Import-Module Pester -RequiredVersion 3.4.0; Invoke-Pester '.\MarkplaneInstaller\tests\Install-VSCodeExtension.Tests.ps1' -PassThru"
```

Expected: parameter-binding failures for `-VsixPath`, `-VSCodeCli`, or `-AntigravityCli`.

- [x] **Step 3: Replace folder copying with CLI resolution and invocation**

Use this parameter surface:

```powershell
param(
    [string]$VsixPath,
    [string]$ExtensionId = "local.markplane-vscode",
    [string]$VSCodeCli,
    [string]$AntigravityCli,
    [switch]$SkipVSCode,
    [switch]$SkipAntigravity,
    [switch]$Uninstall
)
```

Implement command resolution and checked execution:

```powershell
function Resolve-Cli {
    param([string]$ExplicitPath, [string[]]$CommandNames, [string[]]$Candidates)
    if ($ExplicitPath) {
        if (Test-Path -LiteralPath $ExplicitPath -PathType Leaf) { return (Resolve-Path -LiteralPath $ExplicitPath).Path }
        return $null
    }
    foreach ($name in $CommandNames) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
    }
    foreach ($candidate in $Candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) { return $candidate }
    }
    return $null
}

function Invoke-ExtensionCli {
    param([string]$Label, [string]$Cli, [string[]]$Arguments)
    $output = @(& $Cli @Arguments 2>&1)
    $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
    if ($exitCode -ne 0) { throw "$Label CLI failed with exit code ${exitCode}: $($output -join [Environment]::NewLine)" }
    return $output
}
```

Resolve VS Code from `code.cmd`/`code` and Antigravity from `antigravity-ide.cmd`, `agy-ide.cmd`, and `$env:LOCALAPPDATA\Programs\Antigravity IDE\bin\antigravity-ide.cmd`. For each enabled and available CLI:

```powershell
if ($Uninstall) {
    [void](Invoke-ExtensionCli -Label $target.Label -Cli $target.Cli -Arguments @("--uninstall-extension", $ExtensionId))
    Write-Step "Uninstalled $ExtensionId from $($target.Label)"
    continue
}

[void](Invoke-ExtensionCli -Label $target.Label -Cli $target.Cli -Arguments @("--install-extension", $resolvedVsix, "--force"))
$registered = @(Invoke-ExtensionCli -Label $target.Label -Cli $target.Cli -Arguments @("--list-extensions", "--show-versions"))
if (-not ($registered -match "^$([regex]::Escape($ExtensionId))(@|$)")) {
    throw "$ExtensionId was not registered by $($target.Label)."
}
Write-Step "Installed and verified $ExtensionId in $($target.Label)"
```

When a target CLI is absent, use `Write-Warning`; never call `Copy-Item`. On successful installation print:

```text
Run Developer: Reload Window in each open IDE window to activate the Markplane interface.
```

- [x] **Step 4: Pass the bundled VSIX from both Inno installers**

Change both `[Run]` entries to:

```text
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Install-VSCodeExtension.ps1"" -VsixPath ""{app}\vscode-extension\markplane-vscode-0.1.2.vsix"""; Description: "Install Markplane VS Code and Antigravity IDE integration"; Flags: runhidden waituntilterminated
```

Keep `[UninstallRun]` calling `-Uninstall`; the script does not require the VSIX to uninstall by extension ID.

- [x] **Step 5: Run the extension test and confirm GREEN**

Run the Step 2 command.

Expected: both tests pass and logs show install, list, force, and uninstall calls.

- [x] **Step 6: Record the task checkpoint**

Run Markplane sync and check. In a Git checkout, commit with `fix: install markplane interface through vsix`.

### Task 6: Documentation, Full Regression, And Local Smoke Verification

**Files:**
- Modify: `MarkplaneInstaller/README.md`
- Update: `PLAN-48fdt` completion checklist and evidence during execution.

**Interfaces:**
- Consumes: all preceding task outputs.
- Produces: documented behavior and verification evidence sufficient to close `TASK-cv9gy`.

- [x] **Step 1: Update installer documentation**

Document these exact outcomes in `README.md`:

```markdown
- Antigravity uses the customized Superpowers bundle shipped with Markplane; the installer never downloads an upstream replacement.
- `Test-MarkplaneAgentSkills.ps1` verifies the complete installed Antigravity skill tree and warns without deleting same-named external skills.
- The Markplane interface is packaged as `markplane-vscode-0.1.2.vsix` during installer builds and installed with `--install-extension ... --force` through VS Code and Antigravity IDE CLIs.
- End users do not need Node.js or `npx`. If an IDE CLI is unavailable, use `markplane serve`; after a successful VSIX install, run `Developer: Reload Window`.
```

Remove claims that direct extension-root copying is supported.

- [x] **Step 2: Parse every changed PowerShell file**

```powershell
$files = @(
    '.\MarkplaneInstaller\Install-AntigravityIntegration.ps1',
    '.\MarkplaneInstaller\Test-MarkplaneAgentSkills.ps1',
    '.\MarkplaneInstaller\Package-VSCodeExtension.ps1',
    '.\MarkplaneInstaller\Install-VSCodeExtension.ps1',
    '.\MarkplaneInstaller\Build-Installer.ps1',
    '.\MarkplaneInstaller\Build-AgentInstaller.ps1',
    '.\MarkplaneInstaller\hooks\Invoke-MarkplaneAntigravityHook.ps1'
)
foreach ($file in $files) {
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $file), [ref]$null, [ref]$errors)
    if ($errors.Count -gt 0) { throw "$file parse errors: $($errors.Message -join '; ')" }
}
```

Expected: no exception.

- [x] **Step 3: Run all focused tests together**

```powershell
powershell -NoProfile -Command "Import-Module Pester -RequiredVersion 3.4.0; Invoke-Pester @('.\MarkplaneInstaller\tests\Install-AntigravityIntegration.Tests.ps1','.\MarkplaneInstaller\tests\Invoke-MarkplaneAntigravityHook.Tests.ps1','.\MarkplaneInstaller\tests\Package-VSCodeExtension.Tests.ps1','.\MarkplaneInstaller\tests\Install-VSCodeExtension.Tests.ps1') -PassThru"
```

Expected: zero failed tests.

- [x] **Step 4: Run the complete Pester suite**

```powershell
powershell -NoProfile -Command "Import-Module Pester -RequiredVersion 3.4.0; Invoke-Pester '.\MarkplaneInstaller\tests' -PassThru"
```

Expected: `FailedCount` is `0`.

- [x] **Step 5: Build the real VSIX**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\MarkplaneInstaller\Package-VSCodeExtension.ps1
```

Expected: `MarkplaneInstaller\vscode-extension\markplane-vscode-0.1.2.vsix` exists and the command exits `0`. This command may download `@vscode/vsce` only in the build environment when `vsce.cmd` is absent.

- [x] **Step 6: Build both Inno installers when the compiler prerequisite is available**

**Executed (2026-08-04):** Inno Setup 6.7.3 was found under the user-local Programs directory. Both build commands completed successfully after removing their exact stale outputs, and fresh installer executables were produced.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\MarkplaneInstaller\Build-Installer.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\MarkplaneInstaller\Build-AgentInstaller.ps1
```

Verified: `MarkplaneInstaller\Output\MarkplaneSetup-0.1.2.exe` and `MarkplaneInstaller\Output\MarkplaneAgentSetup-0.1.2.exe` exist as fresh Inno 6.7.3 outputs.

- [x] **Step 7: Apply and verify the local Antigravity integration**

After receiving permission to modify the user profile, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\MarkplaneInstaller\Install-AntigravityIntegration.ps1 -InstallDir .\MarkplaneInstaller -SkillSourceRoot .\MarkplaneInstaller\skills -AgentsHintPath .\MarkplaneInstaller\research-checkpoint-agents-extension.txt
powershell -NoProfile -ExecutionPolicy Bypass -File .\MarkplaneInstaller\Install-VSCodeExtension.ps1 -VsixPath .\MarkplaneInstaller\vscode-extension\markplane-vscode-0.1.2.vsix -SkipVSCode
powershell -NoProfile -ExecutionPolicy Bypass -File .\MarkplaneInstaller\Test-MarkplaneAgentSkills.ps1 -SkipCodex -SkipClaude -SkillSourceRoot .\MarkplaneInstaller\skills
& "$env:LOCALAPPDATA\Programs\Antigravity IDE\bin\antigravity-ide.cmd" --list-extensions --show-versions | Select-String '^local\.markplane-vscode@0\.1\.2$'
```

Expected: health check passes and Antigravity lists `local.markplane-vscode@0.1.2`. Tell the user to run `Developer: Reload Window` in open Antigravity IDE windows.

- [x] **Step 8: Close Markplane with evidence**

Update `PLAN-48fdt` and `TASK-cv9gy` with exact test counts, parser result, VSIX path, local CLI verification, and any Inno prerequisite limitation. Then run:

```powershell
.\MarkplaneInstaller\markplane.exe sync
.\MarkplaneInstaller\markplane.exe check
.\MarkplaneInstaller\markplane.exe done TASK-cv9gy
```

Mark the task done only when all required implementation and available verification steps pass. In a Git checkout, commit documentation and final evidence with `docs: document antigravity superpowers and vsix integration`.
