---
name: e2e-engineering
description: Interactive front door for the e2e-engineering flow — drives a Task from idea to an approved PRD (pre-implementation), launches headless implementation via /e2e-flight, and runs the human QA sign-off. Detects phase and task type, sequences sub-skills, plans the PRD with expert agents (UI designer / backend architect / DBA) so it is architecture-aware, and enforces the hard gates. Handles greenfield, feature, bugfix, and refactor on new or existing codebases, plus a one-time `adopt` mode for onboarding an in-progress project. Implementation itself runs in /e2e-flight (ADR 0022 — one Task per spawn, no loop, no context monitoring). Use when the user says "e2e-engineering", "e2e-eng", "ship-it", "ship it", "/e2e-engineering", "implement feature <name>", "write e2e for <feature>", "build this end to end", "run the full flow", or otherwise wants the complete engineering pipeline rather than a single isolated step.
---

# e2e-engineering — orchestrator

Master skill. Detect phase + task type, route mode, sequence sub-skills, drive the loop, enforce gates, checkpoint. Read CONTEXT.md (glossary) for any term below.

State lives under `.e2e-engineering/`. Multi-Task layout (the default for the front-door flow): `queue.json` at the root, and each Task's body under `tasks/<id>/` — `prd.json`, `progress.txt`, `codebase-map.md` (brownfield), `research.md`, `test-cases/*.md`, `qa-signoff.md`, handoff docs. Single-Task legacy layout (inline mode, no queue.json) keeps those files directly under `.e2e-engineering/`. Schemas: [queue.json](./schemas/queue.json.md), [prd.json](./schemas/prd.json.md), [progress.txt](./schemas/progress.txt.md), [qa-signoff](./schemas/qa-signoff.md), [codebase-map](./schemas/codebase-map.md).

**Task root (write artifacts THERE from the start — no base-then-copy).** Every per-Task artifact (prd.json, progress.txt, codebase-map.md, research.md, test-cases/, handoff, qa-signoff) lives at the **Task root**: `.e2e-engineering/tasks/<id>/` in multi-Task mode, `.e2e-engineering/` in single-Task legacy. The orchestrator establishes the Task root ONCE, at pre-impl start (Step 1), and EVERY sub-skill writes directly into it. Do NOT write to base `.e2e-engineering/` and copy into `tasks/<id>/` later — that leaves dirty duplicates at the root. Gate-1 queueing only appends the `queue.json` entry; the body is already in place. See ADR 0021.

This skill is the **interactive front door** (human-driven pre-implementation + batched QA sign-off). The automated implementation drain is [/e2e-flight](../e2e-flight/SKILL.md), launched at gate 1. See ADR 0016 (the split), 0017 (queue), 0018 (QA deferral).

Durable project docs live at repo ROOT (outlive any task): `CONTEXT.md` (glossary), [constitution](./constitution.md) (generic engineering standards), `ARCHITECTURE.md` (project-specific structure + conventions — the "right route" map; schema: [architecture](./schemas/architecture.md)). ARCHITECTURE.md is written ONLY in human phases (pre-impl seed + post-impl human-QA amend); the implementation loop reads it, never writes it. See ADR 0013.

**Sole-writer rule:** ONLY this orchestrator writes `prd.json` + `progress.txt`. Subagents return summaries; never touch shared state.

---

## Step 0 — route mode

- User invoked `/e2e-engineering adopt` → run [adopt](./adopt.md). One-time onboarding, not the per-task flow. Stop here.
- User invoked `/e2e-engineering qa`, OR `queue.json` has any Task `status:pending-qa` → run the **QA sign-off session** ([human-qa](./post-impl/human-qa.md) multi-Task mode): walk every pending-qa Task's [qa-signoff.md](./schemas/qa-signoff.md), sign off (→ `done`), route findings through [triage](./impl/triage.md) into new queue Tasks. Offer this first when pending-qa work exists. Stop here when done.
- Otherwise → per-feature flow below (spec → gate 1 → queue → launch flight).

## Step 1 — detect phase + task type

Determine where to enter (phase-adaptive — user may start mid-flow):

