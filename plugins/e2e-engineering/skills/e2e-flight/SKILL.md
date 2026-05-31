---
name: e2e-flight
description: Headless implementation worker for the e2e-engineering flow. Implements exactly ONE Task from the queue then exits — no external loop, no context monitoring. Within the spawn it IS the orchestrator: fans out each slice to a sub-agent in its own worktree (impl wave), runs an expert-review wave before merge, then self-reviews and parks human-QA. Headless counterpart to the interactive front door /e2e-engineering. Use when the user says "e2e-flight", "/e2e-flight", "flight", "drain the queue", "run the flight loop", or "implement the selected tasks".
---

# e2e-flight — one-Task implementation worker

Sibling to [/e2e-engineering](../e2e-engineering/SKILL.md) (interactive + human: pre-impl + QA sign-off). This is headless implementation. Read CONTEXT.md for any term. Decision record: [ADR 0022](../../../docs/adr/0022-flight-one-task-per-spawn-no-loop-no-checkpoint.md). Process spec: [prototype/e2e-flight-process/design.md](../../../prototype/e2e-flight-process/design.md).

**One Task per invocation, then exit.** No ralph driver loop, no respawn, no 65%/gate context monitoring. Re-invoke `/e2e-flight` to take the next Task. A Task finishes in one spawn or is left resumable via `queue.json`/`prd.json` status.

**The token rule (why this skill exists in this shape).** The blowup was fan-out *not firing* → 126 calls inline → 227-turn O(N²) chain. So fan-out is FORCED (Step 0) and inline slice-impl is a hard STOP (Step 3). Sub-agents hold the heavy tool calls and return summaries — that is what keeps this orchestrator's context small WITHOUT any checkpoint.

---

## Step 0 — bootstrap + forcing mechanism (FIRST, always)

1. **Load the dispatch tools.** `ToolSearch` → load `Agent` and `EnterWorktree`. If either cannot be loaded, fan-out is impossible → emit `<e2e-stall reason="fanout-unavailable" />` and EXIT. NEVER fall back to doing slice work inline.
2. No driver, no lock, no context monitoring. Do not write handoff docs, do not checkpoint, do not respawn.
3. **Orchestrator output = caveman-ultra, essential only** (token discipline — your own chain is the cost).

---

## Step 1 — pick ONE Task

Read `.e2e-engineering/queue.json` (offset/limit — only what you need).

- The user named a Task → take it.
- Else pick: `status:todo` AND every `dependsOn` in {done, pending-qa}, **highest priority** first. Flip it to `in-progress`.
- No pickable Task → emit `<e2e-complete />` and EXIT.

The Task root is `.e2e-engineering/tasks/<id>/`.

---

## Step 2 — reconcile + read state

Read (offset/limit, only needed sections): `tasks/<id>/prd.json` (the slice DAG) + `tasks/<id>/progress.txt`.

- **2.1 — structure missing/invalid** (no prd.json, no DAG, no test-cases): do NOT improvise a plan. Tell the user to plan it via `/e2e-engineering`, then EXIT.
- **2.2 — prior in-progress/stall mess** (worktrees on disk, slices marked in-flight with no commit): propose analysis + reconciliation to the user and EXIT — do not blindly resume a dirty state.
- **Clean reconcile** (within a clean resume): a slice marked in-flight with no commit → reset to `todo`. Then proceed.

---

## Step 3 — per-slice loop (flight IS the orchestrator)

Sole writer: only this orchestrator writes `prd.json` + `progress.txt`. Sub-agents return summaries.

Repeat until the DAG is drained (every slice `done` or `blocked`):

1. **Compute ready set** — slices whose `depends_on` are all `done` AND own `status: todo`.
2. **Fan-out impl wave** — dispatch each ready slice to its OWN git worktree + sub-agent (`EnterWorktree` + `Agent`). Run [tdd](../e2e-engineering/impl/tdd.md). Parallel ONLY across disjoint file sets (same-file slices were serialized by `depends_on` in to-issues). Inject: [constitution](../e2e-engineering/constitution.md) + the slice (acceptanceCriteria, sliceType, `integration` decision) + its testCases + (brownfield) a SCOPED slice of `ARCHITECTURE.md`.
   - **GATE 2 (hard)** — failing test before production code (inside tdd).
   - **GATE 3 (hard)** — 3 failed fixes → re-dispatch ONCE with [systematic-debugging](../e2e-engineering/impl/systematic-debugging.md); still red → mark slice `blocked`, keep draining.
   - **DO NOT do slice-impl inline.** Orchestrator writing slice production code = hard red-flag STOP.
