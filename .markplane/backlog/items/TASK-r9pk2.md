---
id: TASK-r9pk2
title: Make using-superpowers router bootstrap enforceable
status: done
priority: high
type: enhancement
effort: small
epic: null
plan: null
depends_on: []
blocks: []
related: []
assignee: scheurer
tags: []
position: aH
created: 2026-08-03
updated: 2026-08-03
---

# Make using-superpowers router bootstrap enforceable

## Description

The bundled Superpowers router skill is valuable only when main-agent sessions
load it before other actions. The installer already places a managed global
Codex/Claude hint block, but the current wording is too soft. Make the router
bootstrap explicit, keep narrow subagents exempt for token efficiency, and add a
local health check that verifies the global hints and installed router skill.

## Acceptance Criteria

- [x] Managed Codex/Claude hint text requires main agents to load `using-superpowers` before file reads, tool calls, planning, clarification questions, or implementation.
- [x] Managed hint text explicitly exempts narrow subagents and points them to the compact task contract.
- [x] A local installer health check verifies Codex and Claude global hints plus installed `using-superpowers` skill files.
- [x] Installer output points users to the health check after installation.
- [x] Pester coverage fails without the new bootstrap and health-check pieces and passes after implementation.
- [x] Local Codex and Claude installations are updated.
- [x] Markplane sync/check pass.

## Notes

Triggered by concern that the Superpowers router may not be mandatory in other projects.

Implementation evidence:
- Added `MarkplaneInstaller/Test-MarkplaneAgentSkills.ps1` read-only health check.
- Hardened `research-checkpoint-agents-extension.txt` to require main agents to load `using-superpowers` before task actions.
- Added `-SkipTelemetry` for isolated installer tests and set installer `$LASTEXITCODE`.
- Included the health check in both Inno Setup package definitions.
- Updated local `C:\Users\scheurer\.codex\AGENTS.md` and `C:\Users\scheurer\.claude\CLAUDE.md`.
- Verification: full Pester suite reported 40 passed, 0 failed; local health check passed.

## References
