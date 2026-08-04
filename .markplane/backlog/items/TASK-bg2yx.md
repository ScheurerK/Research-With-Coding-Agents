---
id: TASK-bg2yx
title: Fix Antigravity MCP startup and IDE visuals
status: done
priority: high
type: bug
effort: medium
epic: null
plan: null
depends_on: []
blocks: []
related: []
assignee: null
tags: []
position: aK
created: 2026-08-03
updated: 2026-08-03
---

# Fix Antigravity MCP startup and IDE visuals

## Description

Antigravity users saw `markplane-mcp: starting server Error: Project not initialized: No .markplane/ directory found in current or parent directories : calling "initialize": EOF` when the installer had registered Markplane as a global Antigravity MCP server. Markplane MCP is project-scoped; starting it globally without a concrete project root can fail whenever Antigravity launches the stdio process from a directory outside a Markplane workspace.

The same report noted that no Markplane visual panel appeared in Antigravity IDE. The prior visual installer only copied the VS Code activity-bar extension to `%USERPROFILE%\.vscode\extensions`.

## Steps to Reproduce

1. Install the previous Antigravity integration, which writes `%USERPROFILE%\.gemini\config\mcp_config.json` with `markplane` args `mcp` only.
2. Open Antigravity in a directory that does not contain `.markplane` in the current or parent directories.
3. Let Antigravity initialize MCP servers.

## Expected Behavior

Global Antigravity startup must not start a project-scoped Markplane MCP server without a project root. Projects that need MCP tools should use workspace-local `.agents\mcp_config.json` with `markplane mcp --project <project-root>` and `cwd` set to the same root. Visuals should be available through the local Markplane web UI and best-effort IDE extension installation.

## Actual Behavior

The previous global MCP entry launched `markplane mcp` without `--project`, so initialization failed before a session could use Markplane. Antigravity IDE also did not receive the VS Code-family extension copy.

## Resolution

- Added `Install-AntigravityWorkspace.ps1` to write or remove workspace-local `.agents\mcp_config.json` while preserving unrelated MCP servers.
- Changed `Install-AntigravityIntegration.ps1` so global setup removes stale `mcpServers.markplane` entries instead of creating them, keeps hooks and plugin rules, and documents the workspace installer.
- Extended `Install-VSCodeExtension.ps1` to copy the activity-bar extension to VS Code and known Antigravity IDE extension roots, with explicit success exit code handling.
- Included the new workspace installer in both Inno packages and updated README plus health checks.
- Applied the fixed integration on this PC: global Antigravity MCP now keeps `matlab-mcp` only; this repo has workspace-local Markplane MCP with `--project` and `cwd`.

## Verification

- Pester suite: 51 passed, 0 failed.
- PowerShell parse check: changed scripts parse successfully.
- Inno builds: `MarkplaneSetup-0.1.2.exe` and `MarkplaneAgentSetup-0.1.2.exe` compile successfully.
- Local health check: `Test-MarkplaneAgentSkills.ps1` passes.
- Local config check: global Antigravity `mcp_config.json` has no `markplane`; `.agents\mcp_config.json` has project-local Markplane MCP.

## References

- Antigravity MCP docs: global config lives at `~/.gemini/config/mcp_config.json`; workspace config can live at `.agents/mcp_config.json`; stdio entries support `cwd`.
- Antigravity plugin docs: plugins can bundle skills, rules, MCP config, and hooks, and global plugins live under `~/.gemini/config/plugins/`.
