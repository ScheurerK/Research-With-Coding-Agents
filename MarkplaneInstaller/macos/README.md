# Markplane Claude Code integration for macOS/Linux

Bash equivalent of the Windows Inno Setup installer
(`MarkplaneAgentInstaller.iss`) for Claude Code: MCP server registration,
SessionStart/PostToolUse/SubagentStart/Stop/SessionEnd hooks, bundled
Superpowers-style skills, and the VS Code extension.

**Scope note:** this package covers Claude Code only — the same slice as
the Windows "agent-neutral" `MarkplaneAgentSetup` package (Claude MCP +
hooks + skills + VS Code extension), not the Codex-branded package. It does
not touch `~/.codex/` or write an `AGENTS.md`. If you also want Codex
support on macOS, ask for it separately — the shared hook library
(`lib/markplane-claude-hooks.sh`) already handles Codex-shaped tool names
(`shell_command`, `exec_command`, `apply_patch`) in its PostToolUse
relevance check, so a Codex-side entry point would be a thin addition, not
a rewrite.

## Dependencies

- `bash`, `awk`, `shasum`, `grep`, `sed` — all present by default on macOS
  and any common Linux distro.
- `jq` — **not** preinstalled on macOS. Install with:
  ```
  brew install jq
  ```
- The `markplane` binary on `PATH` (Homebrew or `install.sh` from the repo
  root — see the main [README](../../README.md#installation)). This
  installer does **not** bundle or install the binary itself; it only wires
  up Claude Code's side of the integration.
- The `claude` CLI on `PATH`, for MCP registration. If it's missing,
  `configure-claude-code.sh` prints a warning and skips MCP registration
  rather than failing the whole install (you can register manually later
  with `claude mcp add ...`).

## Install

```bash
./install-markplane-mac.sh
```

Options:

| Flag | Default | Purpose |
|------|---------|---------|
| `--scope <user\|local\|project>` | `user` | Claude Code MCP registration scope |
| `--markplane-exe <path>` | first `markplane` on `PATH` | Explicit binary path |
| `--max-context-chars <n>` | `6000` | Cap on injected hook context size |
| `--skip-vscode` | off | Skip the VS Code extension step |

This runs, in order: `configure-claude-code.sh` (MCP registration) →
`install-agent-skills.sh` (skills + `~/.claude/CLAUDE.md` managed block) →
`install-claude-code-hooks.sh` (wires hooks into `~/.claude/settings.json`)
→ `install-vscode-extension.sh` (unless `--skip-vscode`).

Each step is also runnable standalone — see the top of each script for its
own flags.

## What gets installed where

| What | Where |
|------|-------|
| Skills | `~/.claude/skills/<name>/` |
| Agent hint block | `~/.claude/CLAUDE.md` (between `<!-- BEGIN/END MARKPLANE RESEARCH CHECKPOINT SKILL -->` markers — safe to re-run, never duplicates) |
| Hooks | `~/.claude/settings.json` `.hooks.{SessionStart,PostToolUse,SubagentStart,Stop,SessionEnd}` (a backup is written to `settings.json.markplane.bak` the first time this repo touches the file) |
| Hook session state | `~/Library/Application Support/Markplane/claude-hooks/sessions/` |
| VS Code extension | `~/.vscode/extensions/local.markplane-vscode-0.1.2/` |
| Superpowers telemetry opt-out | `export SUPERPOWERS_DISABLE_TELEMETRY=1` appended to `~/.zshrc` and `~/.bash_profile`, between `# BEGIN/END MARKPLANE` markers |
| MCP registration | via `claude mcp add`, not a file this repo owns |

Re-running the installer is idempotent: it replaces its own previous
entries in each of the above rather than duplicating them, and never
touches unrelated hooks/skills/config that were already there.

## Uninstall

```bash
./install-markplane-mac.sh --uninstall
```

Removes the skills, the CLAUDE.md hint block, and the hooks. It does
**not** remove the `markplane` binary or the Claude Code MCP registration —
run `claude mcp remove markplane` if you want that gone too.

## How this relates to the Windows installer

This is a structural bash port of:

| Windows (PowerShell / Inno Setup) | macOS (this directory) |
|---|---|
| `hooks/MarkplaneClaudeHooks.psm1` | `lib/markplane-claude-hooks.sh` |
| `hooks/Invoke-MarkplaneClaudeHook.ps1` | `invoke-markplane-claude-hook.sh` |
| `Configure-ClaudeCode.ps1` | `configure-claude-code.sh` |
| `Install-ClaudeCodeHooks.ps1` | `install-claude-code-hooks.sh` |
| `Install-MarkplaneAgentSkills.ps1` (Claude side only) | `install-agent-skills.sh` |
| `Install-VSCodeExtension.ps1` | `install-vscode-extension.sh` |
| `MarkplaneAgentInstaller.iss` `[Run]`/`[UninstallRun]` | `install-markplane-mac.sh` |

Differences driven by platform, not by choice:

- **No GNU `flock`/`timeout` on macOS.** The project lock is a portable
  `mkdir`-based spin-lock with stale-lock detection via `kill -0`; the
  markplane CLI is run with a manual background+`kill` timeout instead of
  `timeout`/`gtimeout`.
- **JSON via `jq`**, not `ConvertFrom-Json`/`ConvertTo-Json` — the one new
  external dependency this package adds.
- **Hashing via `shasum -a 256`** (present on macOS via the system Perl),
  not `System.Security.Cryptography.SHA256`.
- **Hook command shape**: Windows hook entries invoke `powershell.exe -File
  <script> -Event ... -MarkplaneExe ...` (an interpreter+args array,
  because the hook script needs an interpreter). On macOS the hook script
  is directly executable, so the settings.json entry is a single quoted
  `command` string: `"<path>/invoke-markplane-claude-hook.sh" --event ...
  --markplane-exe ... --state-root ...`.

## Testing

```bash
cd tests
./run-tests.sh
```

37 assertions covering project-root discovery, hashing, context truncation,
session-state persistence, the project lock, all `PostToolUse` relevance
branches, both quality-gate fixtures (placeholder task, unlinked Superpowers
plan), and the full `SessionStart`/`PostToolUse`/`Stop` event dispatch —
including the two-attempt Stop retry ladder — against a fake `markplane`
CLI stub. No real `markplane`/`claude` binaries or network access required.

The install/uninstall scripts (`install-agent-skills.sh`,
`install-claude-code-hooks.sh`, `install-vscode-extension.sh`,
`install-markplane-mac.sh`) were exercised manually end-to-end (fresh
install, idempotent re-install, uninstall) against an isolated `$HOME`
during development, but do not yet have their own assertions in
`run-tests.sh` — a reasonable follow-up if this package sees real use.

**Not yet run on real macOS.** This was developed and tested on Linux-shaped
bash (Git Bash / MSYS2 on Windows) with `jq`, `shasum`, `awk` available —
the same tool versions macOS ships or that `brew install jq` provides, but
not the actual Darwin kernel/BSD userland. Before relying on this in
production, run `tests/run-tests.sh` on an actual Mac once to confirm.
