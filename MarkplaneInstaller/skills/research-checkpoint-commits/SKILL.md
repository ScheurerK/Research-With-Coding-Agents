---
name: research-checkpoint-commits
description: Use when research, empirical analysis, data, simulation, robustness, figures, manuscripts, reproducibility work, or staging/committing scientific work needs Markplane-owned Git checkpoints
---

# Research Checkpoint Commits

Use this skill to keep scientific work reviewable: one coherent research checkpoint, owned by one Markplane TASK, with validation evidence before completion or commit.

## Router

For quick compatibility or planning questions, this file is enough.

Before editing, staging, or committing research work, read `references/full-workflow.md`. For stage-specific validation evidence, also read `references/validation-matrix.md`.

If the task concerns repository layout, raw data, notebooks, generated results, experiment provenance, large/confidential files, or `AGENTS.md`/`CLAUDE.md`, use `research-repo-governance` first. This skill then handles the checkpoint boundary and commit discipline inside those governance rules.

## Core Invariants

- One primary Markplane TASK owns each scientific Git commit.
- When a research program spans multiple checkpoint TASKs, group them under
  one Epic (`epic:` field) instead of leaving them flat in the backlog, and
  record non-obvious decisions (why this specification, why this robustness
  check) as a Markplane NOTE linked via `related:` — this is what makes the
  research program's own reasoning show up in `markplane graph`, not just
  its commits.
- Define the checkpoint contract before implementation: purpose, inputs, outputs, decision rule, acceptance checks, non-goals.
- Keep the diff commit-sized: one scientific intent, one validation story, one rollback boundary.
- Inspect `git status -sb`, unstaged diff, and staged diff before every commit.
- Stage explicit files or hunks only; do not use `git add -A` or `git add .` in mixed worktrees.
- Never commit secrets, restricted data, raw confidential data, large binaries, or machine-specific files.
- Do not mark the TASK done until checks pass and completion evidence is recorded.
- Run Markplane sync/check before reporting completion.

## Commit Shape

Use a scientific subject with the TASK ID, for example:

```text
analysis(TASK-xxxxx): estimate the baseline event-study specification
```

The body records why, evidence, interpretation, and `Markplane: TASK-xxxxx`.
