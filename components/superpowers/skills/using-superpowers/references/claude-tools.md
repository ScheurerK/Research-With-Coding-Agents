# Claude Code Tool Mapping

Skills speak in actions ("dispatch a subagent", "create a todo", "set up an
isolated workspace"). Superpowers' generic vocabulary was written against
Claude Code's native tools, so most actions already map 1:1 — this file only
covers the places where Claude Code's actual lifecycle differs from what a
skill written for a more manual harness (see `codex-tools.md`) assumes.

| Action skills request | Claude Code tool |
|---|---|
| Dispatch a subagent (`Subagent (general-purpose):` template) | `Agent` tool with `subagent_type` (`general-purpose`, `Explore`, `Plan`, or another listed type) |
| Task tracking ("create a todo", "mark complete") | `TodoWrite` — native, exact match, no translation needed |
| Set up an isolated workspace | `EnterWorktree` / `ExitWorktree` if available (see `using-git-worktrees` Step 1a) — check for these before falling back to manual `git worktree` |
| Present a plan for approval | `EnterPlanMode` → explore/design → `ExitPlanMode` (reads the plan file you wrote); do not ask "does this plan look OK?" as a text question |
| Ask the user to choose between options | `AskUserQuestion` |

## Subagent lifecycle: no explicit close step

Unlike Codex's `spawn_agent`/`wait_agent`/`close_agent` model (see
`codex-tools.md`), Claude Code's `Agent` tool defaults to running in the
**background**: dispatching it returns immediately, and you get a
notification when it completes — there is nothing to poll and nothing to
explicitly close. Do not fabricate a "wait for agent" or "close agent" step;
just continue other work (or end your turn) and let the completion
notification arrive on its own turn.

To continue a specific subagent instead of re-dispatching cold — e.g. after
a task reviewer comes back with follow-up questions — use `SendMessage` with
that agent's id or name. A fresh `Agent` call has no memory of a prior run;
`SendMessage` is the only way to resume one with its context intact.

Set `run_in_background: false` only when you genuinely need the result
before you can proceed (e.g. research whose findings determine your next
step) — otherwise leave the default so independent work can proceed in
parallel per `dispatching-parallel-agents`.

## Compact execution state

`ExitPlanMode` performs the one full plan read needed to begin execution. Create
a compact checklist and task brief from it. Do not re-read the full plan for every
task or turn. Reopen it only when the plan changed or compact recovery has no
usable brief or ledger.

## Scheduled / looping execution

For skills like `loop` that need to self-pace across wakeups rather than
poll in a tight cycle, Claude Code provides `ScheduleWakeup` (schedule the
next firing, with a reason, instead of sleeping inline) and `Monitor`
(stream events from a background process one notification per line, for an
until-loop rather than a fixed sleep). Prefer these over chained `sleep`
commands or busy-polling a background task's status.
