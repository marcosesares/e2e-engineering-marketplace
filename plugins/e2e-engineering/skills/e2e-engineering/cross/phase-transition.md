# phase-transition — fresh-session bootstrap

Sequence a restarted session MUST follow before any work. Applies to both phase boundaries AND mid-phase context restarts (after a 65% checkpoint). Provenance: ralph stateless-fresh-agent. ADR 0004.

## Step 0 — Task-level read (multi-Task / flight only)
If `.e2e-engineering/queue.json` exists (multi-Task mode, [/e2e-flight](../../e2e-flight/SKILL.md)), read it FIRST to learn WHICH Task: the single `status:in-progress` Task (resume) or the next selected `todo` Task (pick + flip in-progress). Its dir is `.e2e-engineering/tasks/<id>/` — root the read order below there. Single-Task mode (no queue.json) reads directly from `.e2e-engineering/`. See ADR 0017, [queue.json](../schemas/queue.json.md).

## Bootstrap read order (strict)
1. **Handoff doc** (`<Task root>/handoff-*.md`, latest — Step 0 fixed the Task root: `.e2e-engineering/tasks/<id>/` multi-Task, `.e2e-engineering/` legacy) — FIRST. Self-contained primer: domain language, current state, next action, artifacts, suggested skill.
2. **prd.json** — structured state: story statuses, DAG, taskType, baseBranch.
3. **progress.txt** — learnings, Pending Amendments, Blocked.
4. **Invoke the suggested skill** from the handoff.

Do NOT read CONTEXT.md first — the handoff already carries a language summary; pull the full glossary on demand only if a term is unclear.

## Resuming a blocked story
Read `## Blocked` in progress.txt. Have its `depends_on` changed (a dep now `done`) since it was blocked? → re-dispatch ONCE. Else still stalled → escalate to human. No blind cross-session retry.

## Resuming the loop
FIRST run **worktree reconciliation** (SKILL.md Implementation loop): `git worktree list` vs prd.json — remove worktrees of `done` stories, tear down orphaned in-flight worktrees (cross-check the handoff `## Worktrees` inventory), reset their stories to `todo`. A prior session that checkpointed or crashed mid-fan-out leaves worktrees; reconciling here is what stops them accumulating. THEN recompute the ready set from prd.json (deps `done` + own `status: todo`) and continue fan-out/fan-in. The orchestrator remains sole writer.

## Red flags (stop)
- Reading CONTEXT.md or raw code before the handoff (wastes fresh context; handoff is the primer).
- Re-running completed work because state wasn't read first.
- Blind-retrying a blocked story whose deps haven't changed.
