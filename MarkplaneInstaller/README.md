# Markplane Installer

This folder contains Windows installer payloads for Markplane MCP integrations.

## Contents

- `markplane.exe` - the prebuilt Markplane binary with embedded web UI.
- `Install-MarkplaneForCodex.ps1` - post-install configuration for PATH, Codex MCP, and AGENTS instructions.
- `Install-MarkplaneForAgents.ps1` - agent-neutral Markplane/PATH installer.
- `Install-MarkplaneAgentSkills.ps1` - installs bundled Markplane research skills into Codex and Claude Code and adds managed skill hints.
- `Install-AntigravityIntegration.ps1` - installs bundled skills, lifecycle hooks, Gemini global instructions, local visual rules, and removes stale global Markplane MCP entries for Google Antigravity.
- `Install-AntigravityWorkspace.ps1` - writes project-local Antigravity MCP config with `markplane mcp --project <project-root>` and `cwd` for a single initialized Markplane workspace.
- `Test-MarkplaneAgentSkills.ps1` - local health check for the router bootstrap, installed skills, Antigravity rules, and Superpowers telemetry setting.
- `Install-VSCodeExtension.ps1` - installs, verifies, and uninstalls the bundled Markplane VSIX through the official VS Code and Antigravity IDE CLIs.
- `Configure-ClaudeCode.ps1` - helper to register Markplane MCP with Claude Code user scope via the Claude CLI.
- `Install-ClaudeCodeHooks.ps1` - installs or removes Claude Code lifecycle hooks for project-local Markplane context.
- `hooks/` - Claude Code hook runtime and event entrypoint.
- `markplane-agents-extension.txt` - managed Codex AGENTS.md snippet for Markplane logging.
- `research-checkpoint-agents-extension.txt` - managed Codex/Claude hint for Superpowers plus research checkpoint commits.
- `skills/` - bundled portable skills: Superpowers 6.1.1 plus `research-repo-governance` and `research-checkpoint-commits`.
- `vscode-extension/` - local VS Code webview extension payload and bundled `markplane-vscode-0.1.2.vsix` build output.
- `agent-config-templates/` - MCP configuration snippets for Claude Code, Cursor, VS Code, Windsurf, Zed, and Continue.
- `MarkplaneInstaller.iss` - Inno Setup installer definition.
- `Build-Installer.ps1` - helper that compiles the Codex-oriented `.iss` file.
- `MarkplaneAgentInstaller.iss` - agent-neutral installer definition.
- `Build-AgentInstaller.ps1` - helper that compiles the agent-neutral installer.

## Build

Install Inno Setup 6, then run the Codex-specific build:

```powershell
powershell -ExecutionPolicy Bypass -File .\Build-Installer.ps1
```

The output will be:

```text
Output\MarkplaneSetup-0.1.2.exe
```

For the agent-neutral installer:

```powershell
powershell -ExecutionPolicy Bypass -File .\Build-AgentInstaller.ps1
```

The output will be:

```text
Output\MarkplaneAgentSetup-0.1.2.exe
```

## VSIX Build

Installer builds package `vscode-extension\markplane-vscode-0.1.2.vsix` from the local extension payload. This build-time prerequisite may use `vsce` or `npx` only in the build environment. End users receive the bundled VSIX and do not need Node.js, npm, npx, or a network download.

## Install Behavior

The Codex-oriented installer:

- installs files to `%LOCALAPPDATA%\Programs\Markplane`
- adds that directory to the user PATH
- configures Markplane as a global Codex MCP server in `%USERPROFILE%\.codex\config.toml`
- appends or replaces a managed Markplane block in `%USERPROFILE%\.codex\AGENTS.md`
- installs Superpowers 6.1.1, `research-repo-governance`, and `research-checkpoint-commits` into `%USERPROFILE%\.codex\skills` and `%USERPROFILE%\.claude\skills`
- appends or replaces a managed research checkpoint hint block in `%USERPROFILE%\.codex\AGENTS.md` and `%USERPROFILE%\.claude\CLAUDE.md`
- installs the bundled `markplane-vscode-0.1.2.vsix` through available VS Code and Antigravity IDE CLIs, with registration verification
- registers Markplane MCP for Claude Code with `claude mcp add --scope user` when `claude` is available
- installs Claude Code lifecycle hooks that auto-detect the nearest `.markplane` project per working directory
- installs Codex lifecycle hooks in `%USERPROFILE%\.codex\hooks.json` for the same project-local Markplane context and quality gates
- installs Antigravity Gemini integration in `%USERPROFILE%\.gemini`: plugin skills/rules, hooks, global router hint, Markplane visual guidance, and cleanup for stale global Markplane MCP entries
- sets SUPERPOWERS_DISABLE_TELEMETRY=1 for the current user and bundles a patched visual brainstorming companion that does not load external branding assets

