---
id: TASK-rypkc
title: Fix installer hygiene and port Claude Code integration to macOS
status: done
priority: medium
type: feature
effort: large
epic: EPIC-9rht7
plan: null
depends_on: []
blocks: []
related: [TASK-u6y58]
assignee: null
tags: []
position: a4
created: 2026-07-29
updated: 2026-07-29
---

# Fix installer hygiene and port Claude Code integration to macOS

## Description

Two follow-ups from [[TASK-u6y58]]'s installer audit, both explicitly
requested: (1) the two installer-hygiene issues that were deliberately
deferred out of that task's scope, and (2) a full native macOS equivalent
of the Windows Claude Code installer (MCP registration, hooks, skills, VS
Code extension) — chosen over a docs-only approach or a minimal
pwsh-compatibility shim after being offered all three as options.

## Acceptance Criteria

- [x] `MarkplaneAgentInstaller.iss` no longer bundles the unused
      `Install-CodexHooks.ps1` (it was never invoked in that package).
- [x] Both `.iss` packages show a visible post-install message (not just a
      hidden-process warning) when the `claude` CLI isn't found, with the
      manual registration command to run instead. Verified by actually
      compiling both packages with Inno Setup 6 (found at
      `%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe`) — not just written
      and assumed correct.
- [x] `MarkplaneInstaller/macos/` provides a bash equivalent of the
      Windows Claude-Code-facing installer surface: `lib/markplane-claude-hooks.sh`
      (hook lifecycle + quality gates), `invoke-markplane-claude-hook.sh`,
      `configure-claude-code.sh`, `install-claude-code-hooks.sh`,
      `install-agent-skills.sh`, `install-vscode-extension.sh`, and the
      `install-markplane-mac.sh` orchestrator (with `--uninstall`).
      Scoped to Claude Code only, matching the Windows agent-neutral
      package — no Codex-specific paths.
- [x] `tests/run-tests.sh` (37 assertions) exercises project-root discovery,
      hashing, context truncation, session-state persistence, the project
      lock, every `PostToolUse` relevance branch, both quality-gate
      fixtures, and the full `SessionStart`/`PostToolUse`/`Stop` dispatch
      including the two-attempt retry ladder, against a fake `markplane`
      CLI — all passing.
- [x] The full install → idempotent reinstall → uninstall cycle for every
      installer script was run end-to-end against an isolated `$HOME` with
      fake `markplane`/`claude` CLIs on `PATH`, not just unit-level.

## Notes

Found and fixed one real bug during testing, not just porting: the Stop
event's check+quality result merge inferred "did anything fail" from
whether the failing output string was non-empty, which silently swallowed
failures whose only output was on stderr (a plausible real `markplane
check` failure mode). Fixed by tracking failure with an explicit flag
instead of string emptiness — caught only because a test deliberately
exercised a stderr-only failure, not a happy-path assumption.

Also confirmed a pre-existing (not introduced here) quirk in the original
PowerShell: `Test-MarkplaneChecklistHasConcreteItem` checks a checklist
label like "Criterion 1" against a placeholder regex written for the full
line "- [ ] Criterion 1", so a bare "Criterion 1" label never actually
matches that specific placeholder pattern. Ported faithfully rather than
silently fixed, since the goal was behavioral parity with the existing
Windows implementation.

**Not yet run on real macOS** — developed and tested against Linux-shaped
bash/jq/shasum/awk on this Windows machine (Git Bash + a winget-installed
jq), not the actual Darwin kernel. Run `macos/tests/run-tests.sh` on a real
Mac once before relying on this in production.

This repository currently has no working git history (the outer folder's
`.git` is present but empty/uninitialized, and the inner `markplane-master/`
Rust checkout has no `.git` at all) — none of this session's changes are
under version control yet.

## References

- MarkplaneInstaller/MarkplaneAgentInstaller.iss
- MarkplaneInstaller/MarkplaneInstaller.iss
- MarkplaneInstaller/macos/
- MarkplaneInstaller/macos/tests/run-tests.sh
- MarkplaneInstaller/macos/README.md
