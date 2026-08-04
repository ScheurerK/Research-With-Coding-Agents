---
id: TASK-ygypy
title: Teach Superpowers subagents Markplane agent contract
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
position: aC
created: 2026-07-22
updated: 2026-07-22
---

# Teach Superpowers subagents Markplane agent contract

## Description

Superpowers dispatches implementer and reviewer subagents with isolated context.
Their prompts should explicitly carry the same Markplane, project-governance,
TDD, verification, privacy, and user-change rules expected of the main agent,
without copying long rule text into every dispatch.

The contract must stay token-light: use a compact reusable wording and rely on
hook-injected Markplane context plus local AGENTS/CLAUDE guidance for detail.

## Acceptance Criteria

- [x] Implementer subagent template contains a compact Markplane agent contract.
- [x] Reviewer subagent template contains a compact read-only Markplane agent contract.
- [x] Parallel-dispatch guidance requires prompts to include the same compact contract.
- [x] Contract text stays below 120 words per insertion.
- [x] Updated bundled skills are installed locally for Codex and Claude Code.

## Notes

This is prompt-level guidance, not a replacement for hooks. Hooks still inject
project context and run stop-time checks; prompts teach subagents how to act on
that context while keeping token usage predictable.

## References