The managed hint is intentionally short but strict: main agents must load `using-superpowers` before file reads, tool calls, planning, clarification questions, or implementation. Narrow subagents are exempt and receive the compact task contract instead. `research-repo-governance` controls research repository boundaries; Superpowers handles process work inside those boundaries; `research-checkpoint-commits` controls Markplane-owned research edits, staging, and commits.

The bundled Superpowers policy is shared by Codex, Claude Code, and Antigravity
Gemini. Automatic reasoning is capped at `high`; routine work uses the runtime
default and mechanical work uses a cheaper model when available. Implementation
plans stay at or below 250 lines by default and are read once at execution start.
Agents resume from compact task briefs, active task IDs, and progress ledgers,
reopening the full plan only after a real plan change or missing recovery state.

After installation, run:

```powershell
powershell -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\Programs\Markplane\Test-MarkplaneAgentSkills.ps1"
```

The check verifies the managed Codex/Claude hint blocks, the installed `using-superpowers` skill, and `SUPERPOWERS_DISABLE_TELEMETRY=1`.

The uninstaller removes the PATH entry, managed Codex Markplane blocks, Markplane Claude Code hooks, Markplane Codex hooks, hook session state, bundled research checkpoint skills, managed skill hint blocks, and `local.markplane-vscode` through available IDE CLIs, then removes installed files.

The agent-neutral installer installs Markplane, updates PATH, includes MCP templates, registers Claude Code MCP when the Claude CLI is available, installs bundled Markplane research skills for local Codex and Claude Code, installs Markplane Claude Code hooks, installs Antigravity Gemini integration, and installs the bundled Markplane VSIX through available VS Code and Antigravity IDE CLIs. It does not register MCP servers for Codex, Cursor, VS Code, Windsurf, Zed, or Continue automatically, and Antigravity Markplane MCP is intentionally configured per workspace.


## Codex Integration

Codex MCP registration remains in `%USERPROFILE%\.codex\config.toml`; hooks are kept separately in `%USERPROFILE%\.codex\hooks.json`. The Codex hook installer preserves unrelated hooks, creates a one-time `.markplane.bak`, and replaces only handlers that call the exact installed `hooks\Invoke-MarkplaneCodexHook.ps1` path.

Installed Codex events:

- `SessionStart` for `startup|resume|clear|compact`: finds the nearest parent `.markplane`, runs `markplane sync`, and injects `.markplane/.context/summary.md` capped at 6000 characters.
- `PostToolUse` for editor, patch, shell, and Markplane MCP tools: syncs after Markplane item edits, Superpowers plan edits under `docs/superpowers/plans`, direct Markplane CLI mutations, or mutating Markplane MCP tools.
- `SubagentStart` for `*`: injects a short project-root, read-order, Superpowers-plan-linking, and research-governance reminder capped around 800 characters.
- `Stop` and `SubagentStop`: run local `markplane sync`, `markplane check`, and hook-level quality gates. Codex Stop checks run even if no write hook was observed, so patch-based edits still get a final gate. One failing check asks for one correction pass; the next failed stop emits a visible warning.

The hooks do not use PreToolUse blocks, HTTP hooks, prompt hooks, agent hooks, or telemetry. Codex may ask the user to trust the hook commands on first use depending on the local hook policy.

## Antigravity Gemini Integration

Antigravity is configured through its native Gemini customization paths:

- Global plugin: `%USERPROFILE%\.gemini\config\plugins\markplane`
- Global Gemini instructions: `%USERPROFILE%\.gemini\GEMINI.md`
- Global hooks: `%USERPROFILE%\.gemini\config\hooks.json`
- Workspace MCP server: `<project>\.agents\mcp_config.json`

The Markplane plugin contains the authoritative local Superpowers bundle. The installer never downloads or substitutes an upstream Superpowers copy. `Test-MarkplaneAgentSkills.ps1` recursively compares the complete installed plugin skill tree with the bundled source and warns about same-named external skills without deleting or modifying them.

The installer writes only its `markplane` entry in `hooks.json`, preserving unrelated top-level hook configuration. It uses the current Antigravity schema: direct `PreInvocation` and `Stop` command handlers and matched `PostToolUse` hook handlers.

Markplane MCP is not installed globally for Antigravity. The MCP process is project-scoped and fails during initialize when Antigravity starts it outside a directory tree containing `.markplane`. If a project needs MCP tools, run this once from or for that project:

```powershell
powershell -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\Programs\Markplane\Install-AntigravityWorkspace.ps1" -ProjectRoot "<project-root>"
```

That command writes `.agents\mcp_config.json` with `markplane mcp --project <project-root>` and `cwd` set to the same root while preserving unrelated MCP servers.