1. Does a `prd.json` exist at the relevant Task root (multi-Task: the in-progress Task under `tasks/<id>/`, found via queue.json; legacy: `.e2e-engineering/prd.json`)?
   - **No** → start Pre-implementation from the top.
   - **Yes** → read it. Any story `status != done` → resume Implementation. All `done` → Post-implementation.
2. Resuming a fresh session reads state, not a handoff (ADR 0022 — no checkpoint/handoff): `queue.json` (which Task) → `tasks/<id>/prd.json` (which slices done/todo/blocked) → `progress.txt` (tail for current state), then continue.
3. **Task type** (set/confirm `taskType` in prd.json): `greenfield` (new app/codebase), `feature` (add to existing), `bugfix`, `refactor`. Refactor runs the FULL flow — no lite path (ADR 0012).
4. **Greenfield vs brownfield**: greenfield skips map-codebase; brownfield (feature/bugfix/refactor on existing code) runs it.
5. **Establish the Task root NOW (new feature, front-door flow).** Derive `<id>` = kebab-case feature slug from the request, confirm it with the user, and `mkdir .e2e-engineering/tasks/<id>/`. This is the Task root for the whole pre-impl sequence: map-codebase, grill-with-docs, research, to-prd all write their artifacts INTO it — never to base `.e2e-engineering/`. Set the id before the first artifact is produced (map-codebase is the first writer on brownfield). Single-Task legacy (inline, no queue intended) keeps the base root.

Confirm the detected entry with the user in one line before proceeding.

---

## Pre-implementation phase

Sequence (bracketed = conditional): **[map-codebase? (brownfield)] → grill-with-docs → [research?] → [prototype?] → to-prd**. (map-codebase-first + one unified grill: ADR 0019.)

1. [map-codebase](./pre-impl/map-codebase.md) — brownfield only (gated by `taskType`, NOT by grilling). Runs FIRST so grilling walks in familiar with existing functionality. Produces `codebase-map.md` (5 sections, scoped). Section 5 refactor candidates are WALLED. Greenfield skips it.
2. [grill-with-docs](./pre-impl/grill-with-docs.md) — the single doc-aware brainstorm loop (absorbs old grill-me). Reads CONTEXT.md glossary + ARCHITECTURE.md + (brownfield) codebase-map BEFORE asking, so questions are informed by what already exists; reconciles language inline; gates whether research / prototype fire. Loops until user approves direction. Because language is settled here, Implementation skips straight to to-issues (no second grill).
3. [research](./pre-impl/research.md) — only if task leans on external APIs / unfamiliar libs. Produces `research.md` (rots).
4. [prototype](./pre-impl/prototype.md) — only if taste/UX/state-machine uncertainty needs concrete feedback. Throwaway. ui-branch or logic-branch.
5. [to-prd](./pre-impl/to-prd.md) — convert grill-with-docs notes into the formal PRD → writes `prd.json`. Owns its own interview step (no double-interview). Refactor-shaped stories allowed. Captures testing-decisions that become test-cases.
   - **Plan with expert agents → architecture-aware PRD.** Before finalizing, consult the expert reviewer agents as advisors against `ARCHITECTURE.md` + `constitution`: [backend-architect](../../agents/backend-architect.md) (layering/ownership/integration), [dba](../../agents/dba.md) (schema/migration shape), [ui-designer](../../agents/ui-designer.md) (component reuse/design-system). They surface the project's standards + ownership rules the PRD must respect (which seams to extend, which components to reuse) so the spec is right BEFORE gate 1 — the same agents later review the built slices in [/e2e-flight](../e2e-flight/SKILL.md). This is the interactive, human-reviewed half; flight's expert-review wave is the headless half.

**HARD GATE 1 — PRD approved → implementation.** Present the PRD; require explicit human consent before any code. Do not proceed on silence. This is a STOP: emit the gate as a red-flags line and WAIT. Never infer approval from "looks good" on an earlier draft — consent is on the final PRD.

**→ On consent: queue the Task, then batch or launch.** Implementation is automated by [/e2e-flight](../e2e-flight/SKILL.md), not run inline (ADR 0016). At gate-1 approve, run these steps IN ORDER — each is a human chokepoint, none may be auto-resolved:

