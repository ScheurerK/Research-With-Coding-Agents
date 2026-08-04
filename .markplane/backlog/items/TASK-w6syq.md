---
id: TASK-w6syq
title: Integrate Claude Code lifecycle hooks for Markplane
status: done
priority: high
type: enhancement
effort: large
epic: EPIC-9rht7
plan: null
depends_on: []
blocks: []
related: []
assignee: scheurer
tags: []
position: a8
created: 2026-07-21
updated: 2026-07-21
---

# Integrate Claude Code lifecycle hooks for Markplane

## Description

Add a Claude Code lifecycle integration that loads the Markplane context for the project above the current Claude working directory, keeps Markplane indexes synchronized after Markplane mutations, and validates Markplane consistency before the session stops.

The implementation must keep MCP registration and hooks separate: MCP is managed through the Claude CLI user scope when available, while hooks are stored in `~/.claude/settings.json` and call the installed `markplane.exe` by absolute path.

## Acceptance Criteria

- [x] Claude Code hook runtime supports `SessionStart`, `PostToolUse`, `SubagentStart`, `Stop`, and `SessionEnd` with project-local `.markplane` detection.
- [x] Hook installer preserves unrelated Claude settings and hooks, creates a one-time `.markplane.bak`, and removes only Markplane-owned handlers on uninstall.
- [x] Claude MCP helper uses `claude mcp add --scope user` when the Claude CLI is available and leaves settings unchanged when it is missing.
- [x] Both Inno Setup packages include the hook files and run MCP/hook setup during install plus hook cleanup during uninstall.
- [x] Hook code contains no HTTP, telemetry, prompt-hook, or agent-hook behavior.
- [x] Local installation writes five Markplane hooks into `~/.claude/settings.json` and installs the hook runtime under `%LOCALAPPDATA%\Programs\Markplane\hooks`.
- [x] Verification passed: Pester tests, PowerShell parser checks, two-project live context check, Inno builds, and `markplane check`.

## Notes

Implemented files:

- `MarkplaneInstaller/hooks/MarkplaneClaudeHooks.psm1`
- `MarkplaneInstaller/hooks/Invoke-MarkplaneClaudeHook.ps1`
- `MarkplaneInstaller/Install-ClaudeCodeHooks.ps1`
- `MarkplaneInstaller/Configure-ClaudeCode.ps1`
- `MarkplaneInstaller/MarkplaneInstaller.iss`
- `MarkplaneInstaller/MarkplaneAgentInstaller.iss`
- `MarkplaneInstaller/README.md`
- `MarkplaneInstaller/tests/MarkplaneClaudeHooks.Tests.ps1`
- `MarkplaneInstaller/tests/Install-ClaudeCodeHooks.Tests.ps1`

Local status:

- `claude` is not currently in PATH, so MCP migration was skipped by design and the legacy `mcpServers.markplane` setting remains in `~/.claude/settings.json` until the Claude CLI is available.
- The generated root `CLAUDE.md` snippet was removed because it matched the temporary Markplane snippet exactly.
- Git commands fail because this workspace is not recognized as a git repository.

## References