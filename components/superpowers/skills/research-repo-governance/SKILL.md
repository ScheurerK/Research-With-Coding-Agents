---
name: research-repo-governance
description: Use when creating, reviewing, restructuring, or auditing research repositories, data layout, notebooks, generated results, experiment provenance, large/confidential files, or scoped AGENTS/CLAUDE guidance
license: MIT
metadata:
  author: Adapted from Microsoft Corporation (wiki-agents-md, microsoft/skills)
  version: "1.0.0"
---

# Research Repository Governance

Use this skill to protect reproducibility, data safety, and repository structure in research projects.

## Router

For quick compatibility or priority questions, this file is enough.

Before generating or auditing `AGENTS.md`/`CLAUDE.md`, changing repository layout, reviewing data/results/notebooks/experiments, or proposing a migration, read `references/full-governance.md`. For concrete layouts, read `references/repository-layout.md`. For experiment manifests, read `references/experiment-provenance.md` and `templates/experiment-manifest.yaml`.

For skill changes or audits of agent behavior under pressure, use the lightweight pressure scenarios in `tests/pressure-scenarios/` as manual/half-manual fixtures; they are not an automated LLM eval suite.

Use `research-checkpoint-commits` after this skill when the governed work becomes a Markplane-owned scientific edit, staging decision, or Git commit.

## Core Rules

- Raw data is immutable: never edit, reformat, delete, or overwrite committed or ingested raw data in place.
- Experiments need full provenance: commit, config, seed, dataset version, environment, and run command.
- Notebooks are for exploration and narration; reusable or reproducible logic belongs in importable code.
- Generated results are regenerated from code/config, never manually patched.
- Generated reports and tables are self-contained: variable names, labels, units, samples, time periods, sources, and Table Notes must explain what a reader is seeing.
- Major restructures require a migration plan and owner sign-off before execution.
- Credentials, confidential data, participant-identifiable data, and large binaries do not belong in normal Git history.
- Never overwrite an existing `AGENTS.md` or `CLAUDE.md`; generate only when missing and report skips.
- Repo-specific `AGENTS.md`/`CLAUDE.md` files are additive and must not weaken global `using-superpowers`, Markplane, router, or privacy rules.

## Priority

Repository governance outranks workflow convenience. Superpowers may orchestrate, plan, test, debug, or review only inside these boundaries.
