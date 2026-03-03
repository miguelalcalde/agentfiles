#!/usr/bin/env bash
#
# conduct.sh — External conductor loop for the backlog implement workflow.
#
# Re-invokes an agent CLI until the plan is fully implemented or a blocker
# is hit. The plan file is the shared state — each session reads task statuses,
# skips completed work, and picks up where it left off.
#
# Usage:
#   ./scripts/conduct.sh <slug> --worktree <path> [options]
#
# Examples:
#   ./scripts/conduct.sh provider-expansion-s3-ftp --worktree ../bp-s3-ftp
#   ./scripts/conduct.sh provider-expansion-s3-ftp --worktree ../bp-s3-ftp --max-runs 5

set -euo pipefail

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
show_help() {
  cat <<'HELP'
conduct.sh — Conductor loop for backlog implementation workflow

Repeatedly invokes an agent CLI to implement one phase at a time until
the plan reaches status `implemented`, all tasks are done, or --max-runs
is exhausted.

USAGE
  ./scripts/conduct.sh <slug> --worktree <path> [options]

ARGUMENTS
  <slug>    The feature slug (e.g. provider-expansion-s3-ftp).
            Must match a plan at .backlog/plans/PLAN-<slug>.md
            with status "approved" or "partially_implemented".

OPTIONS
  --worktree <path>   (Required) Run inside a git worktree. Created
                      automatically on the plan's feature branch if it
                      doesn't exist. Keeps your main checkout untouched.
  --engine <name>     Agent engine to use: cursor | claude.
                      Default: cursor
  --engine-cmd <cmd>  Override engine binary (e.g. /usr/local/bin/agent).
  --interactive       Cursor only: run interactive mode instead of headless.
  --headless          Cursor only: force headless mode (default).
  --max-runs <n>      Maximum agent invocations before stopping.
                      Default: 20
  --cooldown <s>      Seconds to wait between runs. Default: 5
  --dry-run           Print what would happen without invoking an agent.
  -h, --help          Show this help message.

EXAMPLES
  # Standard usage (cursor headless by default)
  ./scripts/conduct.sh provider-expansion-s3-ftp --worktree ../bp-s3-ftp

  # Cursor interactive mode
  ./scripts/conduct.sh provider-expansion-s3-ftp --worktree ../bp-s3-ftp --interactive

  # Explicit engine selection
  ./scripts/conduct.sh provider-expansion-s3-ftp --worktree ../bp-s3-ftp --engine claude

  # Limit to 5 sessions, 10s between each run
  ./scripts/conduct.sh provider-expansion-s3-ftp --worktree ../bp-s3-ftp --max-runs 5 --cooldown 10

  # Preview without actually running
  ./scripts/conduct.sh provider-expansion-s3-ftp --worktree ../bp-s3-ftp --dry-run

HOW IT WORKS
  1. Creates or reuses a git worktree on feat/<slug>.
  2. Validates the plan file exists and has an actionable status.
  3. Loops:
     a. Detects the current phase (first phase with pending tasks).
     b. Invokes the selected engine scoped to that phase only.
     c. The agent implements tasks, commits, and updates the plan file.
     d. When the session ends, the loop re-checks and continues.
  4. On success (status=implemented):
     a. Pushes the feature branch to origin.
     b. Removes the worktree.
  5. Logs:
     - Conductor log: .backlog/logs/conduct-<slug>-<timestamp>.log
     - Per-run agent logs: .backlog/logs/agent-<slug>-run-<N>.log

STOPPING
  Ctrl+C stops the current session and the loop.
  Progress is preserved — re-run the same command to continue.
HELP
}

# ---------------------------------------------------------------------------
# Args
# ---------------------------------------------------------------------------
SLUG=""
WORKTREE=""
MAX_RUNS=20
COOLDOWN=5
DRY_RUN=false
ENGINE="cursor"
ENGINE_CMD=""
CURSOR_MODE="headless"
FALLBACK_CMD=""

