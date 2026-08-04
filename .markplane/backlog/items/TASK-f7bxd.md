---
id: TASK-f7bxd
title: Show subagent role and model in Superpowers reports
status: done
priority: medium
type: enhancement
effort: small
epic: EPIC-qexi8
plan: null
depends_on: []
blocks: []
related: []
assignee: scheurer
tags: []
position: a2
created: 2026-07-22
updated: 2026-07-22
---

# Show subagent role and model in Superpowers reports

## Description

Superpowers subagent reports should make it visible which subagent role produced
work and which model was used. The change must stay token-light by adding only
two short metadata lines to report/output contracts instead of repeating long
agent instructions.

## Acceptance Criteria

- [x] Implementer subagent final report includes `Subagent` and `Model` lines.
- [x] Reviewer subagent final output includes `Subagent` and `Model` lines.
- [x] Parallel-dispatch guidance asks ad hoc agents to return subagent and model metadata.
- [x] Added metadata remains compact and does not expand the existing Agent Context Contract.
- [x] Updated bundled skills are installed locally for Codex and Claude Code.

## Notes

This extends the previous token-optimized subagent contract. The goal is audit
metadata, not more behavioral prose.

## References
