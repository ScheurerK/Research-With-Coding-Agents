---
id: TASK-zfety
title: Make Superpowers subagent commits opt-in
status: done
priority: high
type: enhancement
effort: small
epic: EPIC-qexi8
plan: null
depends_on: []
blocks: []
related: []
assignee: scheurer
tags: []
position: aE
created: 2026-07-23
updated: 2026-07-23
---

# Make Superpowers subagent commits opt-in

## Description

Superpowers subagent-driven development currently tells implementer subagents
to commit their own work. That is too aggressive for Markplane-managed research
checkpoints and for small local implementation tasks. Commit ownership should
stay with the controller by default, while per-task subagent commits remain an
explicit opt-in mode for isolated, valid git worktrees.

## Acceptance Criteria

- [x] Implementer subagents are instructed not to stage or commit unless the task brief explicitly sets `subagent_commit_mode: per-task`.
- [x] The SDD controller documentation says controller-owned commits are the default and explains when per-task subagent commits are allowed.
- [x] Report templates expose the commit action without implying every subagent creates commits.
- [x] Research checkpoint commits remain owned by `research-checkpoint-commits`.
- [x] Installer-bundled and locally installed Codex/Claude skills contain the updated policy.
- [x] Pester and Markplane checks pass.

## Notes

Triggered by user concern that "all subagents also commit" is overkill.

Implementation evidence:
- Added Pester coverage in `MarkplaneInstaller/tests/SuperpowersSubagentContract.Tests.ps1`.
- Updated `subagent-driven-development` docs and implementer prompt so subagent commits are opt-in.
- Reinstalled bundled skills to local Codex and Claude directories.
- Verification: full Pester suite reported 33 passed, 0 failed.

## References
