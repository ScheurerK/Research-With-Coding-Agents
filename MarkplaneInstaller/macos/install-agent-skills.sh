#!/usr/bin/env bash
# Bash port of MarkplaneInstaller/Install-MarkplaneAgentSkills.ps1, scoped to
# Claude Code only (no Codex/~/.codex paths — see macos/README.md).
# Installs Markplane's bundled Superpowers-style skills into ~/.claude/skills
# and manages a marked "bundled agent skill" block in ~/.claude/CLAUDE.md.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

SKILL_SOURCE_ROOT=""
HINT_PATH=""
SKIP_HINTS=0
UNINSTALL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --skill-source-root) SKILL_SOURCE_ROOT="$2"; shift 2 ;;
    --hint-path) HINT_PATH="$2"; shift 2 ;;
    --skip-hints) SKIP_HINTS=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

step() { echo "==> $1"; }

resolve_skill_source_root() {
  if [ -n "$SKILL_SOURCE_ROOT" ]; then
    [ -d "$SKILL_SOURCE_ROOT" ] || { echo "Skill source folder not found: $SKILL_SOURCE_ROOT" >&2; return 1; }
    printf '%s\n' "$(cd "$SKILL_SOURCE_ROOT" && pwd -P)"
    return 0
  fi
  local candidate="$SCRIPT_DIR/../skills"
  if [ -d "$candidate" ]; then
    printf '%s\n' "$(cd "$candidate" && pwd -P)"
    return 0
  fi
  echo "Skill source folder not found. Pass --skill-source-root <path>." >&2
  return 1
}

resolve_hint_path() {
  if [ -n "$HINT_PATH" ]; then
    [ -f "$HINT_PATH" ] || { echo "Agent hint file not found: $HINT_PATH" >&2; return 1; }
    printf '%s\n' "$HINT_PATH"
    return 0
  fi
  local candidate="$SCRIPT_DIR/../research-checkpoint-agents-extension.txt"
  if [ -f "$candidate" ]; then
    printf '%s\n' "$candidate"
    return 0
  fi
  echo "Agent hint file not found. Pass --hint-path <path>." >&2
  return 1
}