1. **Task body is already in place** at `.e2e-engineering/tasks/<id>/` — pre-impl wrote prd.json + every artifact there directly (Step 1 set the Task root). Just verify it's complete; do NOT copy/move anything from base `.e2e-engineering/` (there should be nothing there to copy). `<id>` was fixed at Step 1.
2. **Append to [queue.json](./schemas/queue.json.md)** — entry `{ id, title, priority, dependsOn, status:todo, selected:false, parentTask:null }`. Ask the human for `priority` and any cross-Task `dependsOn` (camelCase — distinct from story-level `depends_on`). This skill is the queue's CREATE writer; flight only flips `status`. **New Tasks are born `selected:false`** — selection happens only at the explicit checkbox in step 3, never by default.
3. **Batch or launch?** Ask: *"Spec another feature, or launch flight now?"* — and STOP for the answer.
   - **Another** → loop back to Pre-implementation for the next feature — establish a NEW Task root (`tasks/<new-id>/`) first, then map-codebase? → grill-with-docs …. The queue grows. State this clearly so the human can stack a backlog before launching.
   - **Launch** → **Run-selection checkbox (HARD interactive STOP).** Present every `status:todo` Task with priority + dependsOn as an unchecked checklist and ASK the human which to drain THIS flight. **Do NOT pre-check all, do NOT assume "all", do NOT launch until the human returns a checked subset.** Only auto-additions allowed: an unmet `dependsOn` of a checked Task (warn: "billing-export needs auth-login — adding it"). Set `selected:true` ONLY on the human-chosen set (+ pulled-in deps). If the human checks nothing, do not launch.
4. **Invoke [/e2e-flight](../e2e-flight/SKILL.md)** to start the first selected Task. **Flight implements ONE Task per invocation, then exits — there is no driver loop (ADR 0022).** To drain several selected Tasks, `/e2e-flight` is re-invoked once per Task (by the human, or a future thin re-invoker). Tell the human: "Flight will implement one Task per `/e2e-flight` run. I've kicked off `<id>`; re-run `/e2e-flight` for each remaining selected Task, then run `/e2e-engineering` to QA-sign-off. Watch progress by tailing `tasks/<id>/progress.txt`."

Each `/e2e-flight` invocation is a fresh context: pre-impl grilling never contaminates implementation because implementation runs in separate spawns.

---

## Implementation phase

Entry: PRD approved (gate 1 passed). **Implementation runs in [/e2e-flight](../e2e-flight/SKILL.md)** — one Task per spawn, headless, no loop, no context monitoring (ADR 0022). Flight owns the canonical per-spawn process (fan-out impl wave → expert-review wave → merge → self-review → defer QA); see its SKILL.md. The sub-steps below ([to-issues](./impl/to-issues.md), [tdd](./impl/tdd.md)) are shared building blocks flight uses. Single-Task legacy mode may still run a simplified inline version here — but with NO 65%/gate-reset checkpoint machinery (removed everywhere; ADR 0022 supersedes 0002/0014).

1. [to-issues](./impl/to-issues.md) — split PRD into vertical slices, emit the `depends_on` DAG (tracer→schema→logic→api→ui as edges), author test-case `.md` docs upfront and attach `testCases[]` per story. Reads `ARCHITECTURE.md` (if present) to pin each story's `integration` decision (which existing owner/seam it extends) and to add `depends_on` edges between stories that would write the same file. Output is born `ready-for-agent` (skips triage).
2. [triage](./impl/triage.md) — only for EXTERNALLY-sourced work (bug reports, feature requests) and walled refactor candidates. Forward-flow slices skip it.

