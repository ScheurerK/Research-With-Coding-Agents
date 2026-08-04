#!/usr/bin/env bash
# Entry point Claude Code invokes for each hook event on macOS/Linux.
# Bash port of MarkplaneInstaller/hooks/Invoke-MarkplaneClaudeHook.ps1.
#
# Usage:
#   invoke-markplane-claude-hook.sh --event SessionStart --markplane-exe /path/to/markplane \
#     [--max-context-chars 6000] [--state-root /path/to/state]
#
# Reads the hook event JSON from stdin, prints the hook's JSON response (if
# any) to stdout. Fails open: any internal error is swallowed and reported
# only via stderr, so a hook bug never blocks the user's session.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

EVENT=""
MARKPLANE_EXE=""
MAX_CONTEXT_CHARS=6000
STATE_ROOT="$HOME/Library/Application Support/Markplane/claude-hooks/sessions"

while [ $# -gt 0 ]; do
  case "$1" in
    --event) EVENT="${2:-}"; shift 2 ;;
    --markplane-exe) MARKPLANE_EXE="${2:-}"; shift 2 ;;
    --max-context-chars) MAX_CONTEXT_CHARS="${2:-}"; shift 2 ;;
    --state-root) STATE_ROOT="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done

main() {
  set -e

  case "$EVENT" in
    SessionStart|PostToolUse|SubagentStart|Stop|SessionEnd) ;;
    *) echo "invalid --event '$EVENT'" >&2; return 1 ;;
  esac
  [ -n "$MARKPLANE_EXE" ] || { echo "--markplane-exe is required" >&2; return 1; }

  # shellcheck source=lib/markplane-claude-hooks.sh
  source "$SCRIPT_DIR/lib/markplane-claude-hooks.sh"

  local input_json
  input_json="$(cat)"
  if [ -z "$(printf '%s' "$input_json" | tr -d '[:space:]')" ]; then
    return 0
  fi
  if ! printf '%s' "$input_json" | jq -e . >/dev/null 2>&1; then
    echo "invalid JSON on stdin" >&2
    return 1
  fi

  local result
  result="$(mp_handle_event "$EVENT" "$input_json" "$MARKPLANE_EXE" "$MAX_CONTEXT_CHARS" "$STATE_ROOT")"
  if [ -n "$result" ]; then
    printf '%s' "$result" | jq -c .
  fi
  return 0
}

err_file="$(mktemp)"
if ! main 2>"$err_file"; then
  echo "Markplane Claude hook failed open: $(cat "$err_file")" >&2
fi
rm -f "$err_file"
exit 0
