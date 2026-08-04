---
id: NOTE-ryvgy
title: Why Markplane integration works worse in the Claude Code VS Code extension
status: active
type: decision
related: [EPIC-9rht7]
tags:
- vscode
- claude-code
- mcp
created: 2026-07-30
updated: 2026-07-30
---

# Why Markplane integration works worse in the Claude Code VS Code extension

## Context

Investigated after repeatedly hitting stale `markplane.exe mcp` processes
(~20 at once) blocking `cargo install --force` reinstalls. Verified via the
official docs (`code.claude.com/docs/en/vs-code.md`) and by fetching the
cited GitHub issues directly rather than trusting a research subagent's
report at face value — the subagent had misattributed at least one citation.

## Findings (verified)

- The extension bundles its own **private copy of the CLI** and does not
  add `claude` to shell PATH. MCP server *registration* is only "Partial"
  in the extension: new servers must be added via `claude mcp add` in a
  terminal; the extension can only manage/reconnect existing ones.
- "Commands and skills" available in the extension are a documented
  **Subset** of the CLI's full set — relevant to our 16 bundled Superpowers
  skills.
- **Confirmed, matches our own experience**: GitHub issue #22612 — orphaned
  MCP child processes are not cleaned up when a VS Code session/window ends
  (closed as "not planned/stale", i.e. not being actively fixed upstream).
  This is almost certainly why we accumulated ~20 stale `markplane.exe mcp`
  processes.
- GitHub issue #59718 confirms the `Notification` hook specifically does
  not fire in the extension — but explicitly confirms `Stop` fires
  correctly in both CLI and extension. Our hooks use
  SessionStart/PostToolUse/SubagentStart/Stop/SessionEnd, none of which is
  `Notification`, so this bug does not appear to explain our own symptoms.
- Issue #5202, initially cited as VS-Code-specific PATH evidence, is
  actually a general Linux CLI bug unrelated to the extension — flagged as
  a misattribution, not used as evidence.

## Decision

Keep registering the MCP server and hooks via the standalone `claude` CLI
in a terminal (already how our installers work — absolute paths baked into
hook commands, not reliant on PATH lookup). Do not attempt to "fix" this
from our side beyond that; the process-leak and command/skill-subset
issues are upstream VS Code extension limitations, not something our
installer scripts can work around further right now.

## Practical consequence

After any `markplane.exe` binary update, reload/restart VS Code windows
with the Claude Code extension open, not just kill stale processes once —
the extension will otherwise keep holding a file handle on the old binary
and respawn orphans as sessions accumulate.

## References

- https://code.claude.com/docs/en/vs-code.md
- https://github.com/anthropics/claude-code/issues/22612
- https://github.com/anthropics/claude-code/issues/59718
