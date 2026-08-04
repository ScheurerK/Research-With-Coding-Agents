# Antigravity Superpowers Parity Design

**Status:** Approved design
**Markplane task:** `TASK-cv9gy`

## Context

Markplane already installs its bundled Superpowers 6.1.1 skills into the global
Antigravity plugin at `~/.gemini/config/plugins/markplane`. The current local
installation contains the same 69 files as the installer bundle, but the health
check verifies only a few text markers. Antigravity-specific tool mappings are
available as a `using-superpowers` reference but are not guaranteed to influence
every relevant workflow. The installer also emits the older nested hook shape for
`PreInvocation` and `Stop`, while current Antigravity documentation requires direct
handler arrays for those events.

The Markplane activity-bar extension is currently deployed by copying its source
folder into VS Code-family extension directories. Antigravity IDE can list such a
folder without reliably registering it in its internal extension cache, leaving the
extension present on disk but absent from the Command Palette or UI. The installed
Antigravity IDE CLI supports the standard VSIX install, uninstall, list, and force
update operations needed to avoid this ghost-extension state.

The goal is functional parity for Markplane's portable Superpowers workflows in
Antigravity while ensuring that Markplane's locally bundled and customized version,
not an upstream version obtained from the internet, is authoritative.

## Goals

- Install and use the Markplane-bundled Superpowers skills in Antigravity.
- Make the Markplane plugin copy authoritative whenever duplicate skill names exist.
- Preserve unrelated or previously installed skills without deleting them.
- Map Superpowers actions to Antigravity-native subagent and task mechanisms.
- Generate hooks that conform to the current Antigravity event schema.
- Detect drift or corruption across the entire Markplane-owned plugin skill tree.
- Install the Markplane activity-bar interface through supported VSIX CLI commands.
- Keep installation, operation, and visual tooling local and telemetry-free.

## Non-Goals

- Removing or modifying third-party Superpowers installations.
- Downloading or updating Superpowers from the network.
- Reproducing Codex-specific tool names where Antigravity provides an equivalent
  native action.
- Moving project-scoped Markplane MCP back into Antigravity's global MCP config.
- Refactoring unrelated Codex, Claude Code, Markplane MCP, or visual extension code.
- Requiring Node.js, npm, or `npx` on an end user's machine.

## Chosen Approach

Use the existing global `markplane` Antigravity plugin as the authoritative,
namespaced distribution. The installer owns and reconciles that plugin's skills,
rules, and Markplane hook entries. Global Gemini instructions explicitly direct the
main agent to load `using-superpowers` from the Markplane plugin and to prefer all
Markplane-bundled skill copies over same-named external copies.

This provides global availability without creating per-workspace duplicates. A
separate installation into `~/.gemini/config/skills` is intentionally avoided
because it would create a second active copy and make conflict resolution less
predictable.

## Components

### Bundled Skill Source

`components/superpowers/skills` remains the single source of truth. The Antigravity
installer must resolve and validate this source before changing the plugin. It must
not call package managers, Git, web requests, or other network installation paths.

The installer reconciles the complete Markplane-owned plugin skill tree with the
bundle. Missing, changed, and stale extra files in the plugin are repaired so that
the destination is an exact recursive copy of the bundled source.

### Router And Version Priority

The managed block in `~/.gemini/GEMINI.md` and the plugin router rule state that:

1. Main agents load the Markplane plugin's `using-superpowers` before task actions.
2. Skills selected by that router come from the same Markplane plugin.
3. Same-named external skills are not selected over the Markplane copy.
4. The agent must not fetch, install, or upgrade Superpowers from the internet.

The rule is always present, even when no duplicate installation exists. Its conflict
language becomes operationally relevant only when a user has installed another copy
beforehand or does so later.

### Antigravity Tool Mapping

The bundled
`skills/using-superpowers/references/antigravity-tools.md` remains the canonical
mapping source and is also installed as an explicit Antigravity plugin rule. The
rule covers at least:

- subagent dispatch through `invoke_subagent`;
- full-capability and read-only subagent selection;
- task tracking through a Markdown task artifact created with `write_to_file` and
  maintained with Antigravity file-editing tools;
- the distinction between task artifacts and `manage_task`, which manages
  background processes;
- incremental checklist updates throughout multi-step work.

The missing `Subagent support` section in the current reference is completed so the
document has no broken internal link and gives a usable invocation contract.

### Antigravity Hooks

Global Markplane hooks remain in `~/.gemini/config/hooks.json`, where unrelated hook
namespaces are preserved. The Markplane namespace uses the current schema:

- `PreInvocation`: direct command-handler array;
- `PostToolUse`: matcher entries containing command handlers;
- `Stop`: direct command-handler array.

The existing adapter continues to translate Antigravity camelCase input and output
to the shared Markplane hook module. `PreInvocation` injects project context only on
the first model invocation. `PostToolUse` returns an empty object. `Stop` returns
`continue` only when Markplane quality checks require another pass and otherwise
allows termination.

### Markplane Interface Extension

The extension source in `packages/vscode-extension/source` is packaged as a VSIX
during the Markplane installer build. Both Windows installer variants include that
VSIX as payload. Packaging may use `@vscode/vsce` in the controlled build
environment; the installed product never invokes `npx` or downloads build tools.

`Install-VSCodeExtension.ps1` resolves the bundled VSIX and supported IDE CLIs. It
installs or updates the extension exclusively through:

- `antigravity-ide.cmd --install-extension <vsix> --force` for Antigravity IDE;
- `code --install-extension <vsix> --force` for Visual Studio Code.

