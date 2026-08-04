---
id: TASK-k9mn6
title: Add Antigravity Gemini integration with Markplane visuals
status: done
priority: high
type: enhancement
effort: medium
epic: null
plan: null
depends_on: []
blocks: []
related: []
assignee: scheurer
tags: []
position: aJ
created: 2026-08-03
updated: 2026-08-03
---

# Add Antigravity Gemini integration with Markplane visuals

## Description

Extend the Windows Markplane toolkit so Google Antigravity/Gemini users receive the same project-local Markplane and Superpowers integration as Codex and Claude users. The integration must install skills, global Gemini instructions, Markplane MCP, lifecycle hooks, and explicit local visual guidance without telemetry or external visual assets.

## Acceptance Criteria

- [x] Antigravity receives a global Markplane plugin under `.gemini/config/plugins/markplane` with bundled skills and local rules.
- [x] Gemini global instructions in `.gemini/GEMINI.md` enforce the `using-superpowers` router and describe Markplane visuals.
- [x] Markplane MCP is configured in `.gemini/config/mcp_config.json` without removing unrelated MCP servers.
- [x] Antigravity hooks are configured in `.gemini/config/hooks.json` for `PreInvocation`, `PostToolUse`, and `Stop`.
- [x] Markplane visuals are routed through the local `markplane serve` web UI and Antigravity browser tools.
- [x] Codex/Claude installed skills receive the updated `using-superpowers` Antigravity tool mapping pointer.
- [x] Tests cover installer idempotence, uninstall isolation, Inno packaging, tool-name routing, and health checks.

## Notes

Implemented files include:

- `MarkplaneInstaller/Install-AntigravityIntegration.ps1`
- `MarkplaneInstaller/hooks/Invoke-MarkplaneAntigravityHook.ps1`
- `MarkplaneInstaller/tests/Install-AntigravityIntegration.Tests.ps1`
- updates to `MarkplaneInstaller/hooks/MarkplaneClaudeHooks.psm1`, installer `.iss` files, `Test-MarkplaneAgentSkills.ps1`, `README.md`, and `using-superpowers`.

Verification performed during implementation:

- Targeted Antigravity installer test: 5 passed, 0 failed.
- Hook routing test: 16 passed, 0 failed.
- Full Pester suite: 49 passed, 0 failed.
- PowerShell parser checks: all changed scripts parse.
- Local install health check: `health_exit=0`.
- Antigravity hook smoke test: `PreInvocation` emitted `injectSteps[0].ephemeralMessage` with the current Markplane project summary.

## References

- Antigravity MCP docs: https://antigravity.google/docs/mcp
- Antigravity hooks docs: https://antigravity.google/docs/hooks
- Antigravity plugins docs: https://antigravity.google/docs/plugins
- Antigravity/Gemini rules docs: https://antigravity.google/docs/ide-rules
