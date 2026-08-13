---
id: TASK-rajhb
title: Refresh bundled skills across local agent targets
status: done
priority: medium
type: research
effort: small
epic: null
plan: null
depends_on: []
blocks: []
related:
- NOTE-7fbcj
assignee: scheurer
tags:
- agent-skills
- antigravity
position: a7
created: 2026-08-14
updated: 2026-08-14
---

# Refresh bundled skills across local agent targets

## Research Checkpoint

### Scientific Purpose

Keep the Research With Coding Agents skill bundle reproducible across local agent runtimes after governance-skill changes. The immediate trigger was an Antigravity/Gemini agent reporting that `using-superpowers` could not be found at the expected location.

### Inputs

- Repository skill source: `components/superpowers/skills`.
- Local Codex target: `%USERPROFILE%\.codex\skills`.
- Local Claude Code target: `%USERPROFILE%\.claude\skills`.
- Local Gemini/Antigravity target: `%USERPROFILE%\.gemini\config\plugins\markplane\skills`.
- Related diagnosis note: [[NOTE-7fbcj]].

### Expected Outputs

- Codex, Claude Code, and Gemini/Antigravity local skill targets refreshed from the repository source.
- Repo-local `AGENTS.md` instructs future agents to refresh all supported local targets after changes under `components/superpowers/skills`.
- Agent-skill health check passes.

### Decision Rule

Descriptive/reproducibility only: the checkpoint is complete when all supported local targets have been refreshed and `Test-MarkplaneAgentSkills.ps1` passes against the repository skill source.

### Acceptance Checks

- [x] Codex and Claude Code skill targets refreshed from `components/superpowers/skills`.
- [x] Gemini/Antigravity Markplane plugin skill target refreshed from `components/superpowers/skills`.
- [x] `installer/windows/Test-MarkplaneAgentSkills.ps1 -SkillSourceRoot ./components/superpowers/skills` passes.
- [x] `AGENTS.md` records the future all-target refresh rule.
- [x] Markplane validation passes.

### Non-Goals

- No migration of component fork history.
- No deletion of foreign Superpowers installations.
- No changes to user-owned unrelated Markplane items.

## Completion Evidence

### Result

Refreshed bundled skills into Codex, Claude Code, and Gemini/Antigravity local runtime locations. Added a root `AGENTS.md` rule requiring future bundled-skill changes to refresh every supported local target and run the installed health check before completion.

### Validation

- `installer/windows/Install-MarkplaneAgentSkills.ps1 -SkillSourceRoot ./components/superpowers/skills`: installed bundled skills into `%USERPROFILE%\.codex\skills` and `%USERPROFILE%\.claude\skills`; refreshed managed Codex/Claude instructions; disabled optional Superpowers telemetry for the current user.
- `installer/windows/Install-AntigravityIntegration.ps1 -SkillSourceRoot ./components/superpowers/skills`: installed the Markplane Antigravity plugin into `%USERPROFILE%\.gemini\config\plugins\markplane`; refreshed Gemini hooks and global instructions.
- `installer/windows/Test-MarkplaneAgentSkills.ps1 -SkillSourceRoot ./components/superpowers/skills`: passed.
- `markplane check`: no broken references, valid statuses, symmetric reciprocal links, no dependency cycles.
- `markplane sync`: regenerated indexes and `.context` summaries.

### Interpretation

The earlier missing-path report was not caused by a moved `using-superpowers` file. The local Gemini/Antigravity plugin copy was stale versus the repository skill source and has now been refreshed.

### Caveats

Existing unrelated local changes remain unstaged: `TASK-u2f8k`, `NOTE-4qx2v`, and `EPIC-2iq9n`.

## References

- [[NOTE-7fbcj]]
