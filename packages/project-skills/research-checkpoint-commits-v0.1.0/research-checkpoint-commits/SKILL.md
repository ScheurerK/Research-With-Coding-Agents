---
name: research-checkpoint-commits
description: Create reviewable, scientifically meaningful Git commits for research projects while using Markplane as the source of truth for epics, plans, tasks, decisions, dependencies, and validation evidence. Use for data preparation, empirical analysis, simulation, robustness, figures, manuscripts, and reproducibility work in a Git repository that contains .markplane or uses the Markplane MCP server.
---

# Research Checkpoint Commits

## Objective

Turn research work into a sequence of small, scientifically interpretable, independently reviewable Git commits.

Use Markplane to define the intended checkpoint before changing files and to record the result before committing. The Git history is the audit trail; Markplane is the project-state and decision layer.

A good checkpoint answers all of these questions:

1. What scientific or reproducibility purpose did this change serve?
2. Why does this diff belong together?
3. What evidence shows that the checkpoint is complete?
4. What changed in interpretation, assumptions, or project state?
5. Which Markplane item owns the work?

## Entity Mapping

Use Markplane entities consistently:

- **EPIC**: a paper, chapter, research question, replication, or major work package.
- **PLAN**: a multi-checkpoint design or analysis plan.
- **TASK**: exactly one commit-sized research checkpoint.
- **NOTE**: a methodological decision, anomaly, data provenance record, interpretation, or finding that should outlive the task.

Prefer one TASK per commit. A TASK may be completed by more than one commit only when an intermediate commit is independently useful and each commit remains explicitly linked to the same TASK. Never let one commit silently complete multiple unrelated TASKs.

## Tool Preference

When the Markplane MCP server is available, prefer its typed tools:

- Read context with `markplane_summary`, `markplane_context`, `markplane_query`, and `markplane_show`.
- Create or update items with `markplane_add`, `markplane_plan`, `markplane_link`, and `markplane_update`.
- Finish with `markplane_sync` and `markplane_check`.

When MCP is unavailable, use the Markplane CLI:

```bash
markplane dashboard
markplane show TASK-xxxxx
markplane add "Checkpoint title" --type research --priority medium --effort small
markplane start TASK-xxxxx
markplane done TASK-xxxxx
markplane sync
markplane check
```

When the body of an item must be edited, edit its Markdown file directly. Preserve valid YAML frontmatter and set `updated` to the current date.

## Non-Negotiable Rules

1. Inspect `git status -sb`, the unstaged diff, and the staged diff before every commit.
2. Never use `git add -A` or `git add .` when the worktree contains mixed or uncertain changes.
3. Stage explicit paths or coherent hunks only.
4. Do not commit secrets, credentials, restricted data, raw confidential data, or machine-specific files.
5. Do not mark a TASK done until its acceptance checks pass.
6. Do not hide failed checks. Keep the TASK active and record the failure or blocker.
7. Do not squash scientifically meaningful checkpoints merely to produce a tidy history.
8. Do not amend or rewrite published history unless the user explicitly requests it.
9. Never use a vague commit subject such as `update analysis`, `misc fixes`, `changes`, or `WIP`.
10. Generated artifacts belong in the same commit as their source change only when they are deterministic, reviewable, repository-approved, and necessary evidence of that checkpoint.
11. Respect the repository's existing contribution, data-governance, and validation instructions. This skill supplements them; it does not override them.

## Workflow

### 1. Establish Repository and Research Context

Run:

```bash
git rev-parse --show-toplevel
git status -sb
git diff --stat
git diff
```

Then read, in order when present:

1. Repository instructions such as `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, and the project README.
2. `.markplane/.context/summary.md`.
3. `.markplane/.context/active-work.md`.
4. The relevant EPIC, PLAN, TASK, and related NOTE files.

With MCP, request the project summary, active work, and the full item graph for the selected TASK.

Do not start implementation until the owning TASK is identified or created.

### 2. Select or Create a Commit-Sized TASK

A checkpoint is commit-sized when it has:

- one scientific intent;
- one coherent diff;
- one validation story;
- one interpretation or reproducibility consequence;
- an independent rollback boundary.

Split the work into separate TASKs when any of these are true:

- data acquisition, cleaning, variable construction, estimation, robustness, visualization, and manuscript interpretation are mixed;
- the diff supports more than one substantive claim;
- different parts require different validation methods;
- one part can fail or be reverted without invalidating the other;
- exploratory work is mixed with a confirmatory specification;
- code refactoring is mixed with a change in scientific results;
- unrelated Markplane or documentation changes are present.

Create research TASKs with `type: research` where that task type exists. Use a small effort estimate by default; a large or XL research TASK is normally evidence that it should be split.

### 3. Define the Checkpoint Contract

Before changing implementation files, ensure the TASK body contains:

```markdown
## Research Checkpoint

