---
id: TASK-x2fz8
title: Install Markplane extension through IDE CLIs
status: done
priority: high
type: feature
effort: medium
epic: EPIC-utc5v
plan: PLAN-48fdt
depends_on: []
blocks: []
related:
- NOTE-pvvy5
assignee: scheurer
tags:
- antigravity
- superpowers
position: aR
created: 2026-08-04
updated: 2026-08-04
---

# Install Markplane extension through IDE CLIs

## Description

Install, verify, and uninstall the bundled Markplane VSIX through the official
VS Code and Antigravity IDE command-line interfaces.

## Acceptance Criteria

- [x] Installation uses --install-extension with the VSIX and --force.
- [x] Registration is verified through --list-extensions --show-versions.
- [x] Missing CLIs warn cleanly and never fall back to source-folder copying.

## Notes

Detailed contract: implementation plan Task 5.

## References

- docs/superpowers/plans/2026-08-04-antigravity-superpowers-vsix-parity.md
