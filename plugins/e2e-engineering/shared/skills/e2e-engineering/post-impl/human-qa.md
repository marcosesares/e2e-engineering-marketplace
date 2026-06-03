# human-qa — Manual test script + amendment approval (single chokepoint)

The single human-approval chokepoint of the whole flow. In ONE touch the human (1) walks the Manual test-case script and signs off QA, AND (2) approves/drops the batched constitution amendments. Provenance: mattpocock + qa dispositions.

## Two modes
- **Single-Task** (no `queue.json`): run the steps below once for the current task.
- **Multi-Task QA sign-off session** (flight drained a [Task queue](../schemas/queue.json.md)): /e2e-flight deferred human-QA per Task, leaving each at `status:pending-qa` with a [qa-signoff.md](../schemas/qa-signoff.md). Walk ALL `pending-qa` Tasks here in ONE pass (priority order). For each Task, open its `tasks/<id>/qa-signoff.md` and run the steps below; then flip queue `status: pending-qa → done`. See ADR 0018.

## What to do (per Task)
1. **Manual script** — present the test-cases with disposition **Manual** (those with no E2E). For each: preconditions, steps, expected. The human walks them and records pass/fail. (Multi-Task: these are pre-listed in the Task's qa-signoff.md.)
2. **Pending Amendments** — present the `## Pending Amendments` staged in progress.txt (durable learnings extracted across the task, incl. architecture drift subagents proposed mid-loop). For each, the human routes it: **promote → [constitution](../constitution.md)** if generic (bump version + changelog), **promote → ARCHITECTURE.md** if project-specific structure/ownership/naming/convention, or **drop**. (This is the one human-write phase for ARCHITECTURE.md besides pre-impl seeding.)
3. **Findings → issues** — log any QA finding in the Task's qa-signoff.md `## Findings`, then route each through [triage](../impl/triage.md) into a NEW queue Task: a **bug** → linked bugfix Task (`parentTask=<this id>`, `status:todo`, unselected) — the built Task STILL goes `done`, not reopened (it passed automated gates; the bug is new scope); a **new idea** → feature Task (`status:todo`, unselected). Findings re-enter the queue for a future flight (ADR 0018).
4. Record QA sign-off (set qa-signoff.md `Status: APPROVED`, queue `status: done`).

## Why batched here (not task-by-task)
Pattern promotion is batched at this gate so the human never approves patterns one-task-at-a-time. progress.txt stays per-task scratch and resets on the next task; durable learnings survive only if promoted to the constitution here.

## Task close
- QA signed off + amendments resolved (promoted or dropped) → task DONE.
- progress.txt resets when the NEXT task begins (append-only only WITHIN a task).

## Red flags (stop)
- Auto-promoting amendments without human approval (wrong rule then injected into every future subagent — true for constitution AND ARCHITECTURE.md).
- Approving QA per-slice/per-task instead of at this single chokepoint.
- Carrying Pending Amendments forward unresolved.
