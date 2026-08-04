---
id: EPIC-qexi8
title: Superpowers Governance and Agent Contract
status: done
priority: high
started: null
target: null
related: []
tags: []
created: 2026-07-30
updated: 2026-07-30
---

# Superpowers Governance and Agent Contract

## Objective

Keep the bundled Superpowers skill set predictable across agents and
model tiers: clear governance priority, low token overhead, opt-in
side effects (commits), and reporting that tells the user which
subagent/model actually did the work.

## Key Results

- [x] KR1: A documented, agent-agnostic model tier policy exists so
      Superpowers behaves consistently whether the calling agent is
      Claude Code, Codex, or another host.
- [x] KR2: Subagent-driven-development reports name the acting role and
      model; Superpowers-initiated commits are opt-in, not automatic.
- [x] KR3: Local skill token footprint is optimized and the visual
      brainstorming companion's telemetry is disabled by default.

## Notes

Covers governance priority clarification (bg556), subagent
transparency (f7bxd), the model tier policy (s9mbi), the Markplane
agent contract taught to subagents (ygypy), opt-in commits (zfety),
telemetry opt-out (udkvm), and the token footprint pass (eqppy).
