# context-checkpoint — snapshot + session reset

Two triggers fire this skill:
1. **65% threshold (in-phase net):** when context reaches 65% (hook-injected %), **set a checkpoint flag** — do NOT interrupt immediately. Finish the current in-flight task to its next fan-in boundary, then save and end the session. Provenance: ralph checkpoint/phase-transition. ADR 0002.
2. **Unconditional gate reset (phase-boundary gates 1, 4, 5):** after a phase-boundary hard gate passes, checkpoint + end session REGARDLESS of context % — even at low %. No flag-and-wait: the gate is already a clean boundary, so checkpoint immediately. Gates 2/3 (per-slice, subagent-internal) do NOT trigger this. See ADR 0014.

## When to trigger

| State at 65% | Action |
|---|---|
| Between slices / at fan-in / idle | Checkpoint immediately |
| Mid-slice TDD loop | Finish current slice, checkpoint at fan-in |
| Mid-subagent (spawned, not returned) | Wait for subagent result, checkpoint after fan-in |
| Mid-user-message reply | Complete reply, then checkpoint |
| Session start / after bootstrap, already ≥ 65% | Checkpoint immediately — do NOT start gate work. Write handoff from prd.json + progress.txt and end session. |
| **Phase-boundary gate (1/4/5) just passed** | Checkpoint immediately, ignore % — the gate IS the safe stop. No flag-and-wait. |

Never abort mid-task. The 65% signal means "next safe stop, not right now." Exceptions (checkpoint is immediate): already ≥ 65% at session start (resumed from compaction mid-flow, no in-flight work); OR a phase-boundary gate just passed (unconditional reset, the gate is the boundary).

## What to write (three files — all at the Task root)
All three live at the **Task root**: `.e2e-engineering/tasks/<id>/` in multi-Task mode, `.e2e-engineering/` single-Task legacy. Write directly there — never to base then copy.
1. **prd.json** — already maintained live by the orchestrator. Ensure `status` of every story is current.
2. **progress.txt** — caveman:ultra. Ensure Story Log / Pending Amendments / Blocked are up to date.
3. **Handoff doc** — `<Task root>/handoff-<phase>-<timestamp>.md`, GENERATED from prd.json + progress.txt (not hand-written). caveman:ultra. Self-contained primer:
```
## Domain language   # compressed glossary summary (enough to work; full CONTEXT.md pulled on demand)
## Current state     # phase, taskType, which stories done/todo/blocked
## Worktrees         # `git worktree list` inventory: any in-flight slice worktree (story id → branch/path) so resume reconciles/tears down. Empty if none.
## Next action       # the very next concrete step
## Artifacts         # paths: prd.json, progress.txt, codebase-map?, research?, test-cases/
## Suggested skill   # which e2e-engineering sub-skill the fresh session should invoke
```

Before ending: a CLEAN checkpoint happens at a fan-in boundary, so no slice worktree should be mid-flight — confirm each merged worktree was removed. Record any worktree still on disk under `## Worktrees` so the resuming session's worktree-reconciliation step tears it down (prevents the abandoned-worktree leak across a crash/compaction).

## Then — checkpoint instruction + HARD STOP

After writing the three files:

1. Output this exact message to the user (first line states the trigger):
   ```
   <reason line> — checkpoint saved.
   Handoff: <Task root>/handoff-<phase>-<timestamp>.md

   Resume (manual):
     1. /clear    ← reset context
     2. /e2e-engineering    ← fresh session reads handoff automatically

   <e2e-checkpoint reason="<reason>" handoff="<Task root>/handoff-<phase>-<timestamp>.md" />
   ```
   - 65% trigger: reason line = `Context at 65%+`, signal `reason="threshold"`.
   - Gate reset: reason line = `GATE <N> passed`, signal `reason="gate-<N>"` (N = 1, 4, or 5).
   - Substitute the ACTUAL Task-root handoff path (`.e2e-engineering/tasks/<id>/handoff-…` multi-Task) in BOTH the Handoff line and the signal.
2. **HARD STOP** — process NO further messages in this session. Any further user message gets one reply: "Checkpoint saved — `/clear` then `/e2e-engineering` to resume."

> **Unattended automation (AFK wrapper):** `scripts/afk.ps1` detects `<e2e-checkpoint />` and restarts automatically. Run `.\scripts\afk.ps1` after gate 1 to enable AFK mode. Supports claude (default), opencode, codex via `-AI` param. (ADR 0005)

The fresh session runs [phase-transition](./phase-transition.md) bootstrap when `/e2e-engineering` is invoked.

## Red flags (stop)
- Checkpointing mid-task instead of waiting for fan-in boundary.
- Treating 65% as an immediate hard stop — it's a "prepare to stop" signal.
- Hand-writing the handoff instead of generating from state files (drift).
- Writing the handoff in prose (it's caveman:ultra).
- Continuing to process user messages after outputting the stop message.
- Telling user to start fresh without providing the exact handoff path.
