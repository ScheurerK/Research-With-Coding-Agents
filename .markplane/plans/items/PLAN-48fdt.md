---
id: PLAN-48fdt
title: Implement Antigravity Superpowers and VSIX parity
status: done
implements:
- TASK-cv9gy
- TASK-6r6jf
- TASK-8g384
- TASK-ynpuw
- TASK-ehgw8
- TASK-x2fz8
- TASK-rzu5x
related:
- NOTE-pvvy5
created: 2026-08-04
updated: 2026-08-04
---

# Implement Antigravity Superpowers and VSIX parity

## Overview

Make the customized Markplane Superpowers bundle authoritative in Antigravity,
complete its native tool mappings, migrate hooks to the current schema, and install
the Markplane interface as a bundled VSIX through official IDE CLIs.

The executable task-by-task plan is:

- `docs/superpowers/plans/2026-08-04-antigravity-superpowers-vsix-parity.md`

The approved design is:

- `docs/superpowers/specs/2026-08-04-antigravity-superpowers-parity-design.md`

## Ground Truth

- `MarkplaneInstaller/Install-AntigravityIntegration.ps1` - current plugin and hook installer.
- `MarkplaneInstaller/Test-MarkplaneAgentSkills.ps1` - current installation health check.
- `MarkplaneInstaller/skills/using-superpowers/references/antigravity-tools.md` - canonical Antigravity mappings.
- `MarkplaneInstaller/Install-VSCodeExtension.ps1` - bundled VSIX CLI installer, verifier, and uninstaller.
- `MarkplaneInstaller/vscode-extension/package.json` - extension ID and version `local.markplane-vscode@0.1.2`.
- `MarkplaneInstaller/MarkplaneInstaller.iss` and `MarkplaneInstaller/MarkplaneAgentInstaller.iss` - package payload and lifecycle calls.

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| Markplane plugin skills are authoritative | Prevents an upstream or previously installed copy from replacing local customizations. |
| External duplicate skills are warned about and preserved | Prioritizes Markplane without destructive cleanup. |
| Full recursive hash parity is required | Marker-only checks cannot detect partial drift. |
| Current direct Antigravity hook handlers are used | Matches the documented Antigravity 2.5 schema. |
| VSIX is produced at build time | End users need no Node.js, package manager, or network fetch. |
| IDE CLIs install and verify the extension | Updates internal extension caches and prevents ghost installations. |

## Phases

### Phase 1: Superpowers authority and mappings

- [x] Reconcile the complete plugin skills tree.
- [x] Install the explicit Antigravity mapping rule.
- [x] Complete subagent and task-artifact guidance.
- [x] Add recursive health checks and non-destructive duplicate warnings.

**Checkpoint**: Focused Antigravity installer tests pass and deliberate plugin drift fails health checks.

### Phase 2: Hook schema

- [x] Emit direct `PreInvocation` and `Stop` handlers.
- [x] Retain matched `PostToolUse` handlers.
- [x] Verify adapter output contracts with representative payloads.

**Checkpoint**: Installer and adapter contract tests pass.

### Phase 3: VSIX build and installation

- [x] Add deterministic build-time VSIX packaging.
- [x] Include the VSIX in both Inno payloads.
- [x] Replace folder copies with CLI install, registration check, and uninstall.
- [x] Warn on missing IDE CLIs and retain `markplane serve` fallback.

**Checkpoint**: Fake-CLI tests prove install, `--force`, list verification, uninstall, and no copy fallback.

### Phase 4: Documentation and verification

- [x] Update installer documentation.
- [x] Parse all changed PowerShell files.
- [x] Run focused and complete Pester suites.
- [x] Build the real VSIX and both Inno installers.
- [x] Apply the local Antigravity integration and verify `local.markplane-vscode@0.1.2`.

**Evidence (2026-08-04)**: The final complete `MarkplaneInstaller/tests` suite passed 80/80. The real default packager produced the bundled VSIX, and Inno Setup 6.7.3 freshly built both setup executables. The real Antigravity plugin install and recursive health check passed, and `antigravity-ide.cmd --list-extensions --show-versions` returned `local.markplane-vscode@0.1.2` with exit 0. Installer hashes are recorded in `.superpowers/sdd/task-6-report.md`.

**Checkpoint**: Automated, real-package, Inno build, profile health, and Antigravity registration evidence are recorded.

## Testing Strategy

- RED/GREEN Pester cycle for each phase using installed Pester 3.4.0.
- Recursive SHA-256 comparison for the complete installed skills tree.
- Fake VS Code and Antigravity CLI scripts for deterministic extension tests.
- Documented camelCase hook payload smoke tests.
- Full `MarkplaneInstaller/tests` regression run.
- Local health check and Antigravity `--list-extensions --show-versions` verification.

## Rollback Plan

- Re-run the prior package installer to restore its managed plugin and hook blocks.
- Use each IDE CLI with `--uninstall-extension local.markplane-vscode` to remove the VSIX.
- Preserve foreign skills, hooks, MCP servers, and IDE extensions throughout rollback.
- Keep `markplane serve` available as the portable visual interface.

## Pre-Approval Checklist

- [x] Ground Truth refs verified against current codebase.
- [x] Detailed task contracts live in the linked Superpowers plan.
- [x] No speculative tool names or extension identifiers.
- [x] Plan is under 200 lines.

## References

- https://www.antigravity.google/docs/plugins
- https://www.antigravity.google/docs/hooks
- https://code.visualstudio.com/docs/configure/command-line
- https://code.visualstudio.com/api/working-with-extensions/publishing-extension
