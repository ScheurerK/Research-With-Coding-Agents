---
description: Lint all Markplane crates (cargo clippy --workspace, must be warning-free)
---

Run `cargo clippy --workspace` from the repo root. Per this repo's CLAUDE.md,
the workspace must be warning-free — treat any clippy warning as a failure,
not just errors. Report each finding with file:line; do not attempt fixes
unless asked.
