---
id: TASK-ic56c
title: 'Enrich the Markplane graph: Epics, a decision Note, and a graph-connectivity quality gate'
status: done
priority: high
type: feature
effort: medium
epic: EPIC-9rht7
plan: null
depends_on: []
blocks: []
related: []
assignee: null
tags: []
position: aG
created: 2026-07-30
updated: 2026-07-30
---

# Enrich the Markplane graph: Epics, a decision Note, and a graph-connectivity quality gate

## Description

A graph review of this project found 15 backlog tasks and zero Epics,
Plans, or Notes — the graph rendered as isolated dots plus one small
island, because the project had been documenting almost exclusively at
Task level. This task both fixes the data (this project's own graph) and
closes the gap so it doesn't silently regress: a Stop-hook quality-gate
rule that blocks on Epics/Plans that exist but aren't wired into the
graph, plus a non-blocking nudge for tasks that could be linked to an
existing Epic but aren't.

## Acceptance Criteria

- [x] 3 Epics created (Claude Code/Codex Integration, Superpowers
      Governance and Agent Contract, Markplane Core Hardening) and all 15
      existing tasks assigned via `epic:`.
- [x] The VS Code extension investigation is recorded as NOTE-ryvgy
      (type: decision), linked to EPIC-9rht7 via `related:`, instead of
      living only in conversation history.
- [x] `Test-MarkplaneItemQuality` (plan branch) flags a non-draft PLAN
      whose `implements:` is empty as an orphaned/island plan.
- [x] A new `Test-MarkplaneGraphConnectivity` function flags an Epic with
      no task referencing it via `epic:` (hard, blocks Stop) and warns
      non-blockingly about tasks with no `epic:` link when at least one
      Epic exists in the project.
- [x] Both rules ported to the bash equivalent
      (`mp_test_item_quality`, new `mp_test_graph_connectivity`) with
      matching behavior.
- [x] Pester (`MarkplaneClaudeHooks.Tests.ps1`) and bash
      (`macos/tests/run-tests.sh`) test suites cover both new rules;
      full suites re-run clean (15/15 Pester, 45/45 bash) after the
      change, confirming no regression in the pre-existing 37 bash / 13
      Pester assertions.
- [x] `subagent-driven-development` and `research-checkpoint-commits`
      skills each gained one guidance addition: group multi-task work
      under an Epic, give it a PLAN with `implements:`, and record
      non-obvious decisions as a NOTE — so agents build the graph
      proactively, not only when the Stop gate blocks them.
- [x] The `SubagentStart` injected context (both PowerShell and bash
      hook implementations) gained one line stating this graph contract.

## Notes

Deliberately scoped as two enforcement layers, cheapest first: a
deterministic Stop-hook check (0 model tokens, catches the failure mode
for certain) plus a one-line proactive nudge in injected context and two
skills (guidance only, can't be guaranteed, but costs little). No
Rust/CLI changes — the graph itself (`build_graph` in serve.rs,
`build_reference_graph` in references.rs) already supports Epic/Plan/Note
relations; the gap was purely that this project wasn't populating them.

Retroactive Plans were deliberately not created for the pre-existing 15
tasks (all already `done`) — writing an implementation plan after the
fact for finished work would be fabricated documentation, not a real
plan. Plans should start being used for the *next* multi-task body of
work.

## References

- MarkplaneInstaller/hooks/MarkplaneClaudeHooks.psm1
- MarkplaneInstaller/macos/lib/markplane-claude-hooks.sh
- MarkplaneInstaller/tests/MarkplaneClaudeHooks.Tests.ps1
- MarkplaneInstaller/macos/tests/run-tests.sh
- MarkplaneInstaller/skills/subagent-driven-development/SKILL.md
- MarkplaneInstaller/skills/research-checkpoint-commits/SKILL.md
- .markplane/roadmap/items/EPIC-9rht7.md
- .markplane/notes/items/NOTE-ryvgy.md
