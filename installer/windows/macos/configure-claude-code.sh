#!/usr/bin/env bash
# Bash port of installer/windows/Configure-ClaudeCode.ps1.
# Registers the Markplane MCP server with Claude Code via the `claude` CLI,
# and removes any legacy ~/.claude/settings.json mcpServers.markplane entry.
set -u

SCOPE="user"
MARKPLANE_EXE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --scope) SCOPE="$2"; shift 2 ;;
    --markplane-exe) MARKPLANE_EXE="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

case "$SCOPE" in
  user|local|project) ;;
  *) echo "Invalid --scope '$SCOPE'. Expected user, local, or project." >&2; exit 1 ;;
esac

step() { echo "==> $1"; }

resolve_markplane_exe() {
  if [ -n "$MARKPLANE_EXE" ]; then
    if [ ! -f "$MARKPLANE_EXE" ]; then
      echo "markplane not found at $MARKPLANE_EXE" >&2
      return 1
    fi
    printf '%s\n' "$(cd "$(dirname "$MARKPLANE_EXE")" && pwd -P)/$(basename "$MARKPLANE_EXE")"
    return 0
  fi
  if command -v markplane >/dev/null 2>&1; then
    command -v markplane
    return 0
  fi
  echo "markplane was not found on PATH. Pass --markplane-exe <absolute-path>." >&2
  return 1
}

remove_legacy_settings_server() {
  local settings_path="$HOME/.claude/settings.json"
  [ -f "$settings_path" ] || return 0
  if ! jq -e '.mcpServers.markplane' "$settings_path" >/dev/null 2>&1; then
    return 0
  fi
  local backup="$settings_path.markplane.bak"
  [ -f "$backup" ] || cp "$settings_path" "$backup"
  local tmp; tmp="$(mktemp)"
  jq 'del(.mcpServers.markplane)' "$settings_path" > "$tmp"
  mv -f "$tmp" "$settings_path"
  step "Removed legacy mcpServers.markplane from $settings_path"
}

if ! command -v claude >/dev/null 2>&1; then
  echo "Warning: Claude Code CLI ('claude') was not found in PATH. Skipping MCP registration; Claude settings are left unchanged." >&2
  exit 0
fi

resolved_markplane="$(resolve_markplane_exe)" || exit 1

step "Claude Code CLI: $(claude --version 2>&1)"

if claude mcp get markplane >/dev/null 2>&1; then
  step "Removing existing Claude Code MCP registration for markplane"
  if ! claude mcp remove markplane; then
    echo "Claude Code MCP removal failed." >&2
    exit 1
  fi
fi

step "Registering Markplane MCP with Claude Code scope '$SCOPE'"
if ! claude mcp add --transport stdio --scope "$SCOPE" markplane -- "$resolved_markplane" mcp; then
  echo "Claude Code MCP registration failed." >&2
  exit 1
fi

remove_legacy_settings_server

echo "Claude Code MCP server 'markplane' registered with scope '$SCOPE'."
echo "In Claude Code, run /mcp to verify the connection."
