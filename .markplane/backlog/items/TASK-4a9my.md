---
id: TASK-4a9my
title: Add project-wide file locking to Markplane
status: done
priority: high
type: bug
effort: medium
epic: EPIC-gm2tk
plan: null
depends_on: []
blocks: []
related: []
assignee: scheurer
tags: []
position: a9
created: 2026-07-21
updated: 2026-07-21
---

# Add project-wide file locking to Markplane

## Description

Concurrent Markplane entrypoints on Windows could collide while writing `.markplane/`
files. The old internal pattern used per-item file locks together with atomic
replacement, which can fail on Windows because a locked file cannot be replaced.
Concurrent `sync`, MCP, CLI, hook, or web operations could also update generated
indexes and context files at the same time.

## Steps to Reproduce

1. Keep a Markplane process or MCP server open for a project.
2. Trigger another Markplane mutation or `sync` from a separate window.
3. Observe intermittent Windows file lock or replacement failures.

## Expected Behavior

Markplane-owned mutations for the same project should serialize across CLI, MCP,
hook, and web entrypoints without relying on PATH state or per-item locks.

## Actual Behavior

Multiple processes could attempt to rewrite the same project files concurrently,
and Windows can reject the replacement when a target file is locked.

## Notes

- Added a project-wide OS lock at `.markplane/.lock` in `markplane-core`.
- Added a reentrant in-process guard so high-level operations can call lower-level
  locked helpers safely.
- Routed config, item, index, context, link, archive, and sync writes through the
  project lock.
- Kept legacy item-lock helpers public for compatibility, but stopped using them
  for core mutations.
- Added `.lock` to the generated `.markplane/.gitignore` template and this
  project's `.markplane/.gitignore`.
- Updated the installer payload and local `markplane.exe` installations from the
  new release build.
- Verification:
  - `cargo test -p markplane-core --offline`: 293 passed.
  - `cargo test -p markplane-cli`: 75 CLI tests and 69 MCP integration tests passed.
  - Release build: `cargo build -p markplane-cli --release`.
  - Parallel smoke test: 10 simultaneous `markplane sync` jobs on one project, 0 failed.

## References
