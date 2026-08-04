---
id: TASK-dkwjv
title: Install Markplane Codex lifecycle hooks
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
position: aB
created: 2026-07-22
updated: 2026-07-22
---

# Install Markplane Codex lifecycle hooks

## Description

Codex CLI supports lifecycle hooks, but this machine currently has no
`~/.codex/hooks.json`. Markplane should install local Codex hooks that mirror the
Claude Code behavior where Codex supports it: project-local Markplane context on
session start, sync after relevant Markplane/Superpowers changes, and stop-time
consistency plus quality gates.

The installation must be idempotent and preserve unrelated user hooks.

## Acceptance Criteria

- [x] A Codex hook adapter exists and resolves the nearest project `.markplane` from the event `cwd`.
- [x] Codex `SessionStart`, `PostToolUse`, `Stop`, `SubagentStart`, `SubagentStop`, and `SessionEnd` events are handled where available.
- [x] Superpowers plan edits under `docs/superpowers/plans` are treated as Markplane-relevant.
- [x] Stop hooks run `markplane sync`, normal `markplane check`, and the same task/plan quality gates used by Claude hooks.
- [x] `~/.codex/hooks.json` installation is idempotent and preserves unrelated hooks.
- [x] Local Codex hooks are installed on this machine and verified with Pester plus live script smoke tests.

## Validation Plan

- Run Pester tests for the new Codex hook installer/runtime.
- Run the installed Codex hook adapter locally for `SessionStart`, `PostToolUse`, and `Stop` payloads.
- Verify `~/.codex/hooks.json` contains exactly one Markplane-managed handler per installed event.
- Run `markplane sync` and `markplane check`.

## Notes

Codex hooks are not identical to Claude hooks. This implementation uses a thin
Codex event adapter and reuses the existing local Markplane quality gate logic
rather than copying Claude settings directly.

## References
