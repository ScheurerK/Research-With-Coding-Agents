---
id: PLAN-bxt28
title: Publish Research With Coding Agents public repository
status: in-progress
implements:
- TASK-u2f8k
related: []
created: 2026-08-05
updated: 2026-08-05
---

# Publish Research With Coding Agents public repository Implementation Plan

## Overview

Convert the local Markplane/Superpowers working package into the public
**Research With Coding Agents** GitHub product: a public repository envelope
(docs, licenses, provenance), a unified Windows installer identity, an
authoritative bundled Superpowers copy for Codex/Claude Code/Antigravity, a
VSIX-only Markplane UI deployment, and a signed, checksum-verified,
CI-produced Windows release.

The executable task-by-task plan is:

- `docs/superpowers/plans/2026-08-04-research-with-coding-agents-public-repository.md`

The approved design is:

- `docs/superpowers/specs/2026-08-04-research-with-coding-agents-public-repository-design.md`

## Ground Truth

- `README.md:13` — public install instructions promising a GitHub Release with `ResearchWithCodingAgentsSetup-v0.1.0.exe`.
- `scripts/Build-RwcaRelease.ps1` — builds the unified installer, portable zip, SBOM, and checksums into `dist\`.
- `installer/windows/MarkplaneInstaller.iss` — unified Research With Coding Agents installer identity and output naming.
- `.github/workflows/windows-release.yml` — CI that runs the Pester suite and, as of this plan, publishes the tagged GitHub Release.
- `.github/workflows/repo-hygiene.yml` — public-repository envelope and distribution-readiness gate.
- `UPSTREAM.md`, `THIRD_PARTY_NOTICES.md` — component provenance and license declarations for the vendored Markplane/Superpowers snapshots.

## Approach

Deliver the public product incrementally against the eight tasks in the
linked Superpowers plan, verifying each with the local Pester suite before
moving on: (1) stand up the public repository envelope and docs, (2) add a
machine-readable license/provenance gate, (3) rename the installer identity
to Research With Coding Agents, (4) make the bundled Superpowers copy
authoritative for all supported agents, (5) make Markplane UI deployment
VSIX-only through official IDE CLIs, (6) produce signed release artifacts
(installer, portable zip, checksums, SBOM), (7) wire GitHub Actions CI and
repository hygiene, and (8) close out Markplane tracking once verification
is real (not mocked) on the hosted repository.

Component provenance uses vendored source snapshots under `components/`
(Markplane, Superpowers) rather than Git submodules, so a normal clone
contains the full source tree with no extra checkout step — see the
"Vendored Snapshot Decision" progress note on `TASK-u2f8k`.

## Non-Goals / Out of Scope

- macOS/Linux installer parity — tracked as experimental for the first
  public release per the Global Constraints in the linked Superpowers plan.
- Signed/notarized binaries — not required for the first public release.
- Git submodule conversion — explicitly rejected in favor of vendored
  snapshots; any future change updates installer, CI, and docs together.

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| Vendored source snapshots instead of submodules | Normal `git clone` gets the full source tree; no submodule checkout step for users or CI. |
| Installer ships pinned local payloads only, no network fetch at install time | Reproducible, offline-capable installs; matches the public repo's "no network source downloads" constraint. |
| CI publishes the GitHub Release via a tag-triggered `softprops/action-gh-release` step | Matches the public README's documented install path ("download from a release") instead of a hidden Actions artifact. |
| CI fetches the release `markplane.exe` from the upstream Markplane GitHub Release, checksum-verified | Keeps the prebuilt binary out of git (matches this repo's own "no committed build artifacts" governance rule) while still giving the Antigravity hook contract tests and the Inno Setup build a real binary in CI. |

## Phases

### Phase 1: Public repository envelope and provenance

- [x] Add root public docs, Apache-2.0 license, third-party notices, and component/package READMEs.
- [x] Add machine-readable provenance and distribution-readiness checks.
- [x] Rename the installer identity and unified setup output to Research With Coding Agents.

**Checkpoint**: `Invoke-Pester .\tests` and the distribution-readiness script pass.

### Phase 2: Authoritative Superpowers and VSIX-only UI

- [x] Make the bundled Superpowers copy authoritative for Codex, Claude Code, and Gemini/Antigravity without deleting foreign copies.
- [x] Deploy the Markplane UI as a build-produced VSIX through official IDE CLIs only.

**Checkpoint**: `Invoke-Pester .\installer\windows\tests` passes; real Antigravity/VSIX registration verified.

### Phase 3: Release artifacts and hosted CI

- [x] Produce `dist\` release artifacts: setup exe, portable zip, SHA-256 checksums, SPDX SBOM.
- [x] Add GitHub Actions workflows for the Windows release build and repository hygiene.
- [x] Publish `main` and tag `v0.1.0` to the real GitHub repository.
- [x] Make the tag-triggered workflow actually create a GitHub Release with the `dist\` assets attached, instead of only a transient Actions artifact.
- [x] Fix the hosted-CI-only test failures blocking that release step (missing `markplane.exe` fixture, a PowerShell 5.1 native-stderr/`$ErrorActionPreference` interaction, and an ambient-environment-dependent telemetry assertion).

**Checkpoint**: the hosted `Windows Release` workflow run for `v0.1.0` passes end-to-end and the GitHub Release page shows `ResearchWithCodingAgentsSetup-v0.1.0.exe` and the other `dist\` assets.

### Phase 4: Final verification and closure

- [ ] Run a true clean-profile install/repair/update/uninstall smoke test against the published setup executable.
- [ ] Mark the remaining `TASK-u2f8k` acceptance criteria (clean-profile smoke test, CI-verified provenance/build-instructions completeness) checked only once independently verified.

**Checkpoint**: all `TASK-u2f8k` acceptance criteria are checked and the task is marked done.

## Testing Strategy

- Local Pester 3.4.0 regression suite (`Invoke-Pester .\installer\windows\tests,.\tests`) run before every push, including under `$ErrorActionPreference = "Stop"` to mirror GitHub Actions' default `shell: powershell` behavior.
- Hosted GitHub Actions runs on `windows-latest` as the source of truth for what a clean checkout actually does (no locally-provisioned files assumed).
- Manual clean-profile install/repair/update/uninstall smoke test against the built setup executable before closing `TASK-u2f8k` (outstanding, Phase 4).

## Rollback Plan

- The GitHub Release step is additive and gated to `v*` tag pushes; reverting the workflow commit restores artifact-only CI behavior without affecting `main`.
- Moving a release tag to a fixed commit and force-pushing it only republishes; it does not delete a previously published Release, so a bad hosted run can be corrected by re-tagging once the fix lands.
- Installer/agent-integration rollback follows the existing plan in `PLAN-48fdt` (re-run prior installer, per-IDE CLI uninstall, preserve foreign skills/hooks/MCP/extensions).

## Pre-Approval Checklist

- [x] Ground Truth refs verified against current codebase.
- [x] Detailed task contracts live in the linked Superpowers plan.
- [x] No speculative tool names or extension identifiers.
- [x] Plan is under 200 lines.

## References

- `docs/superpowers/plans/2026-08-04-research-with-coding-agents-public-repository.md`
- `docs/superpowers/specs/2026-08-04-research-with-coding-agents-public-repository-design.md`
- https://github.com/zerowand01/markplane
- https://github.com/obra/superpowers
