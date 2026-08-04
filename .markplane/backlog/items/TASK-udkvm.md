---
id: TASK-udkvm
title: Disable Superpowers visual companion telemetry
status: done
priority: high
type: chore
effort: small
epic: EPIC-qexi8
plan: null
depends_on: []
blocks: []
related: []
assignee: scheurer
tags: []
position: a7
created: 2026-07-21
updated: 2026-07-21
---

# Disable Superpowers visual companion telemetry

## Description

Disable optional Superpowers visual brainstorming companion telemetry for local Codex and Claude Code use. The bundled skill must not load external branding assets by default, and the current Windows user should have `SUPERPOWERS_DISABLE_TELEMETRY=1` set.

## Acceptance Criteria

- [x] The bundled visual companion server does not contain the external Prime Radiant branding URL or generated external image tag path.
- [x] Installed Codex and Claude Code copies use the patched visual companion server.
- [x] `SUPERPOWERS_DISABLE_TELEMETRY=1` is set for the current Windows user.
- [x] The skill installer sets the same privacy default on future installs.
- [x] Managed Codex/Claude hints document that the privacy default must remain enabled.
- [x] JavaScript and PowerShell syntax checks pass.
- [x] Markplane sync/check pass.

## Completion Evidence

### Result

Patched `brainstorming/scripts/server.cjs` in the installer bundle and local Codex/Claude installations so `SUPERPOWERS_TELEMETRY_DISABLED` is always true and the branding renderer returns local text only. Removed the external branding URL and external image markup path from the visual companion server.

Updated `Install-MarkplaneAgentSkills.ps1` so future installs write `SUPERPOWERS_DISABLE_TELEMETRY=1` to `HKCU:\Environment` and set the current process environment. Updated the managed Codex/Claude hint and README to document the no-external-branding privacy default.

### Validation

- `reg query HKCU\Environment /v SUPERPOWERS_DISABLE_TELEMETRY`: `REG_SZ 1`.
- `rg "primeradiant|SUPERPOWERS_BRAND_IMAGE_URL|<img class=|https://github.com/obra/superpowers"` against the three visual companion server copies returned no matches.
- `node --check` passed for the installer, Codex, and Claude Code `brainstorming/scripts/server.cjs` files.
- PowerShell parsed `MarkplaneInstaller/Install-MarkplaneAgentSkills.ps1` successfully.
- Re-ran `MarkplaneInstaller/Install-MarkplaneAgentSkills.ps1`; it completed and installed patched skills into Codex and Claude Code.

### Caveats

Existing already-running Codex, Claude Code, or visual companion processes may keep their old environment until restarted. The code patch removes the external branding path from the installed visual companion server files themselves.

## References

Related to [[TASK-eqppy]].