The Antigravity CLI is resolved from the known Windows install location and command
discovery candidates. Successful installation is verified with
`--list-extensions --show-versions`, which must contain `local.markplane-vscode`.
Uninstall invokes `--uninstall-extension local.markplane-vscode` through each
available CLI. Direct copies into extension directories are removed from the
supported workflow and are not retained as a fallback.

When an IDE CLI is unavailable, the installer emits a warning for that IDE and
continues configuring the remaining integrations. The local `markplane serve` UI
remains the portable visual fallback. Installer output tells users with an open IDE
window to run `Developer: Reload Window` after installation or update.

### Health Check

`Test-MarkplaneAgentSkills.ps1` gains Antigravity checks for:

- exact recursive file parity between the installed package's `skills` directory
  and the Markplane plugin's `skills` directory;
- the authoritative-version instruction in `GEMINI.md`;
- the installed Antigravity Superpowers mapping rule and its required mappings;
- direct `PreInvocation` and `Stop` handlers plus matched `PostToolUse` handlers;
- the existing Markplane router, visuals, workspace MCP rule, and telemetry setting.

Drift inside the Markplane-owned plugin is a failing health check. Same-named skill
directories outside the Markplane plugin produce a visible warning but are not
deleted and do not fail installation when the authoritative copy is intact.

## Data Flow

1. The installer build packages the extension source as a VSIX and includes it in
   both Windows installer payloads.
2. The package installer resolves the local skill bundle and validates required
   files.
3. It reconciles the Markplane plugin against that bundle.
4. It installs the router, tool-mapping, visual, and workspace-MCP rules.
5. It updates the managed global Gemini instruction block.
6. It writes schema-correct Markplane hook entries while preserving foreign entries.
7. It installs the bundled VSIX through each available IDE CLI and verifies the
   registered extension identifier.
8. It runs or points to the health check, which validates content and configuration.
9. At conversation start, Antigravity applies the global priority rule and exposes
   the plugin skills for progressive disclosure.
10. The Markplane `using-superpowers` router selects relevant bundled skills.
11. When those skills request subagents or task tracking, Antigravity-native mappings
   govern the tool calls.

## Error Handling

- Missing or incomplete local bundle: fail before plugin reconciliation with the
  exact missing path.
- Plugin content drift: repair during installation; fail the health check if drift
  remains.
- Same-named external skills: warn and preserve them.
- Invalid foreign JSON: retain the installer's existing explicit parse failure rather
  than silently overwriting user configuration.
- Hook runtime errors: remain fail-open so Antigravity stays usable, with diagnostics
  written to stderr.
- Missing IDE CLI: warn, skip only that IDE, and retain `markplane serve` as the
  visual fallback.
- VSIX packaging or CLI installation failure: fail the relevant build or install
  step with the command's exit code and output; do not silently copy source folders.
- Installed extension absent from `--list-extensions`: treat the installation as
  failed and request `Developer: Reload Window` only after a successful registration.
- Missing project-local Markplane MCP: retain CLI and hook operation and direct the
  user to `Install-AntigravityWorkspace.ps1` when MCP tools are needed.

## Testing

Implementation follows test-first development. Focused Pester coverage must first
fail for the new requirements and then verify:

- exact skill-tree installation and stale-file cleanup;
- Markplane priority instructions and prohibition of network installation;
- preservation and warning behavior for a same-named external skill;
- installation of the explicit Antigravity mapping rule;
- complete subagent and task-artifact mapping content;
- current direct-handler hook schema;
- installer idempotence and uninstall isolation;
- health-check failure for a modified Markplane plugin file;
- health-check success with a warning for an intact plugin plus a same-named
  external skill;
- adapter outputs for representative `PreInvocation`, `PostToolUse`, and `Stop`
  payloads;
- build-time VSIX creation and inclusion in both installer definitions;
- `--install-extension <vsix> --force`, verification, and uninstall calls through
  injected fake VS Code and Antigravity CLI executables;
- warning behavior when one IDE CLI is missing and rejection of direct folder-copy
  fallback behavior.

Verification also includes PowerShell parser checks, the complete Pester suite, an
isolated installer run, and a local Antigravity hook smoke test using documented
event payloads.

## Acceptance Criteria

- A clean install exposes every bundled Markplane skill to Antigravity through the
  `markplane` plugin.
- The plugin skill tree exactly matches the package bundle after installation.
- Global instructions unambiguously prioritize the Markplane plugin copy and forbid
  network replacement of Superpowers.
- A pre-existing external copy is preserved and reported without becoming the
  preferred source.
- Superpowers subagent and task-tracking actions have valid Antigravity-native
  equivalents.
- Installed hook JSON conforms to the current Antigravity schema.
- Antigravity IDE and VS Code receive the bundled extension through their official
  VSIX CLI installation path, and registration is verified by extension ID.
- End-user extension installation requires no Node.js or network package fetch.
- Focused and full tests pass, and the health check detects deliberate plugin drift.
- Existing project-local MCP behavior, unrelated Gemini configuration, privacy
  defaults, and uninstall isolation remain intact.

## References

- Antigravity plugins: https://www.antigravity.google/docs/plugins
- Antigravity skills: https://www.antigravity.google/docs/skills
- Antigravity rules: https://www.antigravity.google/docs/rules-workflows
- Antigravity hooks: https://www.antigravity.google/docs/hooks
- Antigravity MCP: https://www.antigravity.google/docs/mcp
- VS Code extension CLI: https://code.visualstudio.com/docs/configure/command-line
- VSIX packaging: https://code.visualstudio.com/api/working-with-extensions/publishing-extension