3. **Expert-review wave (in the worktree, BEFORE merge).** Once a slice is green, dispatch role reviewer agents — picked by `sliceType` (token discipline, not all on every slice):
   - schema/db → [dba](../../agents/dba.md) + [backend-architect](../../agents/backend-architect.md)
   - api/logic → [backend-architect](../../agents/backend-architect.md) (+ [senior-qa](../../agents/senior-qa.md))
   - ui → [ui-designer](../../agents/ui-designer.md) + frontend lens of [backend-architect](../../agents/backend-architect.md)
   - every slice → [senior-qa](../../agents/senior-qa.md) (AC coverage)

   Each reviews the slice vs PRD + [constitution](../e2e-engineering/constitution.md) + (brownfield) the ARCHITECTURE slice, returns findings **Critical / Important / Minor**. Critical or Important → bounce to the impl sub-agent, re-review after fix. **Bounce cap = 3 round-trips** (mirrors gate 3) → still failing → mark slice `blocked`, tear down worktree, keep draining. Minor → note, don't block.
4. **lint + compile** — orchestrator COMMANDS (not agents). Run the project's lint + build/typecheck; reconcile failures in the branch before merge.
5. **Merge** the slice branch → Task branch (resolve conflicts, never discard work). Remove the worktree immediately (`ExitWorktree`) — its life ends with the merge.
6. **Record** — set slice `status: done` in prd.json; append the sub-agent summary to `progress.txt` (caveman-ultra, status-headed line). This is the fan-out ledger.

---

## Step 4 — e2e QA phase (task-level, after the DAG is drained)

1. **Author e2e TC docs** — write the regression/cross-slice e2e test-cases: Steps, validations, and the automation backlog. `tasks/<id>/test-cases/` (caveman-ultra).
2. **Automate e2e TCs** — **TODO placeholder.** [GATE 4 — full E2E suite green — STUBBED, pending automation. Not deleted.]
3. **green → refactor** — **TODO placeholder.** [GATE 5 — live verification — STUBBED, pending automation. Not deleted.]

---

## Step 5 — self-review (whole task)

Review the assembled Task against its acceptanceCriteria + [constitution](../e2e-engineering/constitution.md).

- **5.1 pass** → mark the TASK `done` in `queue.json` + finalize `progress.txt`.
- **5.2 fail** → **scoped** `git restore` of UNCOMMITTED leftovers ONLY (never wipe already-merged slices) + mark the TASK `blocked` in `queue.json` with the unmet finding. Committed slices stay; the finding rides to human-QA.

---

## Step 6 — defer human-QA

Write `tasks/<id>/qa-signoff.md` ([schema](../e2e-engineering/schemas/qa-signoff.md), caveman-ultra): manual test cases to walk, auto-verified ACs to eyeball, staged pending amendments. Do NOT run [human-qa](../e2e-engineering/post-impl/human-qa.md) — it needs a human. `/e2e-engineering` owns the human review + replanning.

---

## Step 7 — exit

Emit exactly one plain human-facing status as the last line: `<e2e-complete />` (queue has no more pickable Task), `<e2e-task-done id="<id>" />` (this Task done/blocked, more remain), or `<e2e-stall reason="..." />` (needs a human). No respawn — the human re-invokes for the next Task.

---

## Token hygiene (every spawn)
- caveman-ultra for prose artifacts (`progress.txt`, `qa-signoff.md`, test-case `.md`). JSON (`prd.json`/`queue.json`) stays schema-bound.
- offset/limit on all reads — only the sections you need; never re-read a whole file.
- `progress.txt` = single append-only record; status-headed entries; tail for current state.

## Red flags (stop)
- Doing slice-impl inline instead of dispatching a sub-agent (the blowup cause — Step 0 forces fan-out; inline = STOP).
- Falling back to inline work when `Agent`/`EnterWorktree` won't load (stall + exit instead).
- Re-introducing a loop / checkpoint / handoff / 65% monitoring (gone by design — ADR 0022).
- Running [human-qa](../e2e-engineering/post-impl/human-qa.md) headless (needs a human — write qa-signoff.md instead).
- `git restore` wiping already-merged slices on a late failure (scope it to uncommitted only).
- Marking a Task `done` when self-review failed (mark `blocked`).
- Touching another Task's `tasks/<id>/` state.