### Scientific Purpose
[Question, estimand, hypothesis, reproducibility goal, or decision this checkpoint addresses.]

### Inputs
[Datasets, source files, prior outputs, assumptions, and upstream item IDs.]

### Expected Outputs
[Files, tables, figures, diagnostics, or documented decisions expected from this checkpoint.]

### Decision Rule
[What result or condition determines the next step. Use "descriptive only" when no inferential decision is intended.]

### Acceptance Checks
- [ ] The intended pipeline step runs from the documented inputs.
- [ ] Domain-specific integrity checks pass.
- [ ] The diff contains no unrelated work.
- [ ] Results and caveats are recorded below.

### Non-Goals
[Explicitly excluded work. Link deferred work to another Markplane item.]

## Completion Evidence

### Result
[What changed.]

### Validation
[Commands, diagnostics, counts, tests, or comparisons and their outcomes.]

### Interpretation
[What the result means and what it does not establish.]

### Caveats
[Known limitations, unresolved anomalies, or "None identified".]

## References
[Related EPIC, PLAN, TASK, and NOTE links.]
```

Use wiki links such as `[[PLAN-xxxxx]]` and typed Markplane relationships where appropriate.

### 4. Start the TASK

Move the selected TASK into the configured active status, normally `in-progress`.

Only one primary checkpoint TASK should be active for the current working diff. Supporting tasks may be active only when their file scopes are clearly independent.

### 5. Implement Only the Checkpoint Scope

Work only on files required by the checkpoint contract.

Continuously inspect:

```bash
git diff --stat
git diff -- path/to/relevant/files
```

When unrelated changes are discovered:

- leave them unstaged;
- move them to another TASK;
- use a separate branch or worktree when needed;
- do not silently absorb them into the checkpoint.

Record a Markplane NOTE when implementation reveals a durable methodological choice, surprising anomaly, data provenance issue, or interpretation change. Link it to the TASK and PLAN.

### 6. Validate According to Research Stage

Always run:

```bash
git diff --check
markplane check
```

Also run the most relevant project checks. Use the validation matrix in `references/validation-matrix.md`.

At minimum, collect evidence appropriate to the stage:

- **Data ingestion**: source identity, retrieval date or version, checksum where appropriate, row count, schema, and key coverage.
- **Cleaning or joins**: pre/post row counts, duplicate keys, unmatched observations, missingness, and exclusion reasons.
- **Sample construction**: attrition table and a check that inclusion rules match the written design.
- **Variable construction**: units, ranges, missingness, boundary cases, and hand-checked examples.
- **Estimation**: exact specification, sample size, fixed effects, standard-error treatment, convergence, and baseline comparison.
- **Robustness**: one clearly stated variation at a time and a comparison against the baseline.
- **Simulation**: fixed seed or recorded random-state policy, parameter grid, repeated-run determinism where expected, and diagnostic summaries.
- **Figures and tables**: provenance from code, labels and units, deterministic regeneration, and correspondence with cited results.
- **Manuscript**: claims trace to current results; table, figure, appendix, and cross-reference numbers resolve.
- **Reproducibility**: clean-environment execution, dependency lock state, documented entry point, and expected outputs.

A failed check blocks completion unless the failure is itself the intended and documented result of a diagnostic checkpoint.

### 7. Record Completion Evidence

Update the TASK body with concrete results and checks.

Good evidence is specific:

```markdown
### Validation
- `python -m pytest tests/test_sample.py`: 18 passed.
- `make sample-audit`: 42,817 input rows; 39,204 retained; 3,613 exclusions reconcile with the attrition table.
- Firm-year key is unique after the merge; 0 duplicate keys.
```

Bad evidence is vague:

```markdown
### Validation
- Looks good.
- Tests pass.
```

Create or update a NOTE when the checkpoint changes a maintained assumption, empirical design choice, interpretation, or data provenance record.

### 8. Close and Synchronize Markplane

After all acceptance checks pass:

1. mark the TASK done;
2. update the PLAN checklist or status if this closes a plan phase;
3. update linked NOTES;
4. run `markplane sync`;
5. run `markplane check` again.

Include the relevant Markplane item files and tracked generated context/index files in the same Git commit as the research change. Do not force-add ignored Markplane output.

### 9. Stage Explicitly

Stage only checkpoint files:

```bash
git add -- path/to/code path/to/tests path/to/output \
  .markplane/backlog/items/TASK-xxxxx.md \
  .markplane/notes/items/NOTE-xxxxx.md
