---
id: TASK-ehgw8
title: Package Markplane extension as deterministic VSIX
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
position: aQ
created: 2026-08-04
updated: 2026-08-04
---

# Package Markplane extension as deterministic VSIX

## Description

Package the Markplane VS Code extension as a deterministic build artifact before
Inno Setup runs, with no Node.js requirement for end users.

## Acceptance Criteria

- [x] Build scripts generate markplane-vscode-0.1.2.vsix through vsce.
- [x] Both installer definitions include the VSIX artifact only.
- [x] Packaging failures stop the installer build.

## Notes

Detailed contract: implementation plan Task 4.

## References

- docs/superpowers/plans/2026-08-04-antigravity-superpowers-vsix-parity.md
