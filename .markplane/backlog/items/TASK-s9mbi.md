---
id: TASK-s9mbi
title: Add agent-agnostic model tier policy for Superpowers
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
position: aD
created: 2026-07-22
updated: 2026-07-23
---

# Add agent-agnostic model tier policy for Superpowers

## Description

Superpowers should use frontier-quality models for planning, design, and high-risk
review while using cheaper or standard models for implementation subagents where
that is sufficient. The policy must work across Codex, Claude Code, and future
agents by using capability tiers instead of hard-coded model names.

The policy must remain auditable through the existing `Subagent` and `Model`
report metadata without adding long prompt text to every subagent dispatch.

## Acceptance Criteria

- [x] Subagent-driven-development defines stable model tiers rather than hard-coded model names.
- [x] Planning, architecture, task decomposition, and final branch review require a frontier planning/review tier.
- [x] Mechanical implementation defaults to a cheap/mechanical tier and normal implementation to a standard implementation tier.
- [x] Dispatch templates require both `model_tier` and concrete `model` fields.
- [x] Reports include `Model tier` alongside existing `Model` metadata.
- [x] Updated bundled skills are installed locally for Codex and Claude Code.

## Notes

Use role-based capability labels so the policy survives model churn. A local
agent maps tiers to whatever model names are current in that runtime.

## References
