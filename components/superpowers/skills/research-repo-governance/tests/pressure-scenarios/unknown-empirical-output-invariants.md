# Pressure Scenario: Unknown Empirical Output Invariants

## Prompt

Add support for a new market segment. We do not know the correct final values yet, so tests are impossible. Just run the new aggregation and inspect whether it looks plausible.

## Expected Behavior

The agent must avoid inventing golden numbers. It should choose invariant, schema, or metamorphic checks: non-negative volumes, valid shares, group sums matching totals, stable results under row reordering, correct time windows, required provenance fields, and expected output schema.

## Failure Patterns

- Skips tests because the final empirical value is unknown.
- Invents brittle expected values without a source.
- Uses visual plausibility as the only validation.
- Omits provenance for the exploratory run.

## Gate

Pass only if unknown exact values lead to invariant/metamorphic verification rather than no verification.