require_value() {
  local flag="$1"
  local value="${2-}"
  if [[ -z "$value" || "$value" == -* ]]; then
    echo "Error: ${flag} requires a value." >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)   show_help; exit 0 ;;
    --worktree)  require_value "$1" "${2-}"; WORKTREE="$2";  shift 2 ;;
    --max-runs)  require_value "$1" "${2-}"; MAX_RUNS="$2";  shift 2 ;;
    --cooldown)  require_value "$1" "${2-}"; COOLDOWN="$2";  shift 2 ;;
    --engine)    require_value "$1" "${2-}"; ENGINE="$2";    shift 2 ;;
    --engine-cmd) require_value "$1" "${2-}"; ENGINE_CMD="$2"; shift 2 ;;
    --interactive) CURSOR_MODE="interactive"; shift ;;
    --headless)  CURSOR_MODE="headless"; shift ;;
    --dry-run)   DRY_RUN=true;   shift   ;;
    -*)          echo "Unknown option: $1 (use --help for usage)" >&2; exit 1 ;;
    *)
      if [[ -n "$SLUG" ]]; then
        echo "Error: only one <slug> argument is allowed." >&2
        exit 1
      fi
      SLUG="$1"
      shift
      ;;
  esac
done

if [[ -z "$SLUG" ]]; then
  show_help
  exit 1
fi

if [[ -z "$WORKTREE" ]]; then
  echo "Error: --worktree is required." >&2
  echo "" >&2
  echo "The conductor runs in an isolated worktree to avoid disrupting" >&2
  echo "your main working directory." >&2
  echo "" >&2
  echo "Usage: $0 ${SLUG} --worktree <path>" >&2
  echo "Example: $0 ${SLUG} --worktree ../$(basename "$(pwd)")-${SLUG}" >&2
  exit 1
fi

if ! [[ "$MAX_RUNS" =~ ^[0-9]+$ ]] || [[ "$MAX_RUNS" -lt 1 ]]; then
  echo "Error: --max-runs must be a positive integer." >&2
  exit 1
fi

if ! [[ "$COOLDOWN" =~ ^[0-9]+$ ]]; then
  echo "Error: --cooldown must be a non-negative integer." >&2
  exit 1
fi

if [[ "$ENGINE" != "cursor" && "$ENGINE" != "claude" ]]; then
  echo "Error: --engine must be one of: cursor, claude." >&2
  exit 1
fi

resolve_engine_commands() {
  if [[ "$ENGINE" == "cursor" ]]; then
    if [[ -n "$ENGINE_CMD" ]]; then
      if ! command -v "$ENGINE_CMD" >/dev/null 2>&1; then
        echo "Error: --engine-cmd '$ENGINE_CMD' was not found in PATH." >&2
        exit 1
      fi
    elif command -v agent >/dev/null 2>&1; then
      ENGINE_CMD="agent"
    else
      if command -v claude >/dev/null 2>&1; then
        ENGINE="claude"
        ENGINE_CMD="claude"
        echo "Warning: cursor agent not found, falling back to claude." >&2
      else
        echo "Error: neither 'agent' (cursor) nor 'claude' is available in PATH." >&2
        exit 1
      fi
    fi

    if command -v claude >/dev/null 2>&1; then
      FALLBACK_CMD="claude"
    fi
  else
    if [[ -n "$ENGINE_CMD" ]]; then
      if ! command -v "$ENGINE_CMD" >/dev/null 2>&1; then
        echo "Error: --engine-cmd '$ENGINE_CMD' was not found in PATH." >&2
        exit 1
      fi
    elif command -v claude >/dev/null 2>&1; then
      ENGINE_CMD="claude"
    else
      echo "Error: 'claude' is not available in PATH." >&2
      exit 1
    fi
  fi
}

resolve_engine_commands

PLAN_FILE=".backlog/plans/PLAN-${SLUG}.md"
BRANCH="feat/${SLUG}"
LOG_DIR=".backlog/logs"
LOG_FILE="${LOG_DIR}/conduct-${SLUG}-$(date +%Y%m%d-%H%M%S).log"
ORIGIN_DIR="$(pwd)"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

get_plan_status() {
  local status_line=""
  status_line=$(grep -m1 '^status:' "$PLAN_FILE" 2>/dev/null || true)
  echo "$status_line" | sed 's/status:[[:space:]]*//'
}

count_tasks() {
  local status="$1"
  grep -c "\*\*Status\*\*: ${status}" "$PLAN_FILE" 2>/dev/null || echo 0
}

print_progress() {
  local total completed pending blocked in_progress
  total=$(grep -c '\*\*Status\*\*:' "$PLAN_FILE" 2>/dev/null || echo 0)
  completed=$(count_tasks "complete")
  pending=$(count_tasks "pending")
  in_progress=$(count_tasks "in_progress")
  blocked=$(count_tasks "blocked")
  log "Progress: ${completed}/${total} complete | ${in_progress} in_progress | ${pending} pending | ${blocked} blocked"
}