```

If only selected hunks belong to the checkpoint, use interactive staging:

```bash
git add -p -- path/to/file
```

Then inspect:

```bash
git status -sb
git diff --cached --stat
git diff --cached
git diff --cached --check
```

Run `scripts/checkpoint-audit.sh TASK-xxxxx` when available.

Do not commit when:

- the staged diff is empty;
- the owning TASK file is absent from the staged diff;
- unrelated files or hunks are staged;
- required checks failed;
- the completion evidence is missing;
- Markplane validation fails.

### 10. Commit With Scientific Intent

Use:

```text
<type>(TASK-xxxxx): <scientific outcome>

Why:
- <why this change was necessary>

Evidence:
- <most important validation result>
- <second validation result, when useful>

Interpretation:
- <what changes, or "No substantive interpretation change">

Markplane: TASK-xxxxx
```

Allowed default types:

- `data`
- `analysis`
- `robustness`
- `simulation`
- `figure`
- `paper`
- `repro`
- `docs`
- `chore`

The subject should describe the outcome, not the editing activity.

Good subjects:

```text
data(TASK-k3m8p): restrict the sample to common stocks
analysis(TASK-v7q2d): estimate the baseline event-study specification
robustness(TASK-r4c9a): cluster errors by issuer and month
figure(TASK-f8w3n): regenerate treatment-effect confidence intervals
paper(TASK-p2x6e): align the discussion with the revised sample
```

Avoid subjects such as:

```text
analysis(TASK-v7q2d): update regressions
chore(TASK-r4c9a): changes
paper(TASK-p2x6e): fix text
```

Follow an established repository commit convention when one exists, but retain the TASK ID and the explanation of why.

### 11. Report the Checkpoint

After committing, report:

- commit hash and subject;
- Markplane TASK and related PLAN;
- files included;
- checks run and outcomes;
- interpretation change;
- any follow-up TASKs, NOTES, or blockers.

Do not claim completion before the commit succeeds.

## Handling Exploration

Exploration still requires traceability, but it should not pollute confirmatory checkpoints.

For exploratory work:

1. use a TASK tagged `exploratory`;
2. state that the decision rule is exploratory;
3. keep scratch outputs out of Git unless the repository explicitly tracks them;
4. record durable findings in a NOTE;
5. create a new confirmatory TASK before promoting an exploratory result into the maintained analysis.

## Handling Negative or Null Results

A scientifically useful negative result can complete a checkpoint.

Commit it when:

- the procedure was valid;
- the result is documented;
- checks passed;
- the interpretation is appropriately limited;
- the next action is captured in Markplane.

Do not manipulate the checkpoint boundary to hide a null result or combine it with unrelated specification changes.

## Handling Large or Sensitive Data

Do not add large, licensed, confidential, personally identifying, or restricted datasets to Git merely to make the checkpoint self-contained.

Instead, commit:

- acquisition or transformation code;
- checksums or stable source identifiers when permitted;
- schema and provenance notes;
- synthetic fixtures or minimal permitted examples;
- deterministic manifests;
- validation summaries.

Follow repository policy for Git LFS, DVC, object storage, or secure data environments.

## Final Checklist

Before declaring success, verify:

- [ ] The commit has one scientific intent.
- [ ] One Markplane TASK owns the diff.
- [ ] The TASK contract and completion evidence are complete.
- [ ] Durable decisions or anomalies are recorded as NOTES.
- [ ] The staged diff contains no unrelated work.
- [ ] Required project and research checks passed.
- [ ] `markplane check` passed.
- [ ] Markplane indexes/context were synchronized as configured.
- [ ] The commit message explains why and includes the TASK ID.
- [ ] The commit succeeded and its hash was reported.
