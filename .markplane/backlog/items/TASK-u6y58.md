---
id: TASK-u6y58
title: 'Tighten Claude Code fit: skill parity, resume docs, dev setup'
status: done
priority: medium
type: feature
effort: small
epic: EPIC-9rht7
plan: null
depends_on: []
blocks: []
related: [TASK-s52k4, TASK-rypkc]
assignee: null
tags: []
position: a3
created: 2026-07-29
updated: 2026-07-29
---

# Tighten Claude Code fit: skill parity, resume docs, dev setup

## Description

A full-project read-through found several places where the project's fit
with Claude Code specifically (as opposed to being generic/editor-agnostic)
had drifted: the Superpowers router skill documented Codex/Antigravity/Pi
tool mappings but had none for Claude Code; the `resume` context focus added
in [[TASK-s52k4]] wasn't reflected in the upstream docs; and the upstream
repo's own `.claude/` dev configuration was minimal (deny rules only, no
custom commands, no permission allowlist for the documented build/test
workflow).

## Acceptance Criteria

- [x] `using-superpowers/references/claude-tools.md` exists, documents
      Claude Code's background subagent lifecycle (no explicit
      close/wait step, `SendMessage` to resume), plan-mode approval flow,
      and `ScheduleWakeup`/`Monitor` for looping skills — and is wired into
      `SKILL.md`'s platform-adaptation routing line.
- [x] `docs/ai-integration.md` and `docs/mcp-setup.md` document the `resume`
      focus (purpose, token budget, tool catalog entry).
- [x] `markplane-master/.claude/settings.json` allowlists the read-only/build
      commands already documented in root `CLAUDE.md` (cargo
      build/test/clippy/fmt/check/install, npm install/build, read-only
      `markplane` subcommands) without allowing mutating markplane commands
      or destructive cargo/git operations.
- [x] `.claude/commands/` has slash commands for build, test, lint, and
      reinstall — the reinstall command documents the Windows file-lock
      failure mode encountered firsthand in [[TASK-s52k4]].

## Notes

Scope was deliberately narrowed via AskUserQuestion from a larger candidate
list (which also included Inno Setup installer packaging hygiene — dead
`Install-CodexHooks.ps1` bundling in the agent-neutral installer, and
`Configure-ClaudeCode.ps1`'s silent no-op when the `claude` CLI is missing).
Those are real but are installer-distribution concerns, not Claude-Code-fit
specifically, and were left for a separate task.

## References

- MarkplaneInstaller/skills/using-superpowers/SKILL.md
- MarkplaneInstaller/skills/using-superpowers/references/claude-tools.md
- markplane-master/docs/ai-integration.md
- markplane-master/docs/mcp-setup.md
- markplane-master/.claude/settings.json
- markplane-master/.claude/commands/
