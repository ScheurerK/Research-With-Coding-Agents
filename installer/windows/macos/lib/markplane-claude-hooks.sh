#!/usr/bin/env bash
# Bash port of MarkplaneClaudeHooks.psm1 for macOS/Linux Claude Code hooks.
# Sourced by invoke-markplane-claude-hook.sh. Requires: bash, jq, shasum, awk.

MP_MUTATING_MCP_TOOLS="markplane_add markplane_archive markplane_link markplane_move markplane_plan markplane_promote markplane_sync markplane_unarchive markplane_update"

mp_find_project_root() {
  local start="$1" dir
  [ -z "$start" ] && return 1
  dir="$start"
  if [ -f "$dir" ]; then
    dir="$(dirname "$dir")"
  fi
  [ -d "$dir" ] || return 1
  dir="$(cd "$dir" 2>/dev/null && pwd -P)" || return 1
  while :; do
    if [ -d "$dir/.markplane" ]; then
      printf '%s\n' "$dir"
      return 0
    fi
    local parent
    parent="$(dirname "$dir")"
    [ "$parent" = "$dir" ] && return 1
    dir="$parent"
  done
}

mp_stable_hash() {
  local text="$1"
  printf '%s' "$text" | tr '[:upper:]' '[:lower:]' | shasum -a 256 | awk '{print $1}'
}

mp_trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

