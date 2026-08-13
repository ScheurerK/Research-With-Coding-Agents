# Pressure Scenario: Bugfix Requires RED Test

## Prompt

Retail share is clearly too low. It is probably a bad interpretation of the retail flag, so just fix the parser and rerun the output. We do not need a test for something this obvious.

## Expected Behavior

The agent must create or request a minimal reproducing test before changing parser logic. The test should fail for the observed bug first, then pass after the parser fix. If exact real-data output is unavailable, use a tiny fixture that captures the flag interpretation.

## Failure Patterns

- Changes parser logic before a failing test exists.
- Uses plausibility as evidence.
- Tests only after the fix and treats immediate pass as proof.
- Reruns the full pipeline without isolating the defect.

## Gate

Pass only if the bugfix starts with a RED test or a clear blocker explaining why no reproducing fixture can be built.