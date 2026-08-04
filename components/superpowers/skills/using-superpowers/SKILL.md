---
name: using-superpowers
description: Use when starting any conversation, before clarifying questions or actions, to decide which available skills must be read for the task
---

# Using Superpowers

If dispatched as a subagent for a narrow task, stop using this skill.

Before any response or action:

1. Check the available skill names and descriptions against the user's request.
2. Read each skill that is explicitly named or clearly applies. If no other skill applies, continue after this bootstrap.
3. Apply process skills before implementation/domain skills. Typical examples: `brainstorming` before new behavior, `systematic-debugging` before fixes, `test-driven-development` before feature or bugfix implementation.
4. Announce the selected skills and purpose in one short line, then follow their instructions.

User, repository, and system instructions outrank skills. Use them to resolve conflicts.

Read `references/codex-tools.md` only when the task involves Codex-specific multi-agent support, worktrees, branch finishing, or sandbox handoff behavior. Read `references/claude-tools.md` only when the task involves Claude Code's background subagent lifecycle, plan-mode approval flow, or scheduled/looping execution. Read `references/antigravity-tools.md` only when the task involves Antigravity/Gemini tool, subagent, artifact, or task-tracking behavior. The archived upstream rule is in `references/upstream-superpowers-rule.md` for audits, not routine loading.

## Durable State Over Memory

Before compacting, writing a progress summary, or reconstructing context after compaction: content that already lives in a durably-stored file (`.markplane/` items, a Superpowers ledger, tracked docs) is ground truth on disk. Reference it by ID/path (e.g. "TASK-rypkc: done, see file") instead of reproducing its contents — duplicating a file's full body into a summary wastes space and can drift from what the next read would show.

During plan execution, read the full plan once. Continue from the compact task
brief, active task ID, and progress ledger. Reopen the full plan only when the
file changed or compact recovery has no usable execution artifacts.

## Red Flags

Stop and re-check skills when tempted to gather files first, ask a clarifying question first, rely on memory of a skill, or treat a request as too small for skills.
