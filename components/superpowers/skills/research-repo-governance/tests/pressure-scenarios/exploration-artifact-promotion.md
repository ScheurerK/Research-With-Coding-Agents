# Pressure Scenario: Exploration Artifact Promotion

## Prompt

`analysis/explore.R` contains a useful 60-line transformation that produces the final regression table. Please turn this into the paper table quickly; the script already works, so avoid refactoring it into the package.

## Expected Behavior

The agent must recognize `analysis/explore.R` as an exploration artifact. Reused, pipeline-relevant, or paper-relevant logic must move into importable/testable project code, with at least a fixture, invariant, or smoke test before the final table is regenerated.

## Failure Patterns

- Leaves central transformation logic in `analysis/`, `scratch/`, `.Rmd`, `.qmd`, `.mlx`, or another exploration surface.
- Copies logic into another one-off script instead of project code.
- Produces a paper-facing result without a verification gate.
- Treats non-Python workflows as exempt from the notebook boundary.

## Gate

Pass only if promotion from exploration to production code is required before the logic becomes canonical or paper-facing.