---
id: TASK-qyjnd
title: Cap reasoning and load execution plans once across agents
status: done
priority: high
type: enhancement
effort: medium
epic: null
plan: null
depends_on: []
blocks: []
related: []
assignee: scheurer
tags:
- superpowers
- codex
- claude
- gemini
- tokens
position: aT
created: 2026-08-04
updated: 2026-08-04
---

# Cap reasoning and load execution plans once across agents

## Description

Reduce Superpowers token use consistently across Codex, Claude Code, and
Antigravity Gemini. Remove automatic strongest-model selection, cap reasoning at
high, and prevent repeated loading of full implementation plans.

## Acceptance Criteria

- [x] Shared planning and review workflows cap automatic reasoning at high.
- [x] New implementation plans default to at most 250 lines.
- [x] Full plans are read once and compact briefs, task IDs, and ledgers drive resume.
- [x] Codex, Claude, and Gemini mappings state the same compact execution contract.
- [x] Focused and complete regression suites pass.
- [x] Both installers are rebuilt and local installations match the bundled source.

## Notes

Verification on 2026-08-04:

- Focused token-policy and subagent-contract tests: 17/17 passed.
- Complete MarkplaneInstaller Pester suite: 84/84 passed.
- Local agent health check passed.
- Nine policy files compared against each local target with zero mismatches.
- MarkplaneSetup-0.1.2.exe and MarkplaneAgentSetup-0.1.2.exe rebuilt with Inno Setup 6.7.3.

## References

- MarkplaneInstaller/skills/using-superpowers/SKILL.md
- MarkplaneInstaller/skills/writing-plans/SKILL.md
- MarkplaneInstaller/skills/subagent-driven-development/SKILL.md
- MarkplaneInstaller/tests/SuperpowersTokenBudget.Tests.ps1
