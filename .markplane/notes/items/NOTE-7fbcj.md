---
id: NOTE-7fbcj
title: using-superpowers path diagnosis
status: draft
type: research
related:
- TASK-rajhb
tags:
- agent-skills
- diagnosis
created: 2026-08-14
updated: 2026-08-14
---

# using-superpowers path diagnosis

## Summary

A second agent reported that `using-superpowers` was not found at the promised location. Local diagnosis shows the router was not moved and is present in the expected runtime locations for Codex, Claude Code, and Gemini/Antigravity.

## Findings

- Codex runtime file exists: `%USERPROFILE%\.codex\skills\using-superpowers\SKILL.md`.
- Claude Code runtime file exists: `%USERPROFILE%\.claude\skills\using-superpowers\SKILL.md`.
- Gemini/Antigravity Markplane plugin file exists: `%USERPROFILE%\.gemini\config\plugins\markplane\skills\using-superpowers\SKILL.md`.
- Repository source file exists: `components/superpowers/skills/using-superpowers/SKILL.md`.
- All four `using-superpowers` files have the same SHA256 hash: `A38561C3DE2795B6642FA4314C4A400C21397EF689C38396DE67B0C82B9BBD35`.
- `%USERPROFILE%\.research-with-coding-agents\skills\using-superpowers\SKILL.md` is not present and is not the installed runtime target verified here.
- `Test-MarkplaneAgentSkills.ps1 -SkillSourceRoot .\components\superpowers\skills` reports that the Gemini/Antigravity plugin skill tree is stale versus the current repository source, including missing new research-governance pressure scenario files. It does not report a missing `using-superpowers` router.

## Recommendations

If another agent reports the skill missing, check which integration and exact path it used. For Codex, use `%USERPROFILE%\.codex\skills\using-superpowers\SKILL.md`; for Claude Code, use `%USERPROFILE%\.claude\skills\using-superpowers\SKILL.md`; for Gemini/Antigravity, use `%USERPROFILE%\.gemini\config\plugins\markplane\skills\using-superpowers\SKILL.md`. Re-run the agent-skill installer or Antigravity integration installer to refresh stale installed copies after repository skill changes.

## References

- `components/superpowers/skills/using-superpowers/SKILL.md`
- `installer/windows/README.md`
- `installer/windows/Test-MarkplaneAgentSkills.ps1`
## Follow-up

On 2026-08-14 the bundled skill source was refreshed into all supported local targets:

- Codex and Claude Code via `installer/windows/Install-MarkplaneAgentSkills.ps1 -SkillSourceRoot ./components/superpowers/skills`.
- Gemini/Antigravity via `installer/windows/Install-AntigravityIntegration.ps1 -SkillSourceRoot ./components/superpowers/skills`.
- Verification passed with `installer/windows/Test-MarkplaneAgentSkills.ps1 -SkillSourceRoot ./components/superpowers/skills`.

The repository `AGENTS.md` now instructs future agents to refresh all supported local targets after changes under `components/superpowers/skills`.
