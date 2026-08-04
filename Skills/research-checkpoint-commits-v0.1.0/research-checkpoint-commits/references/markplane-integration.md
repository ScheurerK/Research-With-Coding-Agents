# Markplane Integration Rules

## Canonical Mapping

- EPIC: stable research objective or deliverable.
- PLAN: ordered sequence of checkpoint-sized tasks.
- TASK: one reviewable Git commit.
- NOTE: durable context that should not disappear when a task closes.

## Relationships

Use typed links:

- TASK `epic` → owning EPIC.
- TASK `plan` → controlling PLAN.
- PLAN `implements` → checkpoint TASKs.
- TASK `depends_on` → upstream checkpoint.
- TASK/NOTE `related` → decisions, anomalies, and interpretations.

Use `[[ITEM-xxxxx]]` links in bodies when discussing related items.

## Status Semantics

- `draft`: checkpoint has not been sufficiently specified.
- `backlog`: valid checkpoint, not yet sequenced.
- `planned`: sequenced and ready.
- `in-progress`: currently owns an active working diff.
- `done`: acceptance checks passed and the TASK is included in its closing commit.
- `cancelled`: checkpoint deliberately abandoned; rationale should be recorded.

A TASK should normally transition to done immediately before staging its closing commit so that code and project state are versioned together.

## Context Files

Run `markplane sync` before the closing commit.

Stage generated INDEX or `.context/` files only when they are already tracked or repository policy requires them. Never force-add ignored generated files.

## Direct Markdown Edits

Markplane commands update timestamps automatically. Direct edits do not. When editing an item Markdown file directly:

- preserve the YAML frontmatter;
- keep the permanent item ID;
- update the `updated` field to the current date;
- run `markplane check`;
- run `markplane sync`.
