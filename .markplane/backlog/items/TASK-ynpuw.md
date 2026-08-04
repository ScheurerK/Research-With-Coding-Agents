---
id: TASK-ynpuw
title: Migrate Antigravity hooks to current schema
status: done
priority: high
type: feature
effort: medium
epic: EPIC-utc5v
plan: PLAN-48fdt
depends_on: []
blocks: []
related: []
assignee: scheurer
tags:
- antigravity
- superpowers
position: aP
created: 2026-08-04
updated: 2026-08-04
---

# Migrate Antigravity hooks to current schema

## Description

Emit the current Antigravity hook schema and verify adapter behavior for
pre-invocation, post-tool, and stop events.

## Acceptance Criteria

- [x] PreInvocation and Stop contain direct handlers.
- [x] PostToolUse retains matcher entries with nested handlers.
- [x] Representative payload smoke tests confirm valid output contracts.

## Notes

Detailed contract: implementation plan Task 3.

## References

- docs/superpowers/plans/2026-08-04-antigravity-superpowers-vsix-parity.md