(Language was already reconciled in pre-impl grill-with-docs — Implementation does NOT re-grill. Per-slice gap-finding is the [slice gap-check](./impl/tdd.md)'s job.)

### The loop (skill-driven, in-session — ADR 0005)

**Worktree reconciliation (FIRST, every loop entry — incl. fresh-session resume).** Run `git worktree list` and reconcile against prd.json before computing the ready set. A worktree from a prior (interrupted/checkpointed) session may be orphaned:
- Worktree whose story is `done` → already merged; remove it (`ExitWorktree` / `git worktree remove`).
- Worktree whose story is `todo`/`in-progress` → an abandoned in-flight slice. Tear it down (discard the un-merged branch only if it has no committed work; if it has commits, note them and remove the worktree — the story re-dispatches clean). Reset the story to `todo` so it re-enters the ready set.
- Story marked in-flight in prd.json but NO worktree on disk (crash mid-fan-out) → reset to `todo`.
This is what prevents the abandoned-worktree leak: NO worktree outlives the slice that owns it.

Repeat until COMPLETE (all stories `status: done`):

1. **Compute ready set** — stories whose `depends_on` are all `done` AND own `status: todo`.
2. **Fan-out** — dispatch each ready story to its OWN git worktree + subagent (use EnterWorktree). Inject [constitution](./constitution.md) + the story (incl. its `integration` decision) + its testCases into each subagent. On brownfield (or when ARCHITECTURE.md exists), ALSO inject the story's SCOPED slice of ARCHITECTURE.md — its layer's naming + the ownership rules touching its blast radius + relevant anti-patterns — NOT the whole doc (token discipline). Subagent runs [tdd](./impl/tdd.md): gap-check → red-green-refactor → automate its FEATURE e2e → return SUMMARY ONLY.
   - **HARD GATE 2 — TDD red before green.** Each subagent must write a failing test before production code. Enforced inside tdd.md.
   - **HARD GATE 3 — debug escalation.** Subagent fails 3 fix attempts → orchestrator re-dispatches ONCE with [systematic-debugging](./impl/systematic-debugging.md) (4-phase root-cause). Still red → mark story `blocked`, append `## Blocked` in progress.txt, keep draining the ready set. Escalate to human ONLY on stall (no ready work left, or every remaining story depends on a blocked one). Emit `<e2e-stall reason="all-stories-blocked" />` before escalating.
3. **Fan-in (orchestrator, serial — sole writer):** for each returned summary, run the per-slice review's two ordered stages, then the merge-readiness check, then merge. The orchestrator runs all of this inline — this is the per-slice review LAYER; the fresh-context full-diff cross-slice audit stays the separate post-impl [review](./post-impl/review.md). Provenance: superpowers subagent-driven-development (two-stage review) + finishing-a-development-branch (readiness check).
   - **Stage 1 — spec-compliance check.** Does the slice satisfy the story's acceptanceCriteria EXACTLY — no missing behavior, no extra behavior? Verdict `✅ spec-compliant` or `❌ issues found`. Issues → bounce findings back to the slice subagent, re-run stage 1 after the fix. Do NOT advance to stage 2 until spec-compliant.
   - **Stage 2 — quality check.** Check the slice against the [constitution](./constitution.md) AND (when ARCHITECTURE.md exists) its ownership/naming/integration rules — caught here: a new class at a URL an existing class owns, a file that duplicates an existing component name, a second API-client key for one endpoint, a naming-convention break. Triage findings Critical / Important / Minor. Critical or Important → bounce back, re-run stage 2 after the fix. Minor → note, don't block. Do NOT advance to merge-readiness until stage 2 clears.
   - **Bounce ceiling (token-runaway guard).** A stage-1 or stage-2 bounce-back is capped at **3 round-trips for that stage** (mirrors gate 3). Still failing the same stage after 3 → STOP bouncing: mark the story `blocked`, append `## Blocked` (with the unmet finding) in progress.txt, tear down its worktree, and keep draining the ready set. An un-capped bounce loop is exactly how a headless flight burns tokens silently.
   - **Merge-readiness check.** Worktree has no uncommitted changes; the slice's feature E2E + affected tests pass; branch is ahead of baseBranch. Any fail → bounce back (under the same 3-round-trip ceiling), do not merge.
   - Merge the worktree branch into baseBranch. Resolve conflicts (never discard work).
   - **Remove the worktree** (`ExitWorktree` / `git worktree remove`) immediately after a successful merge — the worktree's life ends with the merge. Leaving it is the abandoned-worktree bug.
   - Write `status: done` in prd.json.
   - Append a `## Story Log` line to progress.txt. Stage durable learnings under `## Pending Amendments` (constitution OR ARCHITECTURE.md amendments — both ride this chain).
4. Loop. (No checkpoint / context monitoring — ADR 0022. In flight, fan-out keeps the orchestrator chain small; this legacy inline loop just continues.)

### After COMPLETE

No context monitoring, no checkpoint, no gate reset (ADR 0022 — removed everywhere). Proceed straight to the gate-4/5 steps. In flight these are the Step-4 e2e QA phase.

4. [e2e-loop](./impl/e2e-loop.md) — author the REGRESSION (cross-slice) test-case docs now that the whole feature exists.
   - **GATE 4 — full E2E suite green — STUBBED, pending automation (not deleted).** E2E journey automation is a `TODO` placeholder right now; only the TC docs are authored. When automation lands, this gate runs the full suite again.

5. [verification](./impl/verification.md) — gate 5.
   - **GATE 5 — verification-before-completion — STUBBED, pending automation (not deleted).** Interim: self-review ticks the PRD acceptance criteria against the code; no live `/run`+`/verify` exercise while automation is stubbed + headless. The human-QA checklist is the interim verification net.

---

## Post-implementation phase

Entry: gate 5 passed.

1. [review](./post-impl/review.md) — fresh-context, full-diff, cross-slice audit by a clean reviewer. Findings ranked by severity. **In multi-Task mode flight runs this headless per Task**, before parking QA.
2. [human-qa](./post-impl/human-qa.md) — walk the Manual test-case set (the disposition `Manual` cases). Single human-approval chokepoint: in ONE touch the human approves QA sign-off AND batched `## Pending Amendments` → promote to [constitution](./constitution.md) (bump version) or drop. **In multi-Task mode this is the batched QA sign-off session** (Step 0): flight deferred it per Task to `pending-qa` + qa-signoff.md; the human clears all pending-qa Tasks in one pass and routes findings → [triage](./impl/triage.md) → new queue Tasks (ADR 0018).

Task close (single-Task): extract durable learnings, ensure amendments resolved, progress.txt resets on the NEXT task. Emit `<e2e-complete stories="N" />`. Multi-Task: flight emits `<e2e-complete>` when the selected queue is drained (all selected pending-qa/done/blocked); the QA sign-off session then flips pending-qa → done.

---

## Gates summary

| # | Gate | Type | Where |
|---|------|------|-------|
| 1 | PRD approved → impl | HARD | end of pre-impl |
| 2 | TDD red before green | HARD | in tdd.md per slice |
| 3 | debug escalation (3 strikes → systematic-debugging → blocked → stall→human) | HARD | in loop |
| 4 | E2E suite green → post-impl | STUBBED (pending automation; not deleted) | e2e-loop |
| 5 | verify-before-completion | STUBBED (pending automation; interim: self-review + human checklist) | verification |
| — | coverage / lint / style | SOFT | overridable WITH logged justification; silent skip not allowed |

Hard gates need explicit human consent and surface as a red-flags line in their sub-skill. Never rationalize past a hard gate.

---

## Cross-cutting

- **No context monitoring (ADR 0022).** No 65% checkpoint, no unconditional gate reset, no handoff/respawn. The token fix is forced fan-out (sub-agents hold the heavy churn, return summaries), not checkpointing. Supersedes ADR 0002 (hook-based context monitoring) + ADR 0014 (gate-boundary resets). The 65% hook is disabled.
- **Resume via state, not handoff.** A fresh session resumes by reading `queue.json` (which Task) → `tasks/<id>/prd.json` (which slices done/todo/blocked) → `progress.txt` (tail for current state). No handoff doc.
- **ARCHITECTURE.md governance** — durable project-architecture map (schema: [architecture](./schemas/architecture.md)). Written ONLY in human phases: seeded/drafted in pre-impl (adopt, map-codebase, to-prd — human-reviewed) and amended at the post-impl human-QA gate. The automated implementation loop is READ-ONLY for it (to-issues pins from it, fan-out injects a scoped slice, quality-check checks against it). A subagent that spots architectural drift PROPOSES it in its summary; the orchestrator stages it as a `## Pending Amendment` — never edits ARCHITECTURE.md mid-loop. Same blast radius as the constitution (it shapes every future subagent), so same human-gated governance. See ADR 0013.
- **Writing style:** generated state artifacts (progress.txt, handoff) = caveman:ultra. User-facing conversation = caveman:full. Code, commits, PRs = normal prose.
