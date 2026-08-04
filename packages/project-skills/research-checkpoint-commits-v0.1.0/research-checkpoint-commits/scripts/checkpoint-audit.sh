#!/usr/bin/env bash
set -euo pipefail

task_id="${1:-}"

if [[ ! "$task_id" =~ ^TASK-[A-Za-z0-9]{5}$ ]]; then
  echo "Usage: $0 TASK-xxxxx" >&2
  exit 64
fi

git rev-parse --is-inside-work-tree >/dev/null
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

if ! command -v markplane >/dev/null 2>&1; then
  echo "markplane is not available on PATH." >&2
  exit 69
fi

echo "== Markplane item =="
markplane show "$task_id" >/dev/null
echo "Found $task_id"

echo
echo "== Markplane validation =="
markplane check

echo
echo "== Staged diff checks =="
if git diff --cached --quiet; then
  echo "No staged changes." >&2
  exit 65
fi

git diff --cached --check
git diff --cached --stat

staged_files="$(git diff --cached --name-only)"
task_pattern="^\.markplane/backlog/(items|archive)/${task_id}\.md$"

if ! printf '%s\n' "$staged_files" | grep -Eq "$task_pattern"; then
  echo >&2
  echo "The staged diff does not contain the owning Markplane task file:" >&2
  echo "  .markplane/backlog/items/${task_id}.md" >&2
  echo "or its archived path." >&2
  exit 66
fi

echo
echo "== Staged files =="
printf '%s\n' "$staged_files"

echo
echo "Audit passed. Review the full staged diff before committing:"
echo "  git diff --cached"