get_bundled_skill_names() {
  local source_root="$1" d
  [ -d "$source_root" ] || return 0
  for d in "$source_root"/*/; do
    [ -e "$d" ] || continue
    [ -f "${d}SKILL.md" ] && basename "$d"
  done | sort
}

install_skill_directory() {
  local source_root="$1" destination_root="$2" skill_name="$3"
  local source="$source_root/$skill_name"
  [ -d "$source" ] || { echo "Skill source not found: $source" >&2; return 1; }
  [ -f "$source/SKILL.md" ] || { echo "Skill source does not contain SKILL.md: $source" >&2; return 1; }

  mkdir -p "$destination_root"
  local destination="$destination_root/$skill_name"
  rm -rf "$destination"
  cp -R "$source" "$destination"
  step "Installed $skill_name skill to $destination"
}

remove_skill_directory() {
  local destination_root="$1" skill_name="$2"
  local destination="$destination_root/$skill_name"
  if [ -d "$destination" ]; then
    rm -rf "$destination"
    step "Removed $skill_name skill from $destination"
  else
    step "$skill_name skill was not installed in $destination_root"
  fi
}

update_managed_block() {
  local target_path="$1" content_file="$2" start_marker="$3" end_marker="$4" description="$5"
  mkdir -p "$(dirname "$target_path")"
  [ -f "$target_path" ] || touch "$target_path"
  local content; content="$(cat "$content_file")"
  if [ -z "$(printf '%s' "$content" | tr -d '[:space:]')" ]; then
    echo "Managed content file is empty: $content_file" >&2
    return 1
  fi
  local tmp; tmp="$(mktemp)"
  awk -v start="$start_marker" -v end="$end_marker" '
    $0 == start { in_block=1; next }
    $0 == end { in_block=0; next }
    !in_block { print }
  ' "$target_path" > "$tmp"
  {
    cat "$tmp"
    echo
    printf '%s\n' "$start_marker"
    printf '%s\n' "$content"
    printf '%s\n' "$end_marker"
  } > "$target_path.new"
  mv -f "$target_path.new" "$target_path"
  rm -f "$tmp"
  step "Installed $description instructions in $target_path"
}

remove_managed_block() {
  local target_path="$1" start_marker="$2" end_marker="$3" description="$4"
  if [ ! -f "$target_path" ]; then
    step "$description instructions not found; skipping cleanup"
    return 0
  fi
  local tmp; tmp="$(mktemp)"
  awk -v start="$start_marker" -v end="$end_marker" '
    $0 == start { in_block=1; next }
    $0 == end { in_block=0; next }
    !in_block { print }
  ' "$target_path" > "$tmp"
  mv -f "$tmp" "$target_path"
  step "Removed $description instructions from $target_path"
}

disable_superpowers_telemetry() {
  local telemetry_marker_start="# BEGIN MARKPLANE: disable Superpowers telemetry"
  local telemetry_marker_end="# END MARKPLANE: disable Superpowers telemetry"
  local rc
  for rc in "$HOME/.zshrc" "$HOME/.bash_profile"; do
    [ -f "$rc" ] || : > "$rc"
    local tmp; tmp="$(mktemp)"
    awk -v start="$telemetry_marker_start" -v end="$telemetry_marker_end" '
      $0 == start { in_block=1; next }
      $0 == end { in_block=0; next }
      !in_block { print }
    ' "$rc" > "$tmp"
    {
      cat "$tmp"
      echo
      echo "$telemetry_marker_start"
      echo 'export SUPERPOWERS_DISABLE_TELEMETRY=1'
      echo "$telemetry_marker_end"
    } > "$rc.new"
    mv -f "$rc.new" "$rc"
    rm -f "$tmp"
  done
  export SUPERPOWERS_DISABLE_TELEMETRY=1
  step "Disabled Superpowers optional telemetry for the current user (~/.zshrc, ~/.bash_profile)"
}

CLAUDE_SKILLS_ROOT="$HOME/.claude/skills"
CLAUDE_AGENTS_PATH="$HOME/.claude/CLAUDE.md"
CLAUDE_START="<!-- BEGIN MARKPLANE RESEARCH CHECKPOINT SKILL -->"
CLAUDE_END="<!-- END MARKPLANE RESEARCH CHECKPOINT SKILL -->"

FALLBACK_SKILL_NAMES="brainstorming dispatching-parallel-agents executing-plans finishing-a-development-branch receiving-code-review requesting-code-review research-repo-governance research-checkpoint-commits subagent-driven-development systematic-debugging test-driven-development using-git-worktrees using-superpowers verification-before-completion writing-plans writing-skills"

if [ "$UNINSTALL" -eq 1 ]; then
  step "Removing Markplane bundled agent skills"
  skill_names=""
  if source_root_for_removal="$(resolve_skill_source_root 2>/dev/null)"; then
    skill_names="$(get_bundled_skill_names "$source_root_for_removal")"
  fi
  [ -z "$skill_names" ] && skill_names="$FALLBACK_SKILL_NAMES"

  for skill_name in $skill_names; do
    remove_skill_directory "$CLAUDE_SKILLS_ROOT" "$skill_name"
  done

  if [ "$SKIP_HINTS" -eq 0 ]; then
    remove_managed_block "$CLAUDE_AGENTS_PATH" "$CLAUDE_START" "$CLAUDE_END" "Claude Code bundled agent skill"
  fi

  echo ""
  echo "Bundled agent skill integration removed."
  exit 0
fi

source_root="$(resolve_skill_source_root)" || exit 1
disable_superpowers_telemetry
skill_names="$(get_bundled_skill_names "$source_root")"
if [ -z "$skill_names" ]; then
  echo "No bundled skills with SKILL.md found in $source_root" >&2
  exit 1
fi

for skill_name in $skill_names; do
  install_skill_directory "$source_root" "$CLAUDE_SKILLS_ROOT" "$skill_name" || exit 1
done

if [ "$SKIP_HINTS" -eq 0 ]; then
  hint_file="$(resolve_hint_path)" || exit 1
  update_managed_block "$CLAUDE_AGENTS_PATH" "$hint_file" "$CLAUDE_START" "$CLAUDE_END" "Claude Code bundled agent skill"
fi

echo ""
echo "Bundled agent skill integration installed. Restart Claude Code sessions to load the skills."
