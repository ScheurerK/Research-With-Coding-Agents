---
id: TASK-bg556
title: Clarify Superpowers governance priority and token impact
status: done
priority: medium
type: chore
effort: medium
epic: EPIC-qexi8
plan: null
depends_on: []
blocks: []
related: []
assignee: scheurer
tags: []
position: a0
created: 2026-07-21
updated: 2026-07-21
---

# Clarify Superpowers governance priority and token impact

## Description

Clarify how Superpowers, research repository governance, and research checkpoint commits should interact in local Codex and Claude Code installations, and quantify expected context/token impact.

## Acceptance Criteria

- [x] Managed agent hint prioritizes `research-repo-governance` for research repository structure and data/provenance rules.
- [x] Managed agent hint keeps Superpowers responsible for orchestration and process workflows inside governance boundaries.
- [x] Managed agent hint keeps `research-checkpoint-commits` responsible for scientific staging and commit discipline.
- [x] Updated hint installed into local Codex `AGENTS.md` and Claude Code `CLAUDE.md`.
- [x] Token/context impact measured for metadata, managed hint, bootstrap files, and full skill bodies.

## Completion Evidence

### Result

- Updated `MarkplaneInstaller/research-checkpoint-agents-extension.txt`.
- Reinstalled bundled skill integration for local Codex and Claude Code.
- Updated `MarkplaneInstaller/README.md` to document governance priority.

### Validation

- Verified updated managed blocks in `C:\Users\scheurer\.codex\AGENTS.md` and `C:\Users\scheurer\.claude\CLAUDE.md`.
- Measured bundled skill sizes and approximate token cost using character count / 4.
- Ran `markplane sync` and `markplane check`.

### Token Notes

- Managed hint: 1,393 chars, approx. 349 tokens.
- Bundled skill metadata: 2,687 chars, approx. 672 tokens.
- All bundled skill bodies together: 139,587 chars, approx. 34,897 tokens if fully loaded.
- `using-superpowers` plus Codex reference: approx. 1,148 tokens.
- `research-repo-governance`: approx. 3,192 tokens.
- `research-checkpoint-commits`: approx. 3,549 tokens.

## References

- `research-repo-governance`
- `using-superpowers`
- `research-checkpoint-commits`