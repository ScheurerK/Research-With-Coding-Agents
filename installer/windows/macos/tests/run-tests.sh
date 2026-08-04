#!/usr/bin/env bash
# Test suite for the macOS bash port of the Markplane Claude Code hooks.
# Requires: bash, jq, shasum, awk (all standard on macOS; jq via `brew install jq`).
#
# Usage: ./run-tests.sh
set -u

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
MACOS_DIR="$(cd "$TEST_DIR/.." && pwd -P)"
source "$MACOS_DIR/lib/markplane-claude-hooks.sh"

PASS=0
FAIL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $desc"
    echo "  expected: $expected"
    echo "  actual:   $actual"
  fi
}

assert_contains() {
  local desc="$1" haystack="$2" needle="$3"
  case "$haystack" in
    *"$needle"*) PASS=$((PASS + 1)) ;;
    *)
      FAIL=$((FAIL + 1))
      echo "FAIL: $desc"
      echo "  expected to contain: $needle"
      echo "  actual: $haystack"
      ;;
  esac
}

assert_not_contains() {
  local desc="$1" haystack="$2" needle="$3"
  case "$haystack" in
    *"$needle"*)
      FAIL=$((FAIL + 1))
      echo "FAIL: $desc"
      echo "  expected NOT to contain: $needle"
      echo "  actual: $haystack"
      ;;
    *) PASS=$((PASS + 1)) ;;
  esac
}

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

FAKE_EXE="$WORK/fake-markplane.sh"
cat > "$FAKE_EXE" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  sync)
    echo "sync stdout"
    exit "${FAKE_SYNC_EXIT:-0}"
    ;;
  check)
    if [ "${FAKE_CHECK_EXIT:-0}" -ne 0 ]; then
      echo "check failed: broken reference" >&2
    else
      echo "check stdout ok"
    fi
    exit "${FAKE_CHECK_EXIT:-0}"
    ;;
  *)
    echo "unknown command $1" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$FAKE_EXE"

PROJECT="$WORK/project"
STATE="$WORK/state"
mkdir -p "$PROJECT/.markplane/.context" "$PROJECT/src/nested" "$STATE"
echo "# Project A
## Key Metrics
- Backlog: 0 items" > "$PROJECT/.markplane/.context/summary.md"
echo "# Resume: Project A
## Active Work
- TASK-x: In progress item" > "$PROJECT/.markplane/.context/resume.md"

# --- Project root discovery ---
assert_eq "finds project root from nested dir" "$PROJECT" "$(mp_find_project_root "$PROJECT/src/nested")"

# --- Hashing ---
h1="$(mp_stable_hash "/some/Project/Root")"
h2="$(mp_stable_hash "/some/project/root")"
assert_eq "hash is case-insensitive (matches PowerShell ToLowerInvariant)" "$h1" "$h2"
assert_eq "sha256 hex length is 64" "64" "${#h1}"

# --- Context truncation ---
long_text="$(printf 'x%.0s' $(seq 1 100))"
result="$(mp_limit_context "$long_text" 80)"
assert_eq "truncates to exactly max_chars" "80" "${#result}"
assert_contains "truncation suffix present" "$result" "truncated to 80 characters"
below_floor="$(mp_limit_context "$long_text" 50)"
assert_eq "below 64-char floor returns text unchanged" "100" "${#below_floor}"

# --- Session state lifecycle ---
mp_set_hook_state "sess1" "$PROJECT" "$STATE" true false
state_json="$(mp_get_hook_state "sess1" "$PROJECT" "$STATE")"
assert_eq "set dirty=true persists" "true" "$(printf '%s' "$state_json" | jq -r '.dirty')"
mp_remove_hook_state "sess1" "$STATE"
state_json="$(mp_get_hook_state "sess1" "$PROJECT" "$STATE")"
assert_eq "removed state resets to dirty=false" "false" "$(printf '%s' "$state_json" | jq -r '.dirty')"

# --- Project lock ---
mp_acquire_lock "$PROJECT" 5
lock_dir="$MP_LOCK_DIR"
assert_eq "lock directory created" "0" "$([ -d "$lock_dir" ]; echo $?)"
mp_release_lock
assert_eq "lock directory removed after release" "1" "$([ -d "$lock_dir" ]; echo $?)"

