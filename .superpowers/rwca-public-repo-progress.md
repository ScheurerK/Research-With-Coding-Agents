# Research With Coding Agents Execution Progress

Plan: `docs/superpowers/plans/2026-08-04-research-with-coding-agents-public-repository.md`
Task: `TASK-u2f8k`

## Global Constraints

- Product name is `Research With Coding Agents`.
- Core install root is `%LOCALAPPDATA%\Programs\ResearchWithCodingAgents\`.
- Bundled Superpowers is authoritative for Codex, Claude Code, and Gemini/Antigravity.
- Markplane UI extension installs only via VSIX IDE CLI commands with `--force`.
- Preserve foreign Superpowers copies, user extensions, project `.markplane`, and unrelated config.
- Keep `SUPERPOWERS_DISABLE_TELEMETRY=1`.

## Checklist

- [x] Task 1: Public Repository Envelope
- [x] Task 2: License And Provenance Gate
- [x] Task 3: Unified Installer Identity
- [x] Task 4: Authoritative Superpowers For All Agents
- [x] Task 5: VSIX-Only Markplane Interface Registration
- [x] Task 6: Release Artifacts, Checksums, And SBOM
- [x] Task 7: GitHub CI And Hygiene
- [x] Task 8: Final Verification And Markplane Closure

Current task: external follow-up blockers.

## Verification Log

- Task 1 RED: `Invoke-Pester .\tests\RwcaDistributionReadiness.Tests.ps1` failed because public root files and `README.md` were missing.
- Task 1 GREEN: `Invoke-Pester .\tests\RwcaDistributionReadiness.Tests.ps1` passed: 3 passed, 0 failed.
- Task 2 RED: `Invoke-Pester .\tests\RwcaProvenance.Tests.ps1` failed because provenance scripts were missing.
- Task 2 GREEN: `Invoke-Pester .\tests\RwcaProvenance.Tests.ps1` passed: 3 passed, 0 failed.
- Task 3 RED: `Invoke-Pester .\tests\RwcaInstallerNaming.Tests.ps1, .\installer\windows\tests\Build-Installer.Tests.ps1` failed because installer identity still used Markplane names.
- Task 3 GREEN: same command passed: 5 passed, 0 failed.
- Task 4 RED: `Invoke-Pester .\installer\windows\tests\Install-MarkplaneAgentSkills.Tests.ps1, .\installer\windows\tests\Install-AntigravityIntegration.Tests.ps1` failed because RWCA Superpowers authority was not explicit.
- Task 4 GREEN: same command passed: 15 passed, 0 failed.
- Task 5 CHECK: `Invoke-Pester .\installer\windows\tests\Install-VSCodeExtension.Tests.ps1, .\installer\windows\tests\Package-VSCodeExtension.Tests.ps1` passed: 19 passed, 0 failed.
- Task 6 RED: `Invoke-Pester .\tests\RwcaReleaseArtifacts.Tests.ps1` failed because release scripts were missing.
- Task 6 GREEN: same command passed: 1 passed, 0 failed.
- Task 7 RED: `Invoke-Pester .\tests\RwcaGithubWorkflow.Tests.ps1` failed because `.github` workflows/templates were missing.
- Task 7 GREEN: same command passed: 2 passed, 0 failed.
- Task 8 VERIFY: `Invoke-Pester .\installer\windows\tests, .\tests` passed: 97 passed, 0 failed.
- Task 8 VERIFY: `markplane sync` and `markplane check` passed after BOM-free task rewrite.
- Task 8 BUILD: `.\installer\windows\Build-Installer.ps1` passed with escalated filesystem access and produced `installer\windows\Output\ResearchWithCodingAgentsSetup-v0.1.0.exe`.
- Task 8 RELEASE: `.\scripts\Build-RwcaRelease.ps1 -SkipInstallerBuild` passed and produced `dist` artifacts.
