# Research With Coding Agents Public Repository Implementation Plan
> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
**Goal:** Convert the local Markplane/Superpowers package into the public Research With Coding Agents source and Windows distribution.
**Architecture:** Keep the existing working installer/windows scripts as the first delivery path, then introduce the public repository envelope around them. The installer consumes only local, pinned payloads, registers the Markplane UI through VSIX CLI installation, and makes the project-maintained Superpowers copy authoritative for Codex, Claude Code, and Gemini/Antigravity.
**Tech Stack:** PowerShell 5.1+, Pester, Inno Setup 6, Rust/Cargo, Node.js/npm, `@vscode/vsce`, component source provenance, SPDX JSON, GitHub Actions.
## Global Constraints
- Product name: `Research With Coding Agents`.
- Main repository slug: `research-with-coding-agents`.
- Main repository license: Apache License 2.0.
- Markplane upstream: `https://github.com/zerowand01/markplane`, Apache-2.0.
- Superpowers upstream: `https://github.com/obra/superpowers`, MIT.
- Windows core install root: `%LOCALAPPDATA%\Programs\ResearchWithCodingAgents\`.
- User extension root: `%USERPROFILE%\.research-with-coding-agents\extensions\`.
- Standard Windows artifacts: `ResearchWithCodingAgentsSetup-v0.1.0.exe`, `ResearchWithCodingAgentsPortable-v0.1.0-win-x64.zip`, `SHA256SUMS.txt`, `SBOM.spdx.json`.
- End-user installer uses bundled payloads only and performs no network source downloads.
- Markplane UI extension deployment uses `--install-extension <vsix> --force` through IDE CLIs only; direct extension-folder copying is forbidden.
- Managed agent sessions keep `SUPERPOWERS_DISABLE_TELEMETRY=1`.
- Foreign Superpowers installations are detected and preserved, never deleted.
- Uninstall preserves project `.markplane` directories, local user extensions, unrelated agent configuration, and foreign Superpowers copies.
- macOS/Linux are experimental for the first public release.
---
## File Structure
- Root public files: `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, `UPSTREAM.md`, `LICENSE`, `THIRD_PARTY_NOTICES.md`, `.gitignore`, `.gitattributes`, `CLAUDE.md`.
- Legal/package docs: `LICENSES/*.txt`, `components/README.md`, `packages/**/README.md`, `extensions/README.md`.
- Release scripts: `scripts/Get-RwcaProvenance.ps1`, `scripts/Test-RwcaDistributionReadiness.ps1`, `scripts/New-RwcaChecksums.ps1`, `scripts/New-RwcaSbom.ps1`, `scripts/Build-RwcaRelease.ps1`.
- Tests: `tests/RwcaProvenance.Tests.ps1`, `tests/RwcaDistributionReadiness.Tests.ps1`, `tests/RwcaInstallerNaming.Tests.ps1`, plus existing `installer/windows/tests/*.Tests.ps1`.
- Installer changes: `installer/windows/Build-Installer.ps1`, `installer/windows/MarkplaneInstaller.iss`, `installer/windows/README.md`, install/integration scripts, VSIX packaging script.
- GitHub files: `.github/workflows/*.yml`, `.github/ISSUE_TEMPLATE/*.yml`, `.github/pull_request_template.md`.
### Task 1: Public Repository Envelope
**Files:**
- Create: root documentation, license, notices, ignore, component/package README files listed in File Structure.
- Test: `tests/RwcaDistributionReadiness.Tests.ps1`
**Interfaces:**
- Produces: `Test-RwcaDistributionReadiness.ps1 -RepoRoot <path>` exits `0` only when required public files exist and product naming is consistent.
- [ ] **Step 1: Write failing repository-readiness tests**
Create `tests/RwcaDistributionReadiness.Tests.ps1` with Pester assertions that these files exist: `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, `UPSTREAM.md`, `LICENSE`, `THIRD_PARTY_NOTICES.md`, `.gitignore`, `.gitattributes`, `CLAUDE.md`, `components/README.md`, `packages/README.md`, `extensions/README.md`.
- [ ] **Step 2: Run test to verify it fails**
Run: `Invoke-Pester .\tests\RwcaDistributionReadiness.Tests.ps1 -Output Detailed`
Expected: FAIL because root public repository files are missing.
- [ ] **Step 3: Add public repository files**
Add concise public docs that state the product name, Windows-first install path, recursive clone command, experimental macOS/Linux status, local extension root, and that Markplane/Superpowers live in maintained forks pinned by the main repository.
- [ ] **Step 4: Run test to verify it passes**
Run: `Invoke-Pester .\tests\RwcaDistributionReadiness.Tests.ps1 -Output Detailed`
Expected: PASS.
- [ ] **Step 5: Sync Markplane**
Run: `C:\Users\scheurer\.cargo\bin\markplane.exe sync`
Expected: command exits `0`.
### Task 2: License And Provenance Gate
**Files:**
- Create: `scripts/Get-RwcaProvenance.ps1`, `LICENSES/*.txt`, `tests/RwcaProvenance.Tests.ps1`.
- Modify: `THIRD_PARTY_NOTICES.md`.
**Interfaces:**
- Produces: `Get-RwcaProvenance -RepoRoot <path>` returns objects with `Name`, `LocalPath`, `UpstreamUrl`, `License`, `LicenseFile`, `PinnedCommit`, `Modified`.
- Produces: `Test-RwcaDistributionReadiness.ps1` rejects a shipped component with no license file or upstream URL.
- [ ] **Step 1: Write failing provenance tests**
Assert that `Markplane`, `Superpowers`, and `research-repo-governance` appear in `THIRD_PARTY_NOTICES.md`, have license files under `LICENSES/`, and expose upstream URLs matching the Global Constraints.
- [ ] **Step 2: Run test to verify it fails**
Run: `Invoke-Pester .\tests\RwcaProvenance.Tests.ps1 -Output Detailed`
Expected: FAIL until licenses and notices exist.
- [ ] **Step 3: Add license and notices**
Add Apache-2.0 for the main repo, unmodified Apache-2.0 text for Markplane, unmodified MIT text for Superpowers including Jesse Vincent copyright, and MIT attribution for research-repo-governance.
- [ ] **Step 4: Implement provenance reader**
Implement `Get-RwcaProvenance` so release scripts can read notice rows and fail if `LicenseFile` does not exist.
- [ ] **Step 5: Run provenance tests**
Run: `Invoke-Pester .\tests\RwcaProvenance.Tests.ps1 -Output Detailed`
Expected: PASS.
### Task 3: Unified Installer Identity
**Files:**
- Modify: `installer/windows/Build-Installer.ps1`, `installer/windows/MarkplaneInstaller.iss`, `installer/windows/README.md`.
- Test: `installer/windows/tests/Build-Installer.Tests.ps1`, `tests/RwcaInstallerNaming.Tests.ps1`.
**Interfaces:**
- Produces: installer output `installer/windows/Output/ResearchWithCodingAgentsSetup-v0.1.0.exe`.
- Keeps: existing `-InnoSetupCompiler <path>` test hook.
- [ ] **Step 1: Write failing installer naming tests**
Assert that `MarkplaneInstaller.iss` contains `AppName=Research With Coding Agents`, `DefaultDirName={localappdata}\Programs\ResearchWithCodingAgents`, and `OutputBaseFilename=ResearchWithCodingAgentsSetup-v0.1.0`.
- [ ] **Step 2: Run tests to verify failure**
Run: `Invoke-Pester .\tests\RwcaInstallerNaming.Tests.ps1,.\installer\windows\tests\Build-Installer.Tests.ps1 -Output Detailed`
Expected: FAIL because current installer is still named Markplane.
- [ ] **Step 3: Rename setup metadata**
Update Inno metadata and `Build-Installer.ps1` expected output to `ResearchWithCodingAgentsSetup-v0.1.0.exe`; keep the existing AppId unless a clean product break is intentionally required before release.
- [ ] **Step 4: Run installer naming tests**
Run: `Invoke-Pester .\tests\RwcaInstallerNaming.Tests.ps1,.\installer\windows\tests\Build-Installer.Tests.ps1 -Output Detailed`
Expected: PASS.
### Task 4: Authoritative Superpowers For All Agents
**Files:**
- Modify: `installer/windows/Install-MarkplaneAgentSkills.ps1`, `installer/windows/Install-AntigravityIntegration.ps1`, `installer/windows/Test-MarkplaneAgentSkills.ps1`.
- Test: `installer/windows/tests/Install-MarkplaneAgentSkills.Tests.ps1`, `installer/windows/tests/Install-AntigravityIntegration.Tests.ps1`.
**Interfaces:**
- Produces: managed instructions for Codex, Claude Code, and Gemini/Antigravity that name the installed RWCA Superpowers path as authoritative.
- Produces: detection warning for foreign Superpowers paths without deleting them.
- [ ] **Step 1: Write failing agent authority tests**
Assert that generated managed blocks include `Research With Coding Agents`, the install-local `skills` path, and `SUPERPOWERS_DISABLE_TELEMETRY=1`; assert uninstall removes only managed blocks.
- [ ] **Step 2: Run tests to verify failure**
Run: `Invoke-Pester .\installer\windows\tests\Install-MarkplaneAgentSkills.Tests.ps1,.\installer\windows\tests\Install-AntigravityIntegration.Tests.ps1 -Output Detailed`
Expected: FAIL where current copy still says Markplane-only or omits explicit RWCA authority.
- [ ] **Step 3: Update managed block templates**
Make Codex, Claude Code, and Gemini/Antigravity blocks point to `{app}\skills` and state that bundled RWCA Superpowers overrides network/default copies for this product.
- [ ] **Step 4: Run agent authority tests**
Run: `Invoke-Pester .\installer\windows\tests\Install-MarkplaneAgentSkills.Tests.ps1,.\installer\windows\tests\Install-AntigravityIntegration.Tests.ps1 -Output Detailed`
Expected: PASS.
### Task 5: VSIX-Only Markplane Interface Registration
**Files:**
- Modify: `installer/windows/Install-VSCodeExtension.ps1`, `installer/windows/Package-VSCodeExtension.ps1`.
- Test: `installer/windows/tests/Install-VSCodeExtension.Tests.ps1`, `installer/windows/tests/Package-VSCodeExtension.Tests.ps1`.
**Interfaces:**
- Produces: `Install-VSCodeExtension.ps1 -VsixPath <file> -ShowSummary` installs through `code --install-extension <vsix> --force` and Antigravity `antigravity-ide.cmd --install-extension <vsix> --force`.
- Produces: no folder-copy fallback.
- [ ] **Step 1: Write failing VSIX workflow tests**
Assert CLI calls include `--install-extension`, the VSIX path, and `--force`; assert source-folder copy commands are absent.
- [ ] **Step 2: Run tests**
Run: `Invoke-Pester .\installer\windows\tests\Install-VSCodeExtension.Tests.ps1,.\installer\windows\tests\Package-VSCodeExtension.Tests.ps1 -Output Detailed`
Expected: PASS if current implementation already matches the rule, otherwise FAIL with exact missing behavior.
- [ ] **Step 3: Fix only failing VSIX behavior**
Keep packaging through `npx @vscode/vsce package` fallback and remove any direct extension-folder installation path if found.
- [ ] **Step 4: Run VSIX tests again**
Run: `Invoke-Pester .\installer\windows\tests\Install-VSCodeExtension.Tests.ps1,.\installer\windows\tests\Package-VSCodeExtension.Tests.ps1 -Output Detailed`
Expected: PASS.
### Task 6: Release Artifacts, Checksums, And SBOM
**Files:**
- Create: `scripts/New-RwcaChecksums.ps1`, `scripts/New-RwcaSbom.ps1`, `scripts/Build-RwcaRelease.ps1`.
- Test: `tests/RwcaProvenance.Tests.ps1`, `tests/RwcaDistributionReadiness.Tests.ps1`.
**Interfaces:**
- Produces: `Build-RwcaRelease.ps1 -RepoRoot <path>` creates `dist/ResearchWithCodingAgentsSetup-v0.1.0.exe`, `dist/ResearchWithCodingAgentsPortable-v0.1.0-win-x64.zip`, `dist/SHA256SUMS.txt`, `dist/SBOM.spdx.json`.
- [ ] **Step 1: Write failing release script tests**
Assert the release script requires the unified installer, packages `LICENSE`, `LICENSES`, `THIRD_PARTY_NOTICES.md`, `docs`, and records component paths in SPDX JSON.
- [ ] **Step 2: Run tests**
Run: `Invoke-Pester .\tests -Output Detailed`
Expected: FAIL until release scripts exist.
- [ ] **Step 3: Implement release scripts**
Copy validated build outputs into `dist`, create SHA-256 checksums with `Get-FileHash -Algorithm SHA256`, and create SPDX JSON with package entries for RWCA, Markplane, Superpowers, and research-repo-governance.
- [ ] **Step 4: Run release tests**
Run: `Invoke-Pester .\tests -Output Detailed`
Expected: PASS.
### Task 7: GitHub CI And Hygiene
**Files:**
- Create: `.github/workflows/windows-release.yml`, `.github/workflows/repo-hygiene.yml`, `.github/ISSUE_TEMPLATE/bug_report.yml`, `.github/ISSUE_TEMPLATE/feature_request.yml`, `.github/pull_request_template.md`.
**Interfaces:**
- Produces: CI that runs Pester tests, PowerShell parser checks, Cargo tests, npm build checks, provenance checks, and tracked-artifact hygiene.
- [ ] **Step 1: Write workflow files**
Use Windows runners for installer and Pester gates; validate component source paths and provenance in every job.
- [ ] **Step 2: Validate workflow YAML syntax locally**
Run: `Get-ChildItem .\.github\workflows\*.yml | ForEach-Object { $_.FullName }`
Expected: both workflow files are present.
- [ ] **Step 3: Run local hygiene tests**
Run: `Invoke-Pester .\tests -Output Detailed`
Expected: PASS.
### Task 8: Final Verification And Markplane Closure
**Files:**
- Modify: `.markplane/backlog/items/TASK-u2f8k.md`.
**Interfaces:**
- Produces: task notes with exact verification commands and status.
- [ ] **Step 1: Run installer/unit test suite**
Run: `Invoke-Pester .\installer\windows\tests,.\tests -Output Detailed`
Expected: PASS.
- [ ] **Step 2: Run Markplane consistency checks**
Run: `C:\Users\scheurer\.cargo\bin\markplane.exe sync`
Expected: exits `0`.
Run: `C:\Users\scheurer\.cargo\bin\markplane.exe check`
Expected: no broken references, no invalid statuses, no dependency cycles.
- [ ] **Step 3: Update acceptance criteria**
Check off only verified criteria in `TASK-u2f8k`; leave GitHub remote publication unchecked until a valid repository and remotes exist.
- [ ] **Step 4: Report remaining external blockers**
Report whether `.git` is still invalid, whether the GitHub fork URLs are available, and whether a signed release is still outside the first release scope.
