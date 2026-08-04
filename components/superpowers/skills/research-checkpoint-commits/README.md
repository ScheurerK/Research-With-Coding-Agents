# Research Checkpoint Commits

A portable agent skill for scientific Git workflows with Markplane.

## What This Skill Enforces

- One scientifically meaningful checkpoint per commit.
- One Markplane TASK as the owner of every diff.
- Methodological decisions and anomalies captured as Markplane NOTES.
- Explicit validation before completion.
- Commit messages that document the research reason, not only the file changes.
- Joint versioning of code, verifiable results, and project status.

## Markplane Model

| Markplane object | Research project use |
| --- | --- |
| EPIC | Paper, chapter, research question, or replication |
| PLAN | Multi-step analysis or reproduction plan |
| TASK | Exactly one committable research step |
| NOTE | Decision, data provenance, anomaly, interpretation, or finding |

## Package Contents

- `SKILL.md` - complete workflow for the agent.
- `references/validation-matrix.md` - domain checks by work type.
- `references/markplane-integration.md` - mapping, status, and linking rules.
- `templates/research-task-body.md` - body template for a checkpoint TASK.
- `templates/research-plan-body.md` - template for a multi-step research plan.
- `templates/research-decision-note.md` - template for durable methodological decisions.
- `AGENTS.md.snippet.md` - short project instruction for automatic use.
- `.mcp.json.example` - project-level Markplane MCP configuration.
- `scripts/checkpoint-audit.sh` - read-only audit of the staged checkpoint.

## Usage

1. Ensure the project is a Git repository and contains a `.markplane/` structure.
2. Connect Markplane through MCP or make the `markplane` CLI available.
3. Install or load the skill in an agent that supports the open `SKILL.md` convention.
4. Add the contents of `AGENTS.md.snippet.md` to project instructions when useful.
5. Start with a request such as:

```text
Use research-checkpoint-commits. Break the baseline analysis into
Markplane TASKs, then implement the first checkpoint.
```

Or with an existing task:

```text
Use research-checkpoint-commits for TASK-k3m8p. Commit only after
the data and sample checks have passed.
```

## Recommended Markplane Configuration

The default task type `research` and the default note types `research`,
`analysis`, and `decision` already fit well. Useful additional tags include:

```text
exploratory
confirmatory
data
sample
variables
estimation
robustness
simulation
figure
paper
reproducibility
```

## Safety Principle

The skill does not automatically commit raw data or sensitive data. It prefers
code, provenance, checksums, schemas, small approved fixtures, and validation
summaries.