Installed Antigravity events:

- `PreInvocation`: on the first model invocation of a conversation, resolves the nearest `.markplane` project from `workspacePaths`, runs `markplane sync`, and injects the capped project summary as an ephemeral message.
- `PostToolUse`: matches Antigravity write/edit/command and Markplane MCP tools, syncs when Markplane items or Superpowers plans changed, and marks the conversation for final checks.
- `Stop`: runs local `markplane sync`, `markplane check`, and hook-level quality gates; one failing check asks for one correction pass, then exits with a visible warning.

Markplane visuals are available through a bundled Antigravity rule. When the user asks for a graph, board, roadmap, project overview, or other Markplane visual, Gemini should run `markplane serve` from the resolved project root and open the local URL with Antigravity's browser tools. This local web UI is the supported fallback when an IDE CLI is unavailable or the activity-bar interface is not active.

## VSIX Installation And Verification

The installer uses the bundled `markplane-vscode-0.1.2.vsix`; it does not copy an extension folder into an IDE extension root. For each available official CLI, it runs `--install-extension <vsix> --force` and verifies registration with `--list-extensions --show-versions`.

To install from an unpacked Markplane directory:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-VSCodeExtension.ps1 -VsixPath .\vscode-extension\markplane-vscode-0.1.2.vsix
```

After a successful VSIX install, run `Developer: Reload Window` in each open VS Code or Antigravity IDE window. If an IDE CLI is unavailable, the installer warns and skips that IDE; use `markplane serve` from the Markplane project root as the local visual fallback.

To remove the extension by ID, use the same helper with `-Uninstall`, or run the official CLI directly:

```powershell
code --uninstall-extension local.markplane-vscode
antigravity-ide --uninstall-extension local.markplane-vscode
```

## Claude Code Integration

Claude Code MCP registration is managed through the Claude CLI instead of hand-editing `~/.claude.json`:

```powershell
powershell -ExecutionPolicy Bypass -File .\Configure-ClaudeCode.ps1 -Scope user -MarkplaneExe "<install-dir>\markplane.exe"
```

If `claude` is not in `PATH`, the helper prints a warning and leaves Claude settings unchanged. After a successful registration it removes only the legacy `mcpServers.markplane` entry from `~/.claude/settings.json`; unrelated servers such as MATLAB remain intact. Markplane is not configured with `alwaysLoad`, so its tool schemas are loaded only when Claude needs the MCP server.

The hook installer writes five user-scoped hooks to `~/.claude/settings.json`:

- `SessionStart` for `startup|resume|clear|compact`: finds the nearest parent `.markplane`, runs `markplane sync`, and injects `.markplane/.context/summary.md` as `additionalContext` capped at 6000 characters.
- `PostToolUse` for `Edit|Write|Bash|mcp__markplane__.*`: syncs only after Markplane file edits, Superpowers plan edits under `docs/superpowers/plans`, direct Markplane CLI mutations, or mutating Markplane MCP tools.
- `SubagentStart` for `*`: injects a short project-root, read-order, Superpowers-plan-linking, and research-governance reminder capped around 800 characters.
- `Stop`: after Markplane activity, runs `markplane sync`, normal `markplane check`, and hook-level quality gates for Task/Plan readiness and Superpowers plan links; one failing check asks Claude for one correction pass, a second failure produces a visible warning.
- `SessionEnd`: removes local hook session state.

Superpowers implementation plans may live in `docs/superpowers/plans`, but each plan must be linked or summarized from a Markplane PLAN item. Markplane remains the source of truth for active work, while Superpowers can provide detailed execution plans.

Inspect Claude Code with `/hooks` and `/mcp` after installation. The hooks are global, but every invocation resolves the Markplane project from Claude's current `cwd`, so two VS Code or Claude windows in different projects receive different summaries.

## Privacy And Token Cost

The Claude and Codex hooks do not use HTTP, prompt hooks, agent hooks, or telemetry. The Antigravity hooks also run only local PowerShell and `markplane.exe`; `PreInvocation` injects bounded ephemeral context through Antigravity's documented hook output contract. They run the installed `markplane.exe` by absolute path and store transient state under `%LOCALAPPDATA%\Markplane\claude-hooks\sessions`, `%LOCALAPPDATA%\Markplane\codex-hooks\sessions`, or `%LOCALAPPDATA%\Markplane\antigravity-hooks\sessions`. The injected Markplane summary becomes normal Claude, Codex, or Gemini conversation context and is therefore sent to the already used model service as part of that active session.

Expected context impact is bounded: up to 6000 characters, roughly 1500 tokens, on session start, resume, clear, or compaction; up to about 800 characters, roughly 200 tokens, per subagent start. Successful `PostToolUse`, `Stop`, and `SessionEnd` hooks write no model context.
