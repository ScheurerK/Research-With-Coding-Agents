#!/usr/bin/env bash
# Bash port of installer/windows/Install-VSCodeExtension.ps1.
# Installs the Markplane UI through the official VS Code CLI and a VSIX.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd -P)"

EXTENSION_SOURCE=""
VSIX_PATH=""
EXTENSION_ID="local.markplane-vscode"
CODE_CLI=""
UNINSTALL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --extension-source) EXTENSION_SOURCE="$2"; shift 2 ;;
    --vsix-path) VSIX_PATH="$2"; shift 2 ;;
    --extension-id) EXTENSION_ID="$2"; shift 2 ;;
    --code-cli) CODE_CLI="$2"; shift 2 ;;
    --uninstall) UNINSTALL=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

step() { echo "==> $1"; }

if [ -z "$CODE_CLI" ]; then
  if command -v code >/dev/null 2>&1; then
    CODE_CLI="$(command -v code)"
  else
    echo "VS Code CLI not found. Install the 'code' command, then rerun this script." >&2
    exit 1
  fi
fi

if [ "$UNINSTALL" -eq 1 ]; then
  "$CODE_CLI" --uninstall-extension "$EXTENSION_ID"
  exit $?
fi

if [ -z "$EXTENSION_SOURCE" ]; then
  EXTENSION_SOURCE="$REPO_ROOT/packages/vscode-extension/source"
fi
if [ ! -d "$EXTENSION_SOURCE" ]; then
  echo "VS Code extension source folder not found: $EXTENSION_SOURCE" >&2
  exit 1
fi

if [ -z "$VSIX_PATH" ]; then
  VSIX_PATH="$SCRIPT_DIR/../vscode-extension/markplane-vscode-0.1.2.vsix"
fi
mkdir -p "$(dirname "$VSIX_PATH")"
rm -f "$VSIX_PATH"

if command -v vsce >/dev/null 2>&1; then
  (cd "$EXTENSION_SOURCE" && vsce package --out "$VSIX_PATH") || exit $?
elif command -v npx >/dev/null 2>&1; then
  (cd "$EXTENSION_SOURCE" && npx --yes @vscode/vsce package --out "$VSIX_PATH") || exit $?
else
  echo "Neither vsce nor npx was found; cannot package the VSIX." >&2
  exit 1
fi

if [ ! -f "$VSIX_PATH" ]; then
  echo "VSIX was not created: $VSIX_PATH" >&2
  exit 1
fi

"$CODE_CLI" --install-extension "$VSIX_PATH" --force || exit $?
"$CODE_CLI" --list-extensions --show-versions | grep -E "^${EXTENSION_ID}(@|$)" >/dev/null || {
  echo "Extension registration was not found after installation: $EXTENSION_ID" >&2
  exit 1
}
step "Installed Markplane VS Code extension from $VSIX_PATH"
echo "Run Developer: Reload Window in VS Code to activate it immediately."