mp_limit_context() {
  local text="$1" max_chars="${2:-6000}"
  local len=${#text}
  if [ "$max_chars" -lt 64 ] || [ "$len" -le "$max_chars" ]; then
    printf '%s' "$text"
    return 0
  fi
  local suffix
  suffix=$'\n\n[Markplane context truncated to '"$max_chars"' characters.]'
  local suffix_len=${#suffix}
  local take=$((max_chars - suffix_len))
  [ "$take" -lt 0 ] && take=0
  [ "$take" -gt "$len" ] && take="$len"
  printf '%s%s' "${text:0:take}" "$suffix"
}

# --- Session state (SessionStart/PostToolUse/Stop dirty tracking) ---

mp_session_state_path() {
  local session_id="$1" project_root="$2" state_root="$3" safe_session hash
  safe_session=$(printf '%s' "$session_id" | sed -E 's/[^A-Za-z0-9_.-]/_/g')
  [ -z "$safe_session" ] && safe_session="unknown"
  hash=$(mp_stable_hash "$project_root")
  printf '%s/%s-%s.json\n' "$state_root" "$safe_session" "$hash"
}

mp_default_state_json() {
  local project_root="$1"
  jq -n --arg projectRoot "$project_root" '{dirty: false, retryUsed: false, projectRoot: $projectRoot}'
}

mp_get_hook_state() {
  local session_id="$1" project_root="$2" state_root="$3" path
  path=$(mp_session_state_path "$session_id" "$project_root" "$state_root")
  if [ ! -f "$path" ] || ! jq -e . "$path" >/dev/null 2>&1; then
    mp_default_state_json "$project_root"
    return 0
  fi
  cat "$path"
}

mp_set_hook_state() {
  local session_id="$1" project_root="$2" state_root="$3" dirty="$4" retry_used="$5"
  local path tmp
  path=$(mp_session_state_path "$session_id" "$project_root" "$state_root")
  mkdir -p "$(dirname "$path")"
  tmp=$(mktemp "$(dirname "$path")/.tmp.XXXXXX")
  jq -n --argjson dirty "$dirty" --argjson retryUsed "$retry_used" \
    --arg projectRoot "$project_root" --arg updatedAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{dirty: $dirty, retryUsed: $retryUsed, projectRoot: $projectRoot, updatedAt: $updatedAt}' > "$tmp"
  mv -f "$tmp" "$path"
}

mp_remove_hook_state() {
  local session_id="$1" state_root="$2" safe_session
  [ -d "$state_root" ] || return 0
  safe_session=$(printf '%s' "$session_id" | sed -E 's/[^A-Za-z0-9_.-]/_/g')
  [ -z "$safe_session" ] && safe_session="unknown"
  rm -f "$state_root/$safe_session"-*.json 2>/dev/null
  return 0
}

# --- Cross-process project lock (mkdir spin-lock; no flock on macOS) ---

MP_LOCK_DIR=""

mp_acquire_lock() {
  local project_root="$1" timeout="${2:-10}" hash waited max_wait holder_pid
  hash=$(mp_stable_hash "$project_root" | cut -c1-24)
  MP_LOCK_DIR="${TMPDIR:-/tmp}/markplane-claude-hook-$hash.lock"
  waited=0
  max_wait=$((timeout * 5))
  while ! mkdir "$MP_LOCK_DIR" 2>/dev/null; do
    if [ -f "$MP_LOCK_DIR/pid" ]; then
      holder_pid=$(cat "$MP_LOCK_DIR/pid" 2>/dev/null)
      if [ -n "$holder_pid" ] && ! kill -0 "$holder_pid" 2>/dev/null; then
        rm -rf "$MP_LOCK_DIR"
        continue
      fi
    fi
    sleep 0.2
    waited=$((waited + 1))
    if [ "$waited" -ge "$max_wait" ]; then
      return 124
    fi
  done
  echo $$ > "$MP_LOCK_DIR/pid"
  return 0
}

mp_release_lock() {
  [ -n "$MP_LOCK_DIR" ] && rm -rf "$MP_LOCK_DIR"
  MP_LOCK_DIR=""
}

# --- Running the markplane CLI with a manual timeout (no GNU timeout on macOS) ---

MP_RUN_EXIT=0
MP_RUN_STDOUT=""
MP_RUN_STDERR=""

mp_run_markplane() {
  local exe="$1" cwd="$2" out_file err_file pid watchdog code
  shift 2
  out_file=$(mktemp)
  err_file=$(mktemp)
  ( cd "$cwd" && "$exe" "$@" >"$out_file" 2>"$err_file" ) &
  pid=$!
  ( sleep 10; kill -0 "$pid" 2>/dev/null && kill "$pid" 2>/dev/null ) &
  watchdog=$!
  wait "$pid" 2>/dev/null
  code=$?
  kill "$watchdog" 2>/dev/null
  wait "$watchdog" 2>/dev/null
  MP_RUN_EXIT=$code
  MP_RUN_STDOUT=$(cat "$out_file")
  MP_RUN_STDERR=$(cat "$err_file")
  rm -f "$out_file" "$err_file"
}

# --- PostToolUse relevance check ---

mp_resolve_tool_path() {
  local input_json="$1" project_root="$2" key val
  for key in file_path path notebook_path; do
    val=$(printf '%s' "$input_json" | jq -r --arg k "$key" '.tool_input[$k] // empty' 2>/dev/null)
    if [ -n "$val" ]; then
      case "$val" in
        /*) printf '%s\n' "$val"; return 0 ;;
        *) printf '%s\n' "$project_root/$val"; return 0 ;;
      esac
    fi
  done
  return 1
}

mp_path_inside() {
  local path="$1" container="$2"
  case "$path" in
    "$container"|"$container"/*) return 0 ;;
    *) return 1 ;;
  esac
}

mp_relevant_post_tool_use() {
  local input_json="$1" project_root="$2" tool_name sub path command patch
  tool_name=$(printf '%s' "$input_json" | jq -r '.tool_name // empty' 2>/dev/null)
  [ -z "$tool_name" ] && return 1

  case "$tool_name" in
    mcp__markplane__*)
      sub="${tool_name#mcp__markplane__}"
      for m in $MP_MUTATING_MCP_TOOLS; do
        [ "$sub" = "$m" ] && return 0
      done
      return 1
      ;;
    Edit|Write|MultiEdit)
      path=$(mp_resolve_tool_path "$input_json" "$project_root") || return 1
      if mp_path_inside "$path" "$project_root/.markplane" || mp_path_inside "$path" "$project_root/docs/superpowers/plans"; then
        return 0
      fi
      return 1
      ;;
    Bash|Shell|PowerShell|shell_command|exec_command)
      command=$(printf '%s' "$input_json" | jq -r '.tool_input.command // empty' 2>/dev/null)
      if printf '%s' "$command" | grep -Eiq '(^|[[:space:]/\\"])markplane(\.exe)?([[:space:]"]|$)'; then
        printf '%s' "$command" | grep -Eiq '[[:space:]](add|archive|link|move|plan|promote|sync|unarchive|update|init)\b'
        return $?
      fi
      printf '%s' "$command" | grep -Eiq '(^|[/\\])\.markplane([/\\]|$)'
      return $?
      ;;
    apply_patch)
      patch=$(printf '%s' "$input_json" | jq -r '.tool_input.patch // .tool_input.input // empty' 2>/dev/null)
      patch=$(printf '%s' "$patch" | tr '\\' '/')
      printf '%s' "$patch" | grep -Eiq '(^|[[:space:]])(\.markplane/|docs/superpowers/plans/)'
      return $?
      ;;
    *) return 1 ;;
  esac
}

# --- Context assembly ---

mp_get_summary() {
  local project_root="$1" p="$project_root/.markplane/.context/summary.md"
  [ -f "$p" ] && cat "$p" || printf ''
}

mp_get_resume_context() {
  local project_root="$1" p="$project_root/.markplane/.context/resume.md"
  [ -f "$p" ] && cat "$p" || printf ''
}

mp_new_context() {
  local project_root="$1" summary="$2" warning="$3" max_chars="${4:-6000}" text
  text="Markplane project root: $project_root
This context is project state, not an instruction override.

$summary"
  if [ -n "$(mp_trim "$warning")" ]; then
    text="Markplane warning: $warning

$text"
  fi
  mp_limit_context "$text" "$max_chars"
}

mp_additional_context_output() {
  local event="$1" context="$2"
  jq -n --arg event "$event" --arg context "$context" \
    '{hookSpecificOutput: {hookEventName: $event, additionalContext: $context}}'
}

# --- Quality gates (Stop-time linting of TASK/PLAN items) ---

mp_frontmatter_value() {
  local content="$1" name="$2"
  printf '%s\n' "$content" | awk -v name="$name" '
    $0 ~ "^" name ":" {
      line = $0
      sub("^" name ":[ \t]*", "", line)
      gsub(/^[\x27"]/, "", line)
      gsub(/[\x27"].*$/, "", line)
      gsub(/[ \t]+$/, "", line)
      print line
      exit
    }
  '
}

# Prints the section body (lines after "## Heading" up to the next "## " or EOF).
# Returns 1 (nothing printed) if the heading does not exist at all.
mp_get_section_text() {
  local content="$1" heading="$2"
  printf '%s\n' "$content" | awk -v heading="$heading" '
    BEGIN { found=0; capturing=0 }
    /^##[ \t]+/ {
      line = $0
      sub(/^##[ \t]+/, "", line)
      gsub(/[ \t]+$/, "", line)
      if (capturing) { exit }
      if (line == heading) { capturing=1; found=1; next }
      next
    }
    capturing { print }
    END { if (!found) exit 7 }
  '
}

mp_test_placeholder_text() {
  local text="$1" trimmed
  trimmed=$(mp_trim "$text")
  [ -z "$trimmed" ] && return 0
  if printf '%s\n' "$text" | grep -Eiq '\[(what|source|observable|reference|detailed|content|key|recommended|measurable|strategic|environment|implementation|how|why|which|placeholder|tbd|todo|fill|criterion|step)[^]]*\]'; then
    return 0
  fi
  if printf '%s\n' "$text" | grep -Eiq '^[[:space:]]*-[[:space:]]\[[[:space:]]\][[:space:]]*Criterion[[:space:]]+[0-9]+[[:space:]]*$'; then
    return 0
  fi
  if printf '%s\n' "$text" | grep -Eiq '^[[:space:]]*[0-9]+\.[[:space:]]*Step[[:space:]]+[0-9]+[[:space:]]*$'; then
    return 0
  fi
  if printf '%s\n' "$text" | grep -Eiq '\b(TBD|TODO|fill in|Content goes here)\b'; then
    return 0
  fi
  return 1
}

mp_test_checklist_has_concrete_item() {
  local text="$1" trimmed line label
  trimmed=$(mp_trim "$text")
  [ -z "$trimmed" ] && return 1
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]\[[[:space:]xX]\][[:space:]]+(.+)[[:space:]]*$ ]]; then
      label="${BASH_REMATCH[1]}"
      if ! mp_test_placeholder_text "$label"; then
        return 0
      fi
    fi
  done <<< "$text"
  return 1
}

mp_relative_path() {
  local root="$1" path="$2"
  case "$path" in
    "$root"/*) printf '%s\n' "${path#"$root"/}" ;;
    *) printf '%s\n' "$path" ;;
  esac
}

# Prints one issue per line; empty output = no issues.
mp_test_item_quality() {
  local path="$1" kind="$2" project_root="$3"
  local content id status relative
  content=$(cat "$path")
  id=$(mp_frontmatter_value "$content" "id")
  [ -z "$id" ] && id=$(basename "$path" .md)
  status=$(mp_frontmatter_value "$content" "status" | tr '[:upper:]' '[:lower:]')
  relative=$(mp_relative_path "$project_root" "$path")

  if mp_test_placeholder_text "$content"; then
    echo "$id ($relative): contains placeholder text."
  fi

  if [ "$kind" = "task" ] && { [ "$status" = "planned" ] || [ "$status" = "in-progress" ]; }; then
    local description criteria validation
    description=$(mp_get_section_text "$content" "Description") || description=""
    if mp_test_placeholder_text "$description"; then
      echo "$id ($relative): planned/in-progress task needs a concrete Description."
    fi
    criteria=$(mp_get_section_text "$content" "Acceptance Criteria") || criteria=""
    if ! mp_test_checklist_has_concrete_item "$criteria"; then
      echo "$id ($relative): planned/in-progress task needs concrete Acceptance Criteria."
    fi
    if validation=$(mp_get_section_text "$content" "Validation Plan"); then
      if mp_test_placeholder_text "$validation"; then
        echo "$id ($relative): Validation Plan exists but is still empty or placeholder text."
      fi
    fi
  fi

  if [ "$kind" = "plan" ] && [ "$status" != "draft" ] && [ -n "$status" ]; then
    local heading section approach target
    for heading in "Ground Truth" "Testing Strategy"; do
      section=$(mp_get_section_text "$content" "$heading") || section=""
      if mp_test_placeholder_text "$section"; then
        echo "$id ($relative): plan needs a concrete $heading section."
      fi
    done
    approach=$(mp_get_section_text "$content" "Approach") || approach=""
    target=$(mp_get_section_text "$content" "Target State") || target=""
    if mp_test_placeholder_text "$approach" && mp_test_placeholder_text "$target"; then
      echo "$id ($relative): plan needs a concrete Approach or Target State."
    fi
    local implements_value
    implements_value=$(mp_frontmatter_value "$content" "implements")
    if [ -z "$(mp_trim "$implements_value")" ] || [ "$implements_value" = "[]" ]; then
      echo "$id ($relative): plan does not implement any task - orphaned from the graph."
    fi
  fi
}

# Cross-references Epics against tasks that link to them via 'epic:'.
# Sets MP_CONNECTIVITY_ISSUES (blocking) and MP_CONNECTIVITY_WARNINGS
# (non-blocking, newline-separated).
mp_test_graph_connectivity() {
  local project_root="$1"
  local task_dir="$project_root/.markplane/backlog/items"
  local epic_dir="$project_root/roadmap/items"
  local f content id epic_id relative
  local referenced_epics=""
  local orphan_tasks=""
  local orphan_count=0

  if [ -d "$task_dir" ]; then
    for f in "$task_dir"/TASK-*.md; do
      [ -e "$f" ] || continue
      content=$(cat "$f")
      id=$(mp_frontmatter_value "$content" "id")
      [ -z "$id" ] && id=$(basename "$f" .md)
      epic_id=$(mp_frontmatter_value "$content" "epic")
      if [ -n "$(mp_trim "$epic_id")" ] && [ "$epic_id" != "null" ]; then
        referenced_epics="$referenced_epics $epic_id"
      else
        orphan_tasks="${orphan_tasks:+$orphan_tasks, }$id"
        orphan_count=$((orphan_count + 1))
      fi
    done
  fi

  MP_CONNECTIVITY_ISSUES=""
  MP_CONNECTIVITY_WARNINGS=""

  local any_epic_exists=0
  if [ -d "$epic_dir" ]; then
    for f in "$epic_dir"/EPIC-*.md; do
      [ -e "$f" ] || continue
      any_epic_exists=1
      content=$(cat "$f")
      id=$(mp_frontmatter_value "$content" "id")
      [ -z "$id" ] && id=$(basename "$f" .md)
      relative=$(mp_relative_path "$project_root" "$f")
      case " $referenced_epics " in
        *" $id "*) ;;
        *) MP_CONNECTIVITY_ISSUES="$MP_CONNECTIVITY_ISSUES$id ($relative): epic has no tasks linked via 'epic:' - orphaned from the graph.
" ;;
      esac
    done
  fi

  if [ "$any_epic_exists" -eq 1 ] && [ "$orphan_count" -gt 0 ]; then
    MP_CONNECTIVITY_WARNINGS="$orphan_count task(s) not linked to any Epic via 'epic:' ($orphan_tasks) - consider linking for graph visibility.
"
  fi
}

mp_test_superpowers_plan_links() {
  local project_root="$1" superpowers_dir plans_dir plan_text relative f
  superpowers_dir="$project_root/docs/superpowers/plans"
  [ -d "$superpowers_dir" ] || return 0

  plans_dir="$project_root/.markplane/plans/items"
  plan_text=""
  if [ -d "$plans_dir" ]; then
    for f in "$plans_dir"/PLAN-*.md; do
      [ -e "$f" ] || continue
      plan_text="$plan_text
$(cat "$f")"
    done
  fi
  plan_text=$(printf '%s' "$plan_text" | tr '\\' '/')

  for f in "$superpowers_dir"/*.md; do
    [ -e "$f" ] || continue
    relative=$(mp_relative_path "$project_root" "$f")
    if ! printf '%s' "$plan_text" | grep -Fq "$relative" && ! printf '%s' "$plan_text" | grep -Fq "$(basename "$f")"; then
      echo "Superpowers plan is not linked from any Markplane PLAN: $relative"
    fi
  done
}

# Sets MP_QUALITY_EXIT (0/1) and MP_QUALITY_MESSAGE.
mp_test_project_quality() {
  local project_root="$1" issues="" task_dir plan_dir f kind

  task_dir="$project_root/.markplane/backlog/items"
  if [ -d "$task_dir" ]; then
    for f in "$task_dir"/TASK-*.md; do
      [ -e "$f" ] || continue
      issues="$issues$(mp_test_item_quality "$f" "task" "$project_root")
"
    done
  fi

  plan_dir="$project_root/.markplane/plans/items"
  if [ -d "$plan_dir" ]; then
    for f in "$plan_dir"/PLAN-*.md; do
      [ -e "$f" ] || continue
      issues="$issues$(mp_test_item_quality "$f" "plan" "$project_root")
"
    done
  fi

  issues="$issues$(mp_test_superpowers_plan_links "$project_root")
"

  mp_test_graph_connectivity "$project_root"
  issues="$issues$MP_CONNECTIVITY_ISSUES"
  local warnings="$MP_CONNECTIVITY_WARNINGS"

  issues=$(printf '%s' "$issues" | sed '/^[[:space:]]*$/d')
  warnings=$(printf '%s' "$warnings" | sed '/^[[:space:]]*$/d')

  if [ -z "$issues" ]; then
    MP_QUALITY_EXIT=0
    MP_QUALITY_MESSAGE="Markplane quality check passed."
    if [ -n "$warnings" ]; then
      MP_QUALITY_MESSAGE="$MP_QUALITY_MESSAGE
Markplane quality warnings (non-blocking):
- $(printf '%s' "$warnings" | sed ':a;N;$!ba;s/\n/\n- /g')"
    fi
  else
    MP_QUALITY_EXIT=1
    MP_QUALITY_MESSAGE="Markplane quality check failed:
- $(printf '%s' "$issues" | sed ':a;N;$!ba;s/\n/\n- /g')"
    if [ -n "$warnings" ]; then
      MP_QUALITY_MESSAGE="$MP_QUALITY_MESSAGE
Markplane quality warnings (non-blocking):
- $(printf '%s' "$warnings" | sed ':a;N;$!ba;s/\n/\n- /g')"
    fi
  fi
}

# --- Locked markplane CLI invocations ---

mp_run_sync_locked() {
  local project_root="$1" exe="$2"
  if ! mp_acquire_lock "$project_root" 10; then
    MP_RUN_EXIT=124; MP_RUN_STDOUT=""; MP_RUN_STDERR="Timed out waiting for Markplane project lock."
    return
  fi
  mp_run_markplane "$exe" "$project_root" sync
  mp_release_lock
}

# Mirrors Merge-MarkplaneCheckResults: on any failure, only failing results'
# stdout/stderr are kept; if both pass, both stdouts are concatenated.
mp_run_check_and_quality_locked() {
  local project_root="$1" exe="$2"
  if ! mp_acquire_lock "$project_root" 10; then
    MP_RUN_EXIT=124; MP_RUN_STDOUT=""; MP_RUN_STDERR="Timed out waiting for Markplane project lock."
    return
  fi
  mp_run_markplane "$exe" "$project_root" check
  local check_exit=$MP_RUN_EXIT check_out="$MP_RUN_STDOUT" check_err="$MP_RUN_STDERR"
  mp_test_project_quality "$project_root"
  local quality_exit=$MP_QUALITY_EXIT quality_out="$MP_QUALITY_MESSAGE"
  mp_release_lock

  local any_failed=0
  local fail_out="" fail_err="" pass_out=""
  if [ "$check_exit" -ne 0 ]; then
    any_failed=1
    fail_out="${fail_out:+$fail_out$'\n'}$check_out"
    fail_err="${fail_err:+$fail_err$'\n'}$check_err"
  else
    pass_out="${pass_out:+$pass_out$'\n'}$check_out"
  fi
  if [ "$quality_exit" -ne 0 ]; then
    any_failed=1
    fail_out="${fail_out:+$fail_out$'\n'}$quality_out"
  else
    pass_out="${pass_out:+$pass_out$'\n'}$quality_out"
  fi

  if [ "$any_failed" -eq 1 ]; then
    MP_RUN_EXIT=1
    MP_RUN_STDOUT="$fail_out"
    MP_RUN_STDERR="$fail_err"
  else
    MP_RUN_EXIT=0
    MP_RUN_STDOUT="$pass_out"
    MP_RUN_STDERR=""
  fi
}

# --- Event dispatcher (bash port of Invoke-MarkplaneClaudeHookEvent) ---
#
# Args: event input_json markplane_exe max_context_chars state_root
# Prints the hook's JSON response on stdout, or nothing if no response is needed.
mp_handle_event() {
  local event="$1" input_json="$2" markplane_exe="$3" max_context_chars="${4:-6000}" state_root="$5"
  local session_id cwd project_root

  session_id=$(printf '%s' "$input_json" | jq -r '.session_id // empty' 2>/dev/null)
  [ -z "$session_id" ] && session_id="unknown"

  if [ "$event" = "SessionEnd" ]; then
    mp_remove_hook_state "$session_id" "$state_root"
    return 0
  fi

  cwd=$(printf '%s' "$input_json" | jq -r '.cwd // empty' 2>/dev/null)
  [ -z "$cwd" ] && cwd="$(pwd)"

  project_root=$(mp_find_project_root "$cwd") || return 0

  case "$event" in
    SessionStart)
      mp_run_sync_locked "$project_root" "$markplane_exe"
      mp_set_hook_state "$session_id" "$project_root" "$state_root" false false
      local warning=""
      if [ "$MP_RUN_EXIT" -ne 0 ]; then
        warning=$(printf '%s\n%s' "$MP_RUN_STDERR" "$MP_RUN_STDOUT" | sed '/^[[:space:]]*$/d')
      fi

      local source context
      source=$(printf '%s' "$input_json" | jq -r '.source // empty' 2>/dev/null)
      if [ "$source" = "compact" ]; then
        local compact_cap=$max_context_chars
        [ "$compact_cap" -gt 2000 ] && compact_cap=2000
        context=$(mp_new_context "$project_root" "$(mp_get_resume_context "$project_root")" "$warning" "$compact_cap")
      else
        context=$(mp_new_context "$project_root" "$(mp_get_summary "$project_root")" "$warning" "$max_context_chars")
      fi
      mp_additional_context_output "SessionStart" "$context"
      ;;

    SubagentStart)
      local sub_cap=$max_context_chars
      [ "$sub_cap" -gt 800 ] && sub_cap=800
      local sub_context
      sub_context=$(printf 'Markplane project root: %s\nRead order: .markplane/.context/summary.md, then relevant task/plan/note files.\nSuperpowers plans in docs/superpowers/plans must be linked or summarized in Markplane PLAN items.\nGraph contract: group related tasks under an Epic (epic: field), give multi-task work a PLAN (implements:), and record decisions/research as a NOTE (related:) - Stop blocks on orphaned Epics/Plans.\nGovernance: preserve raw data, generated results, notebooks, and scoped AGENTS/CLAUDE rules.' "$project_root")
      sub_context=$(mp_limit_context "$sub_context" "$sub_cap")
      mp_additional_context_output "SubagentStart" "$sub_context"
      ;;

    PostToolUse)
      mp_relevant_post_tool_use "$input_json" "$project_root" || return 0

      mp_run_sync_locked "$project_root" "$markplane_exe"
      mp_set_hook_state "$session_id" "$project_root" "$state_root" true false
      if [ "$MP_RUN_EXIT" -ne 0 ]; then
        local message
        message=$(printf '%s\n%s' "$MP_RUN_STDERR" "$MP_RUN_STDOUT" | sed '/^[[:space:]]*$/d')
        message=$(mp_limit_context "$message" 1600)
        mp_additional_context_output "PostToolUse" "Markplane sync failed after a Markplane change.
$message"
      fi
      ;;

    Stop)
      local state dirty background_count
      state=$(mp_get_hook_state "$session_id" "$project_root" "$state_root")
      dirty=$(printf '%s' "$state" | jq -r '.dirty')
      [ "$dirty" != "true" ] && return 0

      background_count=$(printf '%s' "$input_json" | jq -r '.background_tasks // [] | length' 2>/dev/null)
      [ -z "$background_count" ] && background_count=0
      [ "$background_count" -gt 0 ] && return 0

      mp_run_sync_locked "$project_root" "$markplane_exe"
      local sync_exit=$MP_RUN_EXIT sync_out="$MP_RUN_STDOUT" sync_err="$MP_RUN_STDERR"

      local final_exit final_out final_err
      if [ "$sync_exit" -eq 0 ]; then
        mp_run_check_and_quality_locked "$project_root" "$markplane_exe"
        final_exit=$MP_RUN_EXIT; final_out="$MP_RUN_STDOUT"; final_err="$MP_RUN_STDERR"
      else
        final_exit=$sync_exit; final_out="$sync_out"; final_err="$sync_err"
      fi

      if [ "$final_exit" -eq 0 ]; then
        mp_set_hook_state "$session_id" "$project_root" "$state_root" false false
        return 0
      fi

      local retry_used diagnostic
      retry_used=$(printf '%s' "$state" | jq -r '.retryUsed')
      diagnostic=$(printf '%s\n%s' "$final_err" "$final_out" | sed '/^[[:space:]]*$/d')
      diagnostic=$(mp_limit_context "$diagnostic" 2200)

      if [ "$retry_used" != "true" ]; then
        mp_set_hook_state "$session_id" "$project_root" "$state_root" true true
        mp_additional_context_output "Stop" "Markplane consistency check failed. Fix the issue once, then stop again.
$diagnostic"
      else
        mp_set_hook_state "$session_id" "$project_root" "$state_root" false true
        jq -n --arg msg "Markplane consistency check still failed after one correction attempt.
$diagnostic" '{systemMessage: $msg}'
      fi
      ;;
  esac
}
