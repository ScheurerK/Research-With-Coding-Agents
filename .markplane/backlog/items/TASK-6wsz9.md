---
id: TASK-6wsz9
title: Fix Antigravity 2 extension root
status: done
priority: high
type: bug
effort: medium
epic: null
plan: null
depends_on: []
blocks: []
related: []
assignee: null
tags: []
position: aL
created: 2026-08-04
updated: 2026-08-04
---

# Fix Antigravity 2 extension root

## Description

Antigravity showed the Markplane plugin rules, but the visual Markplane IDE extension disappeared. Local inspection showed that current Antigravity data is stored under `%USERPROFILE%\.gemini\antigravity`, while the installer only copied the VS Code-style extension to older Antigravity roots.

## Steps to Reproduce

1. Install Markplane with the previous installer.
2. Start current Antigravity.
3. Check whether the Markplane activity-bar view is visible.

## Expected Behavior

The Markplane extension is installed into every supported local VS Code and Antigravity extension root, including `%USERPROFILE%\.gemini\antigravity\extensions`.

## Actual Behavior

The extension was present in `%USERPROFILE%\.gemini\antigravity-ide\extensions` and `%USERPROFILE%\.antigravity-ide\extensions`, but missing from `%USERPROFILE%\.gemini\antigravity\extensions`.

## Notes

- Added `%USERPROFILE%\.gemini\antigravity\extensions` as a default Antigravity extension root in `MarkplaneInstaller/Install-VSCodeExtension.ps1`.
- Added regression coverage for the new root in `MarkplaneInstaller/tests/Install-VSCodeExtension.Tests.ps1`.
- Updated README wording to describe Antigravity 2 extension roots.
- Installed the extension locally into the new Antigravity root on 2026-08-04.
- Made Antigravity hook-state cleanup warn rather than fail when user-profile session state cannot be removed by a sandboxed test run.

## References

- Antigravity plugin docs: https://antigravity.google/docs/plugins
