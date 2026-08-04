---
id: TASK-s52k4
title: Add compact-aware Markplane resume context
status: done
priority: high
type: feature
effort: medium
epic: EPIC-9rht7
plan: null
depends_on: []
blocks: []
related: [TASK-u6y58]
assignee: null
tags: []
position: aF
created: 2026-07-29
updated: 2026-07-29
---

# Add compact-aware Markplane resume context

## Description

`SessionStart` hooks fire for `source ∈ {startup, resume, clear, compact}`,
but the hook always injected the full `.context/summary.md` regardless of
source — unnecessary weight on `/compact`, exactly when we want fewer
tokens re-injected. Added a leaner `.context/resume.md` view (active work +
blocked count + pointers to the SDD ledger / Superpowers plans dir) and
wired the `SessionStart` hook to use it only when `source == "compact"`,
leaving `startup`/`resume`/`clear` on the full summary.

## Acceptance Criteria

- [x] `Project::generate_context_resume` exists in markplane-core, is part
      of `generate_all_context`, and has unit test coverage (empty +
      active/blocked cases).
- [x] `resume` is a valid `focus` value for both the `markplane context`
      CLI command and the `markplane_context` MCP tool.
- [x] `Invoke-MarkplaneClaudeHookEvent`'s `SessionStart` branch injects
      `.context/resume.md` when `source == "compact"` and the full summary
      otherwise; covered by Pester tests.
- [x] `subagent-driven-development` SKILL.md points agents at the resume
      pointer + SDD ledger after compaction instead of conversation memory.

## Notes

Verified end-to-end against this repo's own `.markplane/`: `source=compact`
produced a 386-char context vs. 804 chars for `source=startup`, both via
the freshly reinstalled `markplane.exe` (`cargo install --path
crates/markplane-cli --features embed-ui --force`). Reinstall required
stopping ~20 stale `markplane.exe mcp` processes that had the binary
locked (user-approved).

## References

- markplane-master/crates/markplane-core/src/context.rs
- markplane-master/crates/markplane-cli/src/commands/context.rs
- markplane-master/crates/markplane-cli/src/mcp/tools.rs
- MarkplaneInstaller/hooks/MarkplaneClaudeHooks.psm1
- MarkplaneInstaller/tests/MarkplaneClaudeHooks.Tests.ps1
- MarkplaneInstaller/skills/subagent-driven-development/SKILL.md
