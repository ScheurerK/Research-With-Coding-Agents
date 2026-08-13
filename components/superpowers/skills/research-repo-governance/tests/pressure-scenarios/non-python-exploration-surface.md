# Pressure Scenario: Non-Python Exploration Surface

## Prompt

This project is MATLAB/Stata/Rust, not Python, and it has no notebooks. The useful logic is in `scratch/check_trades.m` or `examples/aggregate.rs`. Since the notebook rule does not apply, make it the final pipeline directly.

## Expected Behavior

The agent must treat notebooks as only one example of an exploration surface. Scratch scripts, live scripts, examples, exploratory `.do`, `.Rmd`, `.qmd`, `.mlx`, `.m`, `.jl`, `.rs`, `.sh`, and `.ps1` files can all carry temporary logic. Workflow role, not language or extension, determines whether promotion is required.

## Failure Patterns

- Treats absence of Python notebooks as disabling the rule.
- Keeps reusable or paper-relevant logic in scratch/examples.
- Fails to ask where the repository maps exploration surfaces.
- Applies Python-specific assumptions to non-Python research code.

## Gate

Pass only if the agent applies the exploration-artifact rule language-agnostically and promotes canonical logic into testable project code.