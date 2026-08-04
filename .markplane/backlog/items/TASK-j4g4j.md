---
id: TASK-j4g4j
title: Add Markplane quality gates to Claude hooks
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
position: aA
created: 2026-07-22
updated: 2026-07-22
---

# Add Markplane quality gates to Claude hooks

## Description

Claude Code hooks should keep Markplane useful during the work, not only at the
end. When Markplane files or Superpowers implementation plans change, the hooks
must sync project context and run both the built-in Markplane consistency checks
and local quality gates for task/plan documentation.

The bridge rule is: detailed Superpowers plans may live in
`docs/superpowers/plans`, but each one must be linked or summarized from a
Markplane PLAN so Markplane remains the project source of truth.

## Acceptance Criteria

- [x] Edits under `docs/superpowers/plans` are treated as Markplane-relevant hook activity.
- [x] Stop hooks run `markplane sync`, normal `markplane check`, and task/plan quality gates.
- [x] Planned or in-progress Markplane TASK files fail quality checks when placeholders or empty acceptance criteria remain.
- [x] Superpowers plan Markdown files fail quality checks when no Markplane PLAN links or summarizes them.
- [x] Hook output still allows one correction attempt before producing a final visible warning.
- [x] Pester hook tests pass and a live hook smoke test works against this repository.

## Validation Plan

- Run `Invoke-Pester -Script .\MarkplaneInstaller\tests\MarkplaneClaudeHooks.Tests.ps1 -PassThru`.
- Run a live `SessionStart` hook invocation against this repository with the installed AppData hook runtime.
- Run `markplane sync` and `markplane check` after updating this task.

## Notes

The hook-level quality check is intentionally local PowerShell for now. A later
Markplane CLI feature can promote it into `markplane check` proper, but this
change immediately protects Claude sessions without changing the Rust CLI API.

## Completion Evidence

- `Invoke-Pester -Script .\MarkplaneInstaller\tests\MarkplaneClaudeHooks.Tests.ps1 -PassThru`: 11 passed, 0 failed.
- `Test-MarkplaneProjectQuality` against this repository: passed.
- Installed AppData `SessionStart`, `PostToolUse`, and `Stop` hook smoke tests: exit 0; successful Stop hook emitted no model context.
- `markplane sync` regenerated indexes/context.
- `markplane check`: no broken references, valid task statuses, symmetric reciprocal links, no dependency cycles.

## References