# --- PostToolUse relevance (mirrors Pester "Project and event routing" cases) ---
assert_eq "normal edit is not relevant" "1" "$(mp_relevant_post_tool_use '{"tool_name":"Edit","tool_input":{"file_path":"/repo/src/app.js"}}' "/repo"; echo $?)"
assert_eq "markplane item write is relevant" "0" "$(mp_relevant_post_tool_use "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"/repo/.markplane/backlog/items/TASK-a.md\"}}" "/repo"; echo $?)"
assert_eq "mcp read tool is not relevant" "1" "$(mp_relevant_post_tool_use '{"tool_name":"mcp__markplane__markplane_summary","tool_input":{}}' "/repo"; echo $?)"
assert_eq "mcp write tool is relevant" "0" "$(mp_relevant_post_tool_use '{"tool_name":"mcp__markplane__markplane_update","tool_input":{}}' "/repo"; echo $?)"
assert_eq "superpowers plan edit is relevant" "0" "$(mp_relevant_post_tool_use "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"/repo/docs/superpowers/plans/feature.md\"}}" "/repo"; echo $?)"
assert_eq "bash markplane sync command is relevant" "0" "$(mp_relevant_post_tool_use '{"tool_name":"Bash","tool_input":{"command":"markplane sync"}}' "/repo"; echo $?)"
assert_eq "bash unrelated command is not relevant" "1" "$(mp_relevant_post_tool_use '{"tool_name":"Bash","tool_input":{"command":"npm test"}}' "/repo"; echo $?)"
assert_eq "apply_patch touching markplane is relevant" "0" "$(mp_relevant_post_tool_use '{"tool_name":"apply_patch","tool_input":{"patch":"*** Update File: docs/superpowers/plans/feature.md\n+details"}}' "/repo"; echo $?)"

# --- Quality gate: placeholder task (mirrors Pester quality-gate test 1) ---
QPROJECT="$WORK/qproject1"
mkdir -p "$QPROJECT/.markplane/backlog/items"
cat > "$QPROJECT/.markplane/backlog/items/TASK-test1.md" <<'EOF'
---
id: TASK-test1
title: Placeholder task
status: planned
priority: high
type: feature
effort: medium
---
# Placeholder task

## Description

[What needs to be done]

## Acceptance Criteria

- [ ] Criterion 1
EOF
mp_test_project_quality "$QPROJECT"
assert_eq "placeholder task fails quality check" "1" "$MP_QUALITY_EXIT"
assert_contains "quality message names the task" "$MP_QUALITY_MESSAGE" "TASK-test1"
assert_contains "quality message flags placeholder" "$MP_QUALITY_MESSAGE" "placeholder"

# --- Quality gate: unlinked Superpowers plan (mirrors Pester quality-gate test 2) ---
QPROJECT2="$WORK/qproject2"
mkdir -p "$QPROJECT2/.markplane/plans/items" "$QPROJECT2/docs/superpowers/plans"
echo "# Feature Plan" > "$QPROJECT2/docs/superpowers/plans/2026-07-22-feature.md"
mp_test_project_quality "$QPROJECT2"
assert_eq "unlinked superpowers plan fails quality check" "1" "$MP_QUALITY_EXIT"
assert_contains "quality message names the unlinked plan" "$MP_QUALITY_MESSAGE" "docs/superpowers/plans/2026-07-22-feature.md"
cat > "$QPROJECT2/.markplane/plans/items/PLAN-x.md" <<'EOF'
---
id: PLAN-x
status: draft
---
References docs/superpowers/plans/2026-07-22-feature.md here.
EOF
mp_test_project_quality "$QPROJECT2"
assert_eq "linked superpowers plan passes quality check" "0" "$MP_QUALITY_EXIT"

# --- Quality gate: island plan (implements empty) ---
QPROJECT3="$WORK/qproject3"
mkdir -p "$QPROJECT3/.markplane/plans/items"
cat > "$QPROJECT3/.markplane/plans/items/PLAN-y.md" <<'EOF'
---
id: PLAN-y
status: approved
implements: []
---
# Plan Y

## Ground Truth
- some/file.rs:L1-10 - concrete source reference

## Approach
Concrete approach text describing the design.

## Testing Strategy
Concrete testing text describing verification steps.
EOF
mp_test_project_quality "$QPROJECT3"
assert_eq "plan without implements fails quality check" "1" "$MP_QUALITY_EXIT"
assert_contains "quality message flags orphaned plan" "$MP_QUALITY_MESSAGE" "does not implement any task"

cat > "$QPROJECT3/.markplane/plans/items/PLAN-y.md" <<'EOF'
---
id: PLAN-y
status: approved
implements: [TASK-z]
---
# Plan Y

## Ground Truth
- some/file.rs:L1-10 - concrete source reference

## Approach
Concrete approach text describing the design.

## Testing Strategy
Concrete testing text describing verification steps.
EOF
mp_test_project_quality "$QPROJECT3"
assert_eq "plan with implements passes quality check" "0" "$MP_QUALITY_EXIT"

# --- Quality gate: Epic graph connectivity (hard block + soft warning) ---
QPROJECT4="$WORK/qproject4"
mkdir -p "$QPROJECT4/.markplane/backlog/items" "$QPROJECT4/roadmap/items"
cat > "$QPROJECT4/roadmap/items/EPIC-orphan.md" <<'EOF'
---
id: EPIC-orphan
title: Orphan Epic
status: later
---
# Orphan Epic
EOF
mp_test_project_quality "$QPROJECT4"
assert_eq "orphan epic fails quality check" "1" "$MP_QUALITY_EXIT"
assert_contains "quality message flags orphan epic" "$MP_QUALITY_MESSAGE" "epic has no tasks linked"

