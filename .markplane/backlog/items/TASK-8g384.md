---
id: TASK-8g384
title: Verify Antigravity skill parity and conflicts
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
position: aO
created: 2026-08-04
updated: 2026-08-04
---

# Verify Antigravity skill parity and conflicts

## Description

Detect drift between bundled and installed Antigravity skills while warning
about external duplicates without deleting user-managed installations.

## Acceptance Criteria

- [x] Recursive SHA-256 manifests match exactly.
- [x] Missing, extra, or changed plugin files fail the health check.
- [x] External duplicates produce warnings but remain untouched.

## Notes

Detailed contract: implementation plan Task 2.

## References

- docs/superpowers/plans/2026-08-04-antigravity-superpowers-vsix-parity.md
