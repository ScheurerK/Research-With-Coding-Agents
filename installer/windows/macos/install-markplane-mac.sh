#!/usr/bin/env bash
# Top-level orchestrator for the macOS Claude Code integration: MCP
# registration, hooks, bundled skills, and the VS Code extension.
# Mirrors installer/windows/MarkplaneAgentInstaller.iss's [Run] sequence,
# minus binary installation — this script expects `markplane` to already be
# on PATH (via Homebrew or install.sh; see README.md in this directory).
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

SCOPE="user"
MARKPLANE_EXE=""
MAX_CONTEXT_CHARS=6000
SKIP_VSCODE=0
UNINSTALL=0

usage() {
  cat <<'EOF'
Usage: install-markplane-mac.sh [options]

Installs Markplane's Claude Code integration (MCP registration, hooks,
bundled Superpowers skills, VS Code extension) on macOS/Linux.

Options:
  --scope <user|local|project>   Claude Code MCP registration scope (default: user)
  --markplane-exe <path>         Path to the markplane binary (default: first on PATH)
  --max-context-chars <n>        Max characters injected per hook (default: 6000)
  --skip-vscode                  Do not install the VS Code extension
  --uninstall                    Remove everything this script installed
  -h, --help                     Show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --scope) SCOPE="$2"; shift 2 ;;
    --markplane-exe) MARKPLANE_EXE="$2"; shift 2 ;;
    --max-context-chars) MAX_CONTEXT_CHARS="$2"; shift 2 ;;
    --skip-vscode) SKIP_VSCODE=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "This installer requires jq. Install it with: brew install jq" >&2
  exit 1
fi

if [ "$UNINSTALL" -eq 1 ]; then
  echo "Removing Markplane Claude Code integration..."
  "$SCRIPT_DIR/install-claude-code-hooks.sh" --install-dir "$SCRIPT_DIR" --uninstall
  "$SCRIPT_DIR/install-agent-skills.sh" --skill-source-root "$SCRIPT_DIR/../../../components/superpowers/skills" --uninstall
  if [ "$SKIP_VSCODE" -eq 0 ]; then
    "$SCRIPT_DIR/install-vscode-extension.sh" --uninstall
  fi
  echo ""
  echo "Markplane Claude Code integration removed."
  echo "The markplane binary and Claude Code MCP registration are not removed automatically."
  echo "Run 'claude mcp remove markplane' if you also want to drop the MCP registration."
  exit 0
fi

if [ -z "$MARKPLANE_EXE" ]; then
  if command -v markplane >/dev/null 2>&1; then
    MARKPLANE_EXE="$(command -v markplane)"
  else
    cat >&2 <<'EOF'
markplane was not found on PATH.
Install it first, e.g.:
  brew install zerowand01/markplane/markplane
  # or: curl -fsSL https://raw.githubusercontent.com/zerowand01/markplane/master/install.sh | sh
Then re-run this installer, or pass --markplane-exe <absolute-path>.
EOF
    exit 1
  fi
fi

echo "==> Using markplane binary: $MARKPLANE_EXE"

"$SCRIPT_DIR/configure-claude-code.sh" --scope "$SCOPE" --markplane-exe "$MARKPLANE_EXE"
"$SCRIPT_DIR/install-agent-skills.sh" --skill-source-root "$SCRIPT_DIR/../../../components/superpowers/skills"
"$SCRIPT_DIR/install-claude-code-hooks.sh" --install-dir "$SCRIPT_DIR" --markplane-exe "$MARKPLANE_EXE" --max-context-chars "$MAX_CONTEXT_CHARS"
if [ "$SKIP_VSCODE" -eq 0 ]; then
  "$SCRIPT_DIR/install-vscode-extension.sh" --extension-source "$SCRIPT_DIR/../../../packages/vscode-extension/source"
fi

echo ""
echo "Markplane Claude Code integration installed."
echo "Restart Claude Code, then run /mcp and /hooks to verify."
