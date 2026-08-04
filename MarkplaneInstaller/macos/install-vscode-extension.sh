#!/usr/bin/env bash
# Bash port of MarkplaneInstaller/Install-VSCodeExtension.ps1.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

EXTENSION_SOURCE=""
EXTENSION_ID="local.markplane-vscode-0.1.2"
UNINSTALL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --extension-source) EXTENSION_SOURCE="$2"; shift 2 ;;
    --extension-id) EXTENSION_ID="$2"; shift 2 ;;
    --uninstall) UNINSTALL=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

step() { echo "==> $1"; }

EXTENSIONS_ROOT="$HOME/.vscode/extensions"
TARGET="$EXTENSIONS_ROOT/$EXTENSION_ID"

if [ "$UNINSTALL" -eq 1 ]; then
  if [ -d "$TARGET" ]; then
    root_resolved="$(cd "$EXTENSIONS_ROOT" && pwd -P)"
    target_resolved="$(cd "$TARGET" && pwd -P)"
    case "$target_resolved" in
      "$root_resolved"/*|"$root_resolved")
        rm -rf "$target_resolved"
        step "Removed VS Code extension from $target_resolved"
        ;;
      *)
        echo "Refusing to remove extension outside VS Code extensions folder: $target_resolved" >&2
        exit 1
        ;;
    esac
  else
    step "VS Code extension was not installed"
  fi
  exit 0
fi

if [ -z "$EXTENSION_SOURCE" ]; then
  EXTENSION_SOURCE="$SCRIPT_DIR/../vscode-extension"
fi

if [ ! -d "$EXTENSION_SOURCE" ]; then
  echo "VS Code extension source folder not found: $EXTENSION_SOURCE" >&2
  exit 1
fi

mkdir -p "$EXTENSIONS_ROOT"
rm -rf "$TARGET"
cp -R "$EXTENSION_SOURCE" "$TARGET"
step "Installed VS Code extension to $TARGET"
echo "Reload VS Code to activate the Markplane activity-bar view."
