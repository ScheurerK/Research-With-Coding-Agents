---
id: TASK-eqppy
title: Optimize local agent skill token footprint
status: done
priority: medium
type: chore
effort: small
epic: EPIC-qexi8
plan: null
depends_on: []
blocks: []
related: []
assignee: scheurer
tags: []
position: a1
created: 2026-07-21
updated: 2026-07-21
---

# Optimize local agent skill token footprint

## Description

Reduce the context footprint of the locally bundled Markplane/Superpowers agent skills while preserving the detailed governance and checkpoint rules behind explicit references.

## Acceptance Criteria

- [x] `using-superpowers` is a short router instead of a full always-loaded rule body.
- [x] `research-checkpoint-commits` keeps core invariants in `SKILL.md` and moves the full workflow to `references/full-workflow.md`.
- [x] `research-repo-governance` is included in the installer bundle and uses a short router `SKILL.md` with its full guidance in `references/full-governance.md`.
- [x] The managed Codex/Claude hint tells agents to load bundled skills selectively.
- [x] Optimized skills are installed into local Codex and Claude Code skill directories.
- [x] Basic structure, installer parse, token-count, Markplane sync, and Markplane check validations pass.

## Completion Evidence

### Result

Implemented token-efficient router versions for the high-frequency `using-superpowers`, `research-checkpoint-commits`, and `research-repo-governance` entrypoints. Added `research-repo-governance` to `MarkplaneInstaller/skills` and to the installer fallback list. Updated the managed Codex/Claude hint and README to describe selective loading.

### Token Measurements

Approximation uses `characters / 4` tokens.

- Managed hint: 349 -> 156 tokens.
- `using-superpowers/SKILL.md`: 766 -> 340 tokens.
- `research-checkpoint-commits/SKILL.md`: 3,549 -> 491 tokens.
- `research-repo-governance/SKILL.md`: 3,192 -> 498 tokens.
- Full installed Codex `AGENTS.md`: 814 -> 621 tokens.
- Full installed Claude `CLAUDE.md`: 1,331 -> 1,138 tokens.
- All bundled `SKILL.md` bodies: previous 15 skills about 34,897 tokens; current 16 skills about 31,911 tokens.

Full detail references remain available when needed:

- `research-checkpoint-commits/references/full-workflow.md`: about 3,549 tokens.
- `research-repo-governance/references/full-governance.md`: about 3,192 tokens.
- `using-superpowers/references/upstream-superpowers-rule.md`: about 766 tokens.

### Validation

- Installed bundled skills into `C:\Users\scheurer\.codex\skills` and `C:\Users\scheurer\.claude\skills`.
- Verified `MarkplaneInstaller/skills` has 16 skill directories, 0 missing `SKILL.md`, and 0 copied `.git` directories.
- Parsed `MarkplaneInstaller/Install-MarkplaneAgentSkills.ps1` as a PowerShell scriptblock successfully.
- Verified local Codex/Claude managed hints contain selective-loading language and research priority order.

### Caveats

The full research-governance and checkpoint references still consume their original tokens when a task explicitly requires those detailed workflows. This is intentional: routine context is smaller, detailed context remains available for high-stakes research operations.

## References

Related to [[TASK-bg556]].
