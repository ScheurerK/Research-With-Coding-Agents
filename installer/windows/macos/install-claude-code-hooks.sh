#!/usr/bin/env bash
# Bash port of installer/windows/Install-ClaudeCodeHooks.ps1.
# Wires (or removes) Markplane's SessionStart/PostToolUse/SubagentStart/Stop/
# SessionEnd hooks in ~/.claude/settings.json (or a custom --settings-path).
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

INSTALL_DIR="$SCRIPT_DIR"
SETTINGS_PATH="$HOME/.claude/settings.json"
MAX_CONTEXT_CHARS=6000
UNINSTALL=0
MARKPLANE_EXE=""
STATE_ROOT="$HOME/Library/Application Support/Markplane/claude-hooks/sessions"

while [ $# -gt 0 ]; do
  case "$1" in
    --install-dir) INSTALL_DIR="$2"; shift 2 ;;
    --settings-path) SETTINGS_PATH="$2"; shift 2 ;;
    --max-context-chars) MAX_CONTEXT_CHARS="$2"; shift 2 ;;
    --markplane-exe) MARKPLANE_EXE="$2"; shift 2 ;;
    --state-root) STATE_ROOT="$2"; shift 2 ;;
    --uninstall) UNINSTALL=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

step() { echo "==> $1"; }

HOOK_SCRIPT="$INSTALL_DIR/invoke-markplane-claude-hook.sh"

read_settings() {
  if [ -f "$SETTINGS_PATH" ] && [ -s "$SETTINGS_PATH" ]; then
    cat "$SETTINGS_PATH"
  else
    printf '{}'
  fi
}

write_settings() {
  local content="$1"
  mkdir -p "$(dirname "$SETTINGS_PATH")"
  local tmp; tmp="$(mktemp "$(dirname "$SETTINGS_PATH")/.tmp.XXXXXX")"
  printf '%s\n' "$content" > "$tmp"
  mv -f "$tmp" "$SETTINGS_PATH"
}

backup_settings_once() {
  [ -f "$SETTINGS_PATH" ] || return 0
  local backup="$SETTINGS_PATH.markplane.bak"
  [ -f "$backup" ] || cp "$SETTINGS_PATH" "$backup"
}

# Builds one hook-event entry as JSON. Args: event matcher markplane_exe
build_hook_entry() {
  local event="$1" matcher="$2" markplane_exe="$3"
  local command
  command="\"$HOOK_SCRIPT\" --event $event --markplane-exe \"$markplane_exe\" --max-context-chars $MAX_CONTEXT_CHARS --state-root \"$STATE_ROOT\""
  if [ -n "$matcher" ]; then
    jq -n --arg matcher "$matcher" --arg command "$command" \
      '{matcher: $matcher, hooks: [{type: "command", command: $command, timeout: 10}]}'
  else
    jq -n --arg command "$command" \
      '{hooks: [{type: "command", command: $command, timeout: 10}]}'
  fi
}

remove_markplane_hook_state() {
  [ -d "$STATE_ROOT" ] && rm -rf "$STATE_ROOT"
}

# Removes any existing hook groups whose command references our hook script,
# for every Markplane-managed event, from a settings JSON blob on stdin.
strip_markplane_hooks() {
  jq --arg hookPath "$HOOK_SCRIPT" '
    def strip(entries):
      [ entries[]?
        | .hooks |= (map(select((.command // "") | contains($hookPath) | not)))
        | select((.hooks | length) > 0)
      ];
    .hooks = (.hooks // {}) |
    .hooks.SessionStart = strip(.hooks.SessionStart // []) |
    .hooks.PostToolUse = strip(.hooks.PostToolUse // []) |
    .hooks.SubagentStart = strip(.hooks.SubagentStart // []) |
    .hooks.Stop = strip(.hooks.Stop // []) |
    .hooks.SessionEnd = strip(.hooks.SessionEnd // []) |
    .hooks = (.hooks | with_entries(select(.value | length > 0)))
  '
}

if [ "$UNINSTALL" -eq 1 ]; then
  settings="$(read_settings | strip_markplane_hooks)"
  write_settings "$settings"
  remove_markplane_hook_state
  echo "Removed Markplane Claude Code hooks."
  exit 0
fi

if [ -z "$MARKPLANE_EXE" ]; then
  if command -v markplane >/dev/null 2>&1; then
    MARKPLANE_EXE="$(command -v markplane)"
  else
    echo "markplane was not found on PATH. Pass --markplane-exe <absolute-path>." >&2
    exit 1
  fi
fi

if [ ! -f "$HOOK_SCRIPT" ]; then
  echo "Markplane Claude hook script was not found: $HOOK_SCRIPT" >&2
  exit 1
fi

backup_settings_once
settings="$(read_settings | strip_markplane_hooks)"

session_start_entry="$(build_hook_entry SessionStart "startup|resume|clear|compact" "$MARKPLANE_EXE")"
post_tool_use_entry="$(build_hook_entry PostToolUse "Edit|Write|Bash|mcp__markplane__.*" "$MARKPLANE_EXE")"
subagent_start_entry="$(build_hook_entry SubagentStart "*" "$MARKPLANE_EXE")"
stop_entry="$(build_hook_entry Stop "" "$MARKPLANE_EXE")"
session_end_entry="$(build_hook_entry SessionEnd "" "$MARKPLANE_EXE")"

settings="$(printf '%s' "$settings" | jq \
  --argjson sessionStart "$session_start_entry" \
  --argjson postToolUse "$post_tool_use_entry" \
  --argjson subagentStart "$subagent_start_entry" \
  --argjson stop "$stop_entry" \
  --argjson sessionEnd "$session_end_entry" \
  '
  .hooks.SessionStart = ((.hooks.SessionStart // []) + [$sessionStart]) |
  .hooks.PostToolUse = ((.hooks.PostToolUse // []) + [$postToolUse]) |
  .hooks.SubagentStart = ((.hooks.SubagentStart // []) + [$subagentStart]) |
  .hooks.Stop = ((.hooks.Stop // []) + [$stop]) |
  .hooks.SessionEnd = ((.hooks.SessionEnd // []) + [$sessionEnd])
  ')"

if printf '%s' "$settings" | jq -e '.disableAllHooks == true' >/dev/null 2>&1; then
  echo "Warning: Claude Code disableAllHooks is set. Markplane hooks were installed but Claude may not run them." >&2
fi
if printf '%s' "$settings" | jq -e '.allowManagedHooksOnly == true' >/dev/null 2>&1; then
  echo "Warning: Claude Code allowManagedHooksOnly is set. User-scoped Markplane hooks may be ignored." >&2
fi

write_settings "$settings"
echo "Installed Markplane Claude Code hooks."
echo "In Claude Code, run /hooks to inspect them."
