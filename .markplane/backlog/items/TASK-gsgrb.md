---
id: TASK-gsgrb
title: Add research governance pressure scenario fixtures
status: done
priority: medium
type: enhancement
effort: small
epic: null
plan: null
depends_on: []
blocks: []
related: []
assignee: scheurer
tags:
- superpowers
- research-governance
- testing
position: a6
created: 2026-08-13
updated: 2026-08-13
---

# Add research governance pressure scenario fixtures

## Description

Add lightweight, human-readable pressure scenarios for the research governance skill so future skill changes can be checked against concrete agent failure modes without introducing a full automated LLM evaluation suite.

## Acceptance Criteria

- [x] Research governance ships pressure scenario fixtures for common high-risk agent temptations.
- [x] Each scenario declares `Prompt`, `Expected Behavior`, `Failure Patterns`, and `Gate` sections.
- [x] The governance skill router points maintainers to the scenario fixtures for manual or half-manual behavior audits.
- [x] Pester tests verify the scenario fixture contract.

## Notes

Implemented five fixtures under `components/superpowers/skills/research-repo-governance/tests/pressure-scenarios/`:

- `quick-result-patch.md`
- `exploration-artifact-promotion.md`
- `bugfix-requires-red-test.md`
- `unknown-empirical-output-invariants.md`
- `non-python-exploration-surface.md`

Verification:

- RED observed: `Invoke-Pester .\tests\RwcaResearchGovernanceSkill.Tests.ps1` failed because the scenario directory did not exist.
- After adding fixtures and router link, the same test passed: 3 passed, 0 failed.
- A PowerShell backtick escaping defect in the router path was caught by diff review and fixed before final verification.
- Final `Invoke-Pester .\tests\RwcaResearchGovernanceSkill.Tests.ps1` with isolated `.tmp\pester` TEMP: 3 passed, 0 failed.
- Final `Invoke-Pester .\tests` with isolated `.tmp\pester` TEMP: 18 passed, 0 failed.
- `git diff --check`: exit 0; only line-ending normalization warnings.
- `markplane check`: valid.

## References

- `components/superpowers/skills/research-repo-governance/SKILL.md`
- `components/superpowers/skills/research-repo-governance/tests/pressure-scenarios/`
- `tests/RwcaResearchGovernanceSkill.Tests.ps1`
