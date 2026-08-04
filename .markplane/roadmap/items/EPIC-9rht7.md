---
id: EPIC-9rht7
title: Claude Code / Codex Integration
status: done
priority: high
started: null
target: null
related: [NOTE-ryvgy]
tags: []
created: 2026-07-30
updated: 2026-07-30
---

# Claude Code / Codex Integration

## Objective

Make Markplane a first-class citizen of the Claude Code / Codex lifecycle:
hooks that keep `.markplane/` in sync automatically, an MCP server exposed
to the agent, quality gates enforced at Stop, and installers that cover
Windows and macOS for both agents.

## Key Results

- [x] KR1: SessionStart/PostToolUse/SubagentStart/Stop/SessionEnd hooks
      installed for both Claude Code and Codex, with a compact-aware
      resume context that shrinks injected tokens after `/compact`.
- [x] KR2: Stop-hook quality gates catch placeholder content and
      unlinked Superpowers plans before a session ends.
- [x] KR3: Installers exist for Windows (Inno Setup, both agent-neutral
      and Codex-branded packages) and macOS/Linux (bash port), covering
      MCP registration, hooks, skills, and the VS Code extension.

## Notes

Covers the full hook lifecycle (dkwjv, w6syq, j4g4j, s52k4), the
Claude-Code-fit audit and macOS port (u6y58, rypkc), and the Codex
skill packaging follow-up (svdsc). The VS Code extension specifically
has known upstream limitations (private bundled CLI, partial MCP
config, orphaned MCP processes on session end — see NOTE on the
VS Code extension investigation) that this epic's hooks/MCP setup
works around but cannot fully fix.
