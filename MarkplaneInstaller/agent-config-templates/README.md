# Markplane MCP templates for other agents

These snippets assume `markplane.exe` was installed by the installer and is available on PATH as `markplane`.

Markplane must be initialized per project before MCP can manage project state:

```powershell
markplane init --name "My Project"
```

If the AI tool launches MCP from a different working directory than your project, add:

```json
"args": ["mcp", "--project", "C:/path/to/project"]
```

instead of:

```json
"args": ["mcp"]
```

## Claude Code

Preferred user-level setup:

```powershell
claude mcp add --transport stdio --scope user markplane -- markplane mcp
```

Or copy `.mcp.json` into a project root for project-scoped setup.

## Cursor

Copy `cursor.mcp.json` to:

```text
.cursor/mcp.json
```

inside the project.

## VS Code / GitHub Copilot

Copy `vscode.mcp.json` to:

```text
.vscode/mcp.json
```

inside the project.

## Windsurf

Merge `windsurf.mcp_config.json` into:

```text
%USERPROFILE%\.codeium\windsurf\mcp_config.json
```

## Zed

Merge `zed.settings.snippet.json` into your Zed settings.

## Continue

Merge `continue.config.snippet.yaml` into:

```text
%USERPROFILE%\.continue\config.yaml
```
