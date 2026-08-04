---
id: TASK-svdsc
title: Package research checkpoint commits skill for Codex and Claude Code
status: done
priority: high
type: enhancement
effort: medium
epic: EPIC-9rht7
plan: null
depends_on: []
blocks: []
related: []
assignee: scheurer
tags: []
position: a6
created: 2026-07-21
updated: 2026-07-21
---

# Package research checkpoint commits skill for Codex and Claude Code

## Description

Bundle and install portable agent skills for local Codex and Claude Code installations, centered on `research-checkpoint-commits` and Superpowers.

## Acceptance Criteria

- [x] `research-checkpoint-commits` is available locally to Codex and Claude Code.
- [x] Superpowers skills are fetched from the official `obra/superpowers` source and available locally to Codex and Claude Code.
- [x] Markplane installer payload includes bundled skills and a reusable installer script.
- [x] Managed hints explain how Superpowers and research checkpoint commits interact.
- [x] Installer definitions include install and uninstall hooks for bundled skills.

## Completion Evidence

### Result

- Added `MarkplaneInstaller/Install-MarkplaneAgentSkills.ps1`.
- Added `MarkplaneInstaller/research-checkpoint-agents-extension.txt`.
- Added bundled skills under `MarkplaneInstaller/skills/`:
  - Superpowers 6.1.1 skill set from `obra/superpowers`.
  - `research-checkpoint-commits`.
- Updated `MarkplaneInstaller/MarkplaneInstaller.iss` and `MarkplaneInstaller/MarkplaneAgentInstaller.iss` to package and install bundled skills.
- Updated `MarkplaneInstaller/README.md`.
- Installed all bundled skills into:
  - `C:\Users\scheurer\.codex\skills`
  - `C:\Users\scheurer\.claude\skills`
- Updated managed hint blocks in:
  - `C:\Users\scheurer\.codex\AGENTS.md`
  - `C:\Users\scheurer\.claude\CLAUDE.md`

### Validation

- Downloaded `https://github.com/obra/superpowers/archive/refs/heads/main.zip`.
- Superpowers archive SHA256: `76C221D9822DEE9C853713BFD2BD1A970D537CB623B6933E5DDB8FD26C4E9086`.
- Verified 15 bundled skill directories contain `SKILL.md`.
- Ran `Install-MarkplaneAgentSkills.ps1` with `-SkipCodex -SkipClaude -SkipAgentHints` successfully.
- Ran full local skill installation successfully.
- Verified local Codex and Claude Code skill directories contain the Superpowers and research checkpoint skills.
- Verified managed hint blocks exist in Codex `AGENTS.md` and Claude `CLAUDE.md`.
- Ran `markplane check`: passed.

### Caveats

- Inno Setup (`ISCC.exe`) was not available in this environment, so the installer `.exe` files were not rebuilt here. The `.iss` definitions and payload are updated for the next build.
- The outer workspace is not a usable Git checkout for `git status`, despite containing a `.git` directory.

## References

- Official source: `https://github.com/obra/superpowers`