cat > "$QPROJECT4/.markplane/backlog/items/TASK-linked.md" <<'EOF'
---
id: TASK-linked
title: Linked task
status: done
epic: EPIC-orphan
---
# Linked task
EOF
mp_test_project_quality "$QPROJECT4"
assert_eq "epic with linked task passes quality check" "0" "$MP_QUALITY_EXIT"

cat > "$QPROJECT4/.markplane/backlog/items/TASK-unlinked.md" <<'EOF'
---
id: TASK-unlinked
title: Unlinked task
status: done
epic: null
---
# Unlinked task
EOF
mp_test_project_quality "$QPROJECT4"
assert_eq "unlinked task alongside satisfied epic still passes (soft warning only)" "0" "$MP_QUALITY_EXIT"
assert_contains "quality message warns about unlinked task" "$MP_QUALITY_MESSAGE" "not linked to any Epic"

# --- Full dispatcher: SessionStart startup vs compact ---
out_startup="$(mp_handle_event "SessionStart" '{"session_id":"s1","cwd":"'"$PROJECT"'","source":"startup"}' "$FAKE_EXE" 6000 "$STATE")"
assert_contains "startup SessionStart includes full summary" "$out_startup" "Key Metrics"
out_compact="$(mp_handle_event "SessionStart" '{"session_id":"s1b","cwd":"'"$PROJECT"'","source":"compact"}' "$FAKE_EXE" 6000 "$STATE")"
assert_contains "compact SessionStart includes resume view" "$out_compact" "TASK-x"
assert_not_contains "compact SessionStart omits full summary metrics" "$out_compact" "Key Metrics"

# --- Full dispatcher: PostToolUse marks dirty only when relevant ---
out="$(mp_handle_event "PostToolUse" '{"session_id":"s2","cwd":"'"$PROJECT"'","tool_name":"Bash","tool_input":{"command":"npm test"}}' "$FAKE_EXE" 6000 "$STATE")"
assert_eq "irrelevant PostToolUse produces no output" "" "$out"
mp_handle_event "PostToolUse" '{"session_id":"s2","cwd":"'"$PROJECT"'","tool_name":"mcp__markplane__markplane_add","tool_input":{}}' "$FAKE_EXE" 6000 "$STATE" >/dev/null
state_json="$(mp_get_hook_state "s2" "$PROJECT" "$STATE")"
assert_eq "relevant PostToolUse marks state dirty" "true" "$(printf '%s' "$state_json" | jq -r '.dirty')"

# --- Full dispatcher: Stop retry ladder ---
export FAKE_CHECK_EXIT=1
resolved_root="$(mp_find_project_root "$PROJECT")"
mp_set_hook_state "s3" "$resolved_root" "$STATE" true false
stop_input='{"session_id":"s3","cwd":"'"$PROJECT"'","background_tasks":[]}'
out1="$(mp_handle_event "Stop" "$stop_input" "$FAKE_EXE" 6000 "$STATE")"
assert_contains "first Stop failure asks for one correction" "$out1" "Fix the issue once"
state_json="$(mp_get_hook_state "s3" "$resolved_root" "$STATE")"
assert_eq "first Stop failure sets retryUsed=true" "true" "$(printf '%s' "$state_json" | jq -r '.retryUsed')"
out2="$(mp_handle_event "Stop" "$stop_input" "$FAKE_EXE" 6000 "$STATE")"
assert_contains "second Stop failure gives systemMessage" "$out2" "systemMessage"
assert_contains "second Stop failure mentions one correction attempt" "$out2" "after one correction attempt"
state_json="$(mp_get_hook_state "s3" "$resolved_root" "$STATE")"
assert_eq "second Stop failure clears dirty (stops looping)" "false" "$(printf '%s' "$state_json" | jq -r '.dirty')"
unset FAKE_CHECK_EXIT

mp_set_hook_state "s5" "$resolved_root" "$STATE" true false
out5="$(mp_handle_event "Stop" '{"session_id":"s5","cwd":"'"$PROJECT"'","background_tasks":[]}' "$FAKE_EXE" 6000 "$STATE")"
assert_eq "Stop with passing check produces no output" "" "$out5"
state_json="$(mp_get_hook_state "s5" "$resolved_root" "$STATE")"
assert_eq "Stop with passing check clears dirty" "false" "$(printf '%s' "$state_json" | jq -r '.dirty')"

# --- SessionEnd cleanup ---
state_path="$(mp_session_state_path "s5" "$resolved_root" "$STATE")"
mp_handle_event "SessionEnd" '{"session_id":"s5"}' "$FAKE_EXE" 6000 "$STATE" >/dev/null
assert_eq "SessionEnd removes the state file" "1" "$([ -f "$state_path" ]; echo $?)"

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
