#!/usr/bin/env bash
#
# AFK driver — unattended e2e-flight Task-queue drain (POSIX port of afk.ps1).
# Loops fresh /e2e-flight sessions. Each spawn = fresh context (external /clear).
#
# Drives the Task queue at .e2e-engineering/queue.json one Task-step per spawn.
# WARNING: runs with --dangerously-skip-permissions. All tool calls execute
# without approval. Only reachable post-gate-1 (flight needs a selected queue).
#
# Sets E2E_DRIVER=1 so /e2e-flight enters worker mode (Step 0 guard). Catches
# four signals on each session tail:
#   <e2e-complete>   -> success, exit 0
#   <e2e-stall>      -> human needed, exit 1
#   <e2e-task-done>  -> next Task, respawn
#   <e2e-checkpoint> -> resume same Task, respawn
#
# Usage:
#   ./afk.sh                    # claude default, /e2e-flight
#   AI=opencode ./afk.sh        # opencode preset
#   AI=codex ./afk.sh           # codex preset
#   SKILL=/other ./afk.sh       # different skill
#   MAX_SESSIONS=80 ./afk.sh    # raise ceiling
#   CMD="custom cmd" ./afk.sh   # custom override

set -euo pipefail

AI="${AI:-claude}"
SKILL="${SKILL:-/e2e-flight}"
MAX_SESSIONS="${MAX_SESSIONS:-50}"
# Runaway guard: max consecutive checkpoints on the SAME Task with no task-done.
MAX_STUCK_CHECKPOINTS="${MAX_STUCK_CHECKPOINTS:-6}"
CMD="${CMD:-}"

# State dir holds queue.json, flight.log, flight.lock, flight-status.md.
if [ -z "${STATE_DIR:-}" ]; then
  if [ -d ".e2e-engineering" ]; then STATE_DIR=".e2e-engineering"; else STATE_DIR="$(cd "$(dirname "$0")" && pwd)"; fi
fi
LOG_FILE="$STATE_DIR/flight.log"
LOCK_FILE="$STATE_DIR/flight.lock"

# Duplicate-driver guard: refuse to start if a live driver already owns the lock.
if [ -f "$LOCK_FILE" ]; then
  existing_pid="$(head -n1 "$LOCK_FILE" 2>/dev/null || true)"
  if [ -n "$existing_pid" ] && kill -0 "$existing_pid" 2>/dev/null; then
    echo "[afk] Driver already running (PID $existing_pid). Not starting a second. Watch $LOG_FILE." >&2
    exit 0
  fi
  rm -f "$LOCK_FILE"   # stale lock
fi
echo "$$" > "$LOCK_FILE"
cleanup() { rm -f "$LOCK_FILE"; }
trap cleanup EXIT

case "$AI" in
  claude)   PRESET="claude --print --dangerously-skip-permissions \"$SKILL\"" ;;
  opencode) PRESET="opencode -p --dangerously-skip-permissions \"$SKILL\"" ;;
  codex)    PRESET="codex exec --dangerously-bypass-approvals-and-sandbox \"$SKILL\"" ;;
  *) echo "Unknown AI preset: $AI" >&2; exit 64 ;;
esac

[ -n "$CMD" ] || CMD="$PRESET"

# Worker mode for /e2e-flight Step 0 guard.
export E2E_DRIVER=1

session=0
stuck_checkpoints=0   # consecutive checkpoints with no intervening task-done
start_ts=$(date +%s)

log() { printf '[afk %s] %s\n' "$(date +%H:%M:%S)" "$1" | tee -a "$LOG_FILE"; }

log "Starting. AI=$AI MAX_SESSIONS=$MAX_SESSIONS SKILL=$SKILL"
log "Command: $CMD"
log "Console mirrored to $LOG_FILE · current state in $STATE_DIR/flight-status.md"

while [ "$session" -lt "$MAX_SESSIONS" ]; do
  session=$((session + 1))
  log "Session $session/$MAX_SESSIONS"

  # Capture full output while streaming it (to console + log); keep tail for matching.
  out="$(eval "$CMD" 2>&1 | tee -a "$LOG_FILE" | tee /dev/stderr)"
  tail="$(printf '%s\n' "$out" | tail -n 30)"

  # Order matters: complete/stall terminal; task-done/checkpoint respawn.
  if printf '%s' "$tail" | grep -Eq '<e2e-complete[^/]*/>'; then
    elapsed=$(( $(date +%s) - start_ts ))
    log "COMPLETE — queue drained after $session session(s) [${elapsed}s]"
    exit 0
  fi

  if printf '%s' "$tail" | grep -Eq '<e2e-stall[[:space:]]+reason="[^"]*"'; then
    reason="$(printf '%s' "$tail" | grep -oE 'reason="[^"]*"' | head -1)"
    log "STALL: $reason. Human input required."
    log "Resolve then resume: ./.e2e-engineering/afk.sh"
    exit 1
  fi

  if printf '%s' "$tail" | grep -Eq '<e2e-task-done[[:space:]]+id="[^"]*"'; then
    id="$(printf '%s' "$tail" | grep -oE 'id="[^"]*"' | head -1)"
    log "Task done: $id. Next Task -> session $((session + 1))..."
    stuck_checkpoints=0   # real forward progress — reset the runaway counter
    continue
  fi

  if printf '%s' "$tail" | grep -Eq '<e2e-checkpoint[[:space:]]+handoff="[^"]*"'; then
    stuck_checkpoints=$((stuck_checkpoints + 1))
    log "Checkpoint ($stuck_checkpoints/$MAX_STUCK_CHECKPOINTS). Resuming same Task..."
    if [ "$stuck_checkpoints" -ge "$MAX_STUCK_CHECKPOINTS" ]; then
      log "RUNAWAY: $MAX_STUCK_CHECKPOINTS consecutive checkpoints, no Task completed. Stopping to avoid token burn."
      log "Inspect $STATE_DIR/flight-status.md + handoff, then resume manually."
      exit 4
    fi
    continue
  fi

  log "No signal detected in session $session. Review output."
  printf '%s\n' "$out" | tail -n 5 | sed 's/^/  /'
  exit 2
done

log "Safety ceiling reached ($MAX_SESSIONS sessions)."
exit 3
