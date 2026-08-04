---
id: TASK-u2f8k
title: Publish Research With Coding Agents repository
status: in-progress
priority: high
type: feature
effort: large
epic: null
plan: null
depends_on: []
blocks: []
related: []
assignee: scheurer
tags:
- github
- distribution
- licensing
position: aU
created: 2026-08-04
updated: 2026-08-04
---

# Publish Research With Coding Agents repository

## Description

Restructure the current local package into the public **Research With Coding
Agents** GitHub product. Preserve Markplane and Superpowers as separately licensed,
officially linked forks pinned by the main repository, and provide a unified,
reproducible Windows distribution that supports users from direct installation
through unrestricted source and extension development.

## Acceptance Criteria

- [ ] The main GitHub repository is named Research With Coding Agents and pins the
  maintained Markplane and Superpowers forks as submodules.
- [ ] One tested Windows setup executable installs, repairs, updates, verifies, and
  uninstalls the required core plus optional agent and IDE integrations.
- [x] The bundled customized Superpowers revision is authoritative for Codex,
  Claude Code, and Gemini/Antigravity without deleting foreign installations.
- [x] Markplane UI deployment uses a build-produced VSIX and official IDE CLI
  installation, with no source-folder copy fallback.
- [ ] Public source, extension interfaces, build instructions, contribution paths,
  licenses, provenance, checksums, and an SBOM are complete and verified by CI.
- [ ] Windows behavior is fully tested and macOS/Linux support is explicitly marked
  experimental where parity is not implemented.
## Notes

The design is approved in conversation and awaiting review as a written spec. The
current workspace root contains an invalid/empty `.git` directory, so the design
cannot be committed until the public repository is initialized or restored.

## References

- `docs/superpowers/specs/2026-08-04-research-with-coding-agents-public-repository-design.md`
- `docs/superpowers/specs/2026-08-04-antigravity-superpowers-parity-design.md`
## Progress 2026-08-04

Implemented the local public repository foundation and unified Windows release path:

- Added root public docs, Apache-2.0 main license, third-party notices, license files, component/package/extension docs, GitHub workflows, and issue/PR templates.
- Renamed the primary Inno installer identity to Research With Coding Agents and changed the output to `ResearchWithCodingAgentsSetup-v0.1.0.exe` under `%LOCALAPPDATA%\Programs\ResearchWithCodingAgents\`.
- Made the bundled customized Superpowers authority explicit for Codex, Claude Code, and Gemini/Antigravity while preserving foreign Superpowers copies.
- Verified Markplane UI extension deployment remains VSIX-only through official IDE CLIs with `--install-extension <vsix> --force`.
- Added machine-readable provenance, distribution-readiness checks, release artifact builder, SHA-256 checksums, and SPDX SBOM generation.
- Built the real installer at `MarkplaneInstaller\Output\ResearchWithCodingAgentsSetup-v0.1.0.exe` and generated `dist\ResearchWithCodingAgentsSetup-v0.1.0.exe`, `dist\ResearchWithCodingAgentsPortable-v0.1.0-win-x64.zip`, `dist\SHA256SUMS.txt`, and `dist\SBOM.spdx.json`.

Verification:

- `Invoke-Pester .\MarkplaneInstaller\tests, .\tests` passed: 97 passed, 0 failed.
- `C:\Users\scheurer\.cargo\bin\markplane.exe sync` passed.
- `C:\Users\scheurer\.cargo\bin\markplane.exe check` passed.
- `.\MarkplaneInstaller\Build-Installer.ps1` passed after sandbox escalation to access Inno Setup.
- `.\scripts\Build-RwcaRelease.ps1 -SkipInstallerBuild` passed.

Remaining before closing this task:

- Repair or initialize the invalid root `.git`, then create/pin the real GitHub fork submodules.
- Run a true clean-profile install/repair/update/uninstall smoke test against the generated setup executable.
- Push to GitHub and let the workflows run on the real repository.

