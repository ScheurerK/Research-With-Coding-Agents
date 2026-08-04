# {TITLE}

## Research Objective

[Research question, paper deliverable, replication target, or reproducibility objective.]

## Design Ground Truth

- [Protocol, preregistration, manuscript section, source code, dataset documentation.]
- [Exact repository paths and related Markplane items.]

## Estimand or Target Quantity

[Define the target quantity, population, timing, units, and comparison.]

## Assumptions

- [Maintained assumption.]
- [Threat or limitation.]

## Checkpoint Sequence

Each checkpoint below should become one Markplane TASK and normally one Git commit.

### Phase 1: Inputs and provenance

- [ ] TASK: identify and validate source data.
- [ ] TASK: implement deterministic ingestion.

**Checkpoint condition:** sources, versions, schemas, and row counts are documented.

### Phase 2: Sample and variables

- [ ] TASK: construct the analysis sample.
- [ ] TASK: construct the primary variables.

**Checkpoint condition:** attrition, keys, units, ranges, and missingness are audited.

### Phase 3: Analysis

- [ ] TASK: estimate the baseline specification.
- [ ] TASK: produce the primary table or figure.

**Checkpoint condition:** specification, N, uncertainty treatment, and output provenance are documented.

### Phase 4: Robustness and interpretation

- [ ] TASK: run one named robustness variation.
- [ ] TASK: update interpretation and caveats.

**Checkpoint condition:** robustness is compared with baseline and manuscript claims trace to current outputs.

## Validation Strategy

[Project commands and stage-specific diagnostics.]

## Decision and Stop Rules

[Conditions for proceeding, revising the design, or stopping.]

## Non-Goals

[Explicit exclusions and deferred items.]

## Reproducibility Contract

[Clean-run entry point, environment, expected outputs, and data-access requirements.]

## References

[Related EPIC, TASK, and NOTE items.]
