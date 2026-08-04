---
id: EPIC-gm2tk
title: Markplane Core Hardening
status: done
priority: medium
started: null
target: null
related: []
tags: []
created: 2026-07-30
updated: 2026-07-30
---

# Markplane Core Hardening

## Objective

Close correctness gaps in Markplane's own core (`markplane-core`) that
surface only under concurrent or multi-process use, so the CLI and the
Claude Code/Codex hooks that shell out to it don't corrupt state when
multiple processes touch the same project.

## Key Results

- [x] KR1: Project-wide file locking exists so concurrent `markplane`
      invocations (e.g. two hook events firing close together) don't
      race on writes to `.markplane/`.

## Notes

Currently a single completed hardening task (4a9my). Future
core-level correctness work (not agent-integration or governance)
should land under this epic rather than starting a new one.