# Find the first phase section that still has pending or in_progress tasks.
# Returns the phase header text (e.g., "Phase 0: Unified Data Model + Drive Migration")
# or empty string if no pending phases.
get_current_phase() {
  local current_phase=""
  local in_phase=""
  while IFS= read -r line; do
    # Match phase headers like "## Phase 0: ..." or "## Phase 1: ..."
    if [[ "$line" =~ ^##\ (Phase\ [0-9]+:.*)$ ]]; then
      # If we were in a phase that had pending work, return it
      if [[ -n "$in_phase" ]]; then
        echo "$in_phase"
        return
      fi
      current_phase="${BASH_REMATCH[1]}"
      in_phase=""
    fi
    # Check if current line has a pending or in_progress task
    if [[ -n "$current_phase" && "$line" == *"**Status**: pending"* ]] || \
       [[ -n "$current_phase" && "$line" == *"**Status**: in_progress"* ]]; then
      in_phase="$current_phase"
    fi
  done < "$PLAN_FILE"
  # Check the last phase
  if [[ -n "$in_phase" ]]; then
    echo "$in_phase"
  fi
}

build_phase_prompt() {
  local phase="$1"
  cat <<EOF
Implement feature slug "${SLUG}" by executing ONLY tasks from "${phase}" in "${PLAN_FILE}".

Requirements:
- Follow "skills/backlog/implement/SKILL.md".
- Do not read or implement tasks from other phases.
- Commit each completed logical task locally.
- Update task statuses in the plan file.
- Stop when all tasks in this phase are complete or blocked.
EOF
}

invoke_engine() {
  local prompt="$1"
  if [[ "$ENGINE" == "cursor" ]]; then
    if [[ "$CURSOR_MODE" == "interactive" ]]; then
      "$ENGINE_CMD" "$prompt"
    else
      "$ENGINE_CMD" -p --force --trust "$prompt"
    fi
  else
    "$ENGINE_CMD" --verbose "$prompt"
  fi
}

# ---------------------------------------------------------------------------
# Worktree setup
# ---------------------------------------------------------------------------
if [[ ! -d "$WORKTREE" ]]; then
  echo "Creating worktree at ${WORKTREE} on branch ${BRANCH}..."
  if git show-ref --verify --quiet "refs/heads/${BRANCH}" 2>/dev/null; then
    git worktree add "$WORKTREE" "$BRANCH"
  elif git show-ref --verify --quiet "refs/remotes/origin/${BRANCH}" 2>/dev/null; then
    git worktree add -b "$BRANCH" "$WORKTREE" "origin/${BRANCH}"
  else
    git worktree add -b "$BRANCH" "$WORKTREE"
  fi
else
  if ! git -C "$WORKTREE" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: --worktree path exists but is not a git worktree: ${WORKTREE}" >&2
    exit 1
  fi
fi

WORK_DIR="$(cd "$WORKTREE" && pwd)"
cd "$WORK_DIR"

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
if [[ ! -f "$PLAN_FILE" ]]; then
  echo "Plan file not found: ${PLAN_FILE}" >&2
  exit 1
fi

mkdir -p "$LOG_DIR"

PLAN_STATUS=$(get_plan_status)
if [[ "$PLAN_STATUS" != "approved" && "$PLAN_STATUS" != "partially_implemented" ]]; then
  echo "Plan status is '${PLAN_STATUS}' — must be 'approved' or 'partially_implemented' to run." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------
log "=== Conductor started for: ${SLUG} ==="
log "Plan: ${PLAN_FILE}"
log "Branch: ${BRANCH}"
log "Worktree: ${WORK_DIR}"
log "Engine: ${ENGINE} (${ENGINE_CMD})"
if [[ "$ENGINE" == "cursor" ]]; then
  log "Cursor mode: ${CURSOR_MODE}"
fi
log "Max runs: ${MAX_RUNS}"
print_progress

RUN=0
while true; do
  RUN=$((RUN + 1))

  # --- Check termination conditions ---
  PLAN_STATUS=$(get_plan_status)
  if [[ "$PLAN_STATUS" == "implemented" ]]; then
    log "Plan is fully implemented!"
    print_progress
    break
  fi

  PENDING=$(count_tasks "pending")
  IN_PROGRESS=$(count_tasks "in_progress")
  if [[ "$PENDING" -eq 0 && "$IN_PROGRESS" -eq 0 ]]; then
    log "No pending or in_progress tasks remaining."
    print_progress
    break
  fi

  if [[ "$RUN" -gt "$MAX_RUNS" ]]; then
    log "Reached max runs (${MAX_RUNS}). Stopping."
    print_progress
    break
  fi

  # --- Detect current phase ---
  CURRENT_PHASE=$(get_current_phase)
  if [[ -z "$CURRENT_PHASE" ]]; then
    log "No phase with pending tasks found. Stopping."
    print_progress
    break
  fi

  # --- Run agent ---
  AGENT_LOG="${LOG_DIR}/agent-${SLUG}-run-${RUN}.log"
  log ""
  log "--- Run ${RUN}/${MAX_RUNS} [${CURRENT_PHASE}] ---"
  print_progress

  PROMPT=$(build_phase_prompt "$CURRENT_PHASE")

  if [[ "$DRY_RUN" == true ]]; then
    if [[ "$ENGINE" == "cursor" && "$CURSOR_MODE" == "headless" ]]; then
      log "[DRY RUN] Would invoke: ${ENGINE_CMD} -p --force --trust \"<phase prompt>\""
    elif [[ "$ENGINE" == "cursor" ]]; then
      log "[DRY RUN] Would invoke: ${ENGINE_CMD} \"<phase prompt>\""
    else
      log "[DRY RUN] Would invoke: ${ENGINE_CMD} --verbose \"<phase prompt>\""
    fi
    log "[DRY RUN] Prompt: Implement ${SLUG} scoped to ${CURRENT_PHASE}"
    log "[DRY RUN] Agent log would be: ${AGENT_LOG}"
    break
  fi

  # Invoke selected agent engine scoped to the current phase.
  log "Agent log: ${AGENT_LOG}"
  set +e
  invoke_engine "$PROMPT" 2>&1 | tee "$AGENT_LOG" | tee -a "$LOG_FILE"
  EXIT_CODE=$?
  set -e

  if [[ "$EXIT_CODE" -ne 0 && "$ENGINE" == "cursor" && -n "$FALLBACK_CMD" ]]; then
    if grep -Eq "Workspace Trust Required|Failed to trust workspace" "$AGENT_LOG"; then
      log "Cursor headless trust blocked execution. Falling back to claude for this run."
      set +e
      "$FALLBACK_CMD" --verbose "$PROMPT" 2>&1 | tee -a "$AGENT_LOG" | tee -a "$LOG_FILE"
      EXIT_CODE=$?
      set -e
    fi
  fi

  if [[ "$EXIT_CODE" -ne 0 ]]; then
    log "Agent exited with code ${EXIT_CODE}."
  fi

  # Brief cooldown between runs
  log "Cooldown ${COOLDOWN}s..."
  sleep "$COOLDOWN"
done

# ---------------------------------------------------------------------------
# Post-loop: push and cleanup on success
# ---------------------------------------------------------------------------
log ""
log "=== Conductor finished ==="
print_progress

FINAL_STATUS=$(get_plan_status)
if [[ "$FINAL_STATUS" == "implemented" ]]; then
  # Push the feature branch
  log "Pushing branch ${BRANCH} to origin..."
  set +e
  git push -u origin "${BRANCH}" 2>&1 | tee -a "$LOG_FILE"
  PUSH_EXIT=$?
  set -e

  if [[ "$PUSH_EXIT" -eq 0 ]]; then
    log "Branch pushed successfully."

    # Cleanup the worktree
    log "Removing worktree at ${WORK_DIR}..."
    cd "$ORIGIN_DIR"
    set +e
    git worktree remove "$WORKTREE" 2>&1 | tee -a "$LOG_FILE"
    CLEANUP_EXIT=$?
    set -e

    if [[ "$CLEANUP_EXIT" -eq 0 ]]; then
      log "Worktree removed."
    else
      log "WARNING: Could not remove worktree. Clean up manually:"
      log "  git worktree remove ${WORKTREE}"
    fi
  else
    log "WARNING: Push failed. Branch is committed locally. Push manually:"
    log "  cd ${WORK_DIR} && git push -u origin ${BRANCH}"
  fi
else
  log "Plan not fully implemented (status: ${FINAL_STATUS}). Worktree preserved for next run."
fi

log "Conductor log: ${LOG_FILE}"
