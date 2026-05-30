---
name: e2e-engineering
description: Master engineering orchestrator — drives a Task from idea to passing E2E across pre-implementation, implementation, and post-implementation phases. Detects phase and task type, sequences sub-skills, runs the vertical-slice TDD loop with parallel subagents, enforces five hard gates, and checkpoints at 65% context. Handles greenfield, feature, bugfix, and refactor on new or existing codebases, plus a one-time `adopt` mode for onboarding an in-progress project. Use when the user says "e2e-engineering", "e2e-eng", "ship-it", "ship it", "/e2e-engineering", "implement feature <name>", "write e2e for <feature>", "build this end to end", "run the full flow", or otherwise wants the complete engineering pipeline rather than a single isolated step.
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
2. If a handoff doc exists at that Task root (`handoff-*.md`), this is a fresh-session resume → run [phase-transition](./cross/phase-transition.md) bootstrap FIRST (read handoff → prd.json → progress.txt → invoke suggested skill).
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

**HARD GATE 1 — PRD approved → implementation.** Present the PRD; require explicit human consent before any code. Do not proceed on silence. This is a STOP: emit the gate as a red-flags line and WAIT. Never infer approval from "looks good" on an earlier draft — consent is on the final PRD.

**→ On consent: queue the Task, then batch or launch.** Implementation is automated by [/e2e-flight](../e2e-flight/SKILL.md), not run inline (ADR 0016). At gate-1 approve, run these steps IN ORDER — each is a human chokepoint, none may be auto-resolved:

1. **Task body is already in place** at `.e2e-engineering/tasks/<id>/` — pre-impl wrote prd.json + every artifact there directly (Step 1 set the Task root). Just verify it's complete; do NOT copy/move anything from base `.e2e-engineering/` (there should be nothing there to copy). `<id>` was fixed at Step 1.
2. **Append to [queue.json](./schemas/queue.json.md)** — entry `{ id, title, priority, dependsOn, status:todo, selected:false, parentTask:null }`. Ask the human for `priority` and any cross-Task `dependsOn` (camelCase — distinct from story-level `depends_on`). This skill is the queue's CREATE writer; flight only flips `status`. **New Tasks are born `selected:false`** — selection happens only at the explicit checkbox in step 3, never by default.
3. **Batch or launch?** Ask: *"Spec another feature, or launch flight now?"* — and STOP for the answer.
   - **Another** → loop back to Pre-implementation for the next feature — establish a NEW Task root (`tasks/<new-id>/`) first, then map-codebase? → grill-with-docs …. The queue grows. State this clearly so the human can stack a backlog before launching.
   - **Launch** → **Run-selection checkbox (HARD interactive STOP).** Present every `status:todo` Task with priority + dependsOn as an unchecked checklist and ASK the human which to drain THIS flight. **Do NOT pre-check all, do NOT assume "all", do NOT launch until the human returns a checked subset.** Only auto-additions allowed: an unmet `dependsOn` of a checked Task (warn: "billing-export needs auth-login — adding it"). Set `selected:true` ONLY on the human-chosen set (+ pulled-in deps). If the human checks nothing, do not launch.
4. **Invoke [/e2e-flight](../e2e-flight/SKILL.md)** — once, for the whole selected set (never per-Task; that would spawn multiple drivers). Flight's Step 0 [E2E_DRIVER guard] self-bootstraps the [AFK wrapper](../../../scripts/afk.ps1) in a VISIBLE window (it refuses to launch a second if one is already running) and exits. This skill does NOT touch afk.ps1 directly. Tell the human: "Flight draining N Tasks in a new window — watch progress there, in `.e2e-engineering/flight.log`, or `.e2e-engineering/flight-status.md`. You're free to step away; run `/e2e-engineering` later to QA-sign-off."

Each flight spawn is a fresh context (the external equivalent of the gate-1 unconditional reset — ADR 0014/0015): pre-impl grilling never contaminates the impl loop because the impl loop runs in separate driver-spawned processes.

---

## Implementation phase

Entry: PRD approved (gate 1 passed). **In multi-Task mode this phase runs inside [/e2e-flight](../e2e-flight/SKILL.md)** (driver-spawned, headless), scoped to the current Task's `tasks/<id>/`. The description below is canonical — flight reuses it verbatim per Task. Single-Task legacy mode may still run it inline here.

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
4. **Checkpoint** if context ≥ 65% (see Cross-cutting). Then loop.

### After COMPLETE

**Before GATE 4 (65% in-phase net):** Check context. If ≥ 65%, write handoff + flush prd.json + progress.txt + end session per [context-checkpoint](./cross/context-checkpoint.md). Do not start the regression suite in a saturated context. (This is the threshold net, not a phase-boundary reset — the long impl loop may saturate before reaching gate 4.)

4. [e2e-loop](./impl/e2e-loop.md) — FINAL pass. Automate the REGRESSION (cross-slice) test-cases now that the whole feature exists. Run the full accumulated suite.
   - **HARD GATE 4 — E2E suite green → post-implementation.** Full suite must pass.

**→ UNCONDITIONAL gate reset (after GATE 4, before GATE 5).** Flush prd.json + progress.txt, write handoff + end session per [context-checkpoint](./cross/context-checkpoint.md) — regardless of context %. Verification starts fresh. Rationale: gate 4 just ran the full regression suite (high token cost) and Playwright verification ahead is the highest-token-growth phase (BR-PLAYWRIGHT-01); a guaranteed clean break here is worth the re-bootstrap.

5. [verification](./impl/verification.md) — gate 5.
   - **HARD GATE 5 — verification-before-completion.** Full suite re-run (all tests) + live exercise via `/run` + `/verify` + every PRD acceptance criterion ticked. Passing = implementation done.

**→ UNCONDITIONAL gate reset (after GATE 5).** Checkpoint + end session per [context-checkpoint](./cross/context-checkpoint.md) — regardless of context %. Post-implementation starts fresh. This feeds the fresh-context review naturally: review.md already requires a clean reviewer with no impl-loop baggage.

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
| 4 | E2E suite green → post-impl | HARD | e2e-loop |
| 5 | verify-before-completion | HARD | verification |
| — | coverage / lint / style | SOFT | overridable WITH logged justification; silent skip not allowed |

Hard gates need explicit human consent and surface as a red-flags line in their sub-skill. Never rationalize past a hard gate.

---

## Cross-cutting

- **Checkpoint at 65% context** — [context-checkpoint](./cross/context-checkpoint.md): write handoff doc + prd.json + progress.txt (caveman:ultra), then end the session.
- **Unconditional gate reset (gates 1, 4, 5)** — after each PHASE-BOUNDARY hard gate passes, checkpoint + end session REGARDLESS of context % (gate 1 = pre-impl→impl; gate 4 = before verification; gate 5 = impl→post-impl). Each phase starts in a fresh session — no cross-phase context contamination, deterministic. Gates 2/3 are per-slice/subagent-internal and DO NOT reset. See ADR 0014.
- **65% in-phase net** — independent of the gate resets: within any phase, if context hits 65% mid-loop, checkpoint at the next fan-in boundary (the long impl loop may saturate before reaching gate 4). The gate resets are unconditional; the 65% net is the threshold safety valve between gates.
- **Phase transition / fresh-session resume** — [phase-transition](./cross/phase-transition.md): read handoff → prd.json → progress.txt → invoke suggested skill. Do NOT read CONTEXT.md first (handoff carries a language summary; pull glossary on demand).
- **ARCHITECTURE.md governance** — durable project-architecture map (schema: [architecture](./schemas/architecture.md)). Written ONLY in human phases: seeded/drafted in pre-impl (adopt, map-codebase, to-prd — human-reviewed) and amended at the post-impl human-QA gate. The automated implementation loop is READ-ONLY for it (to-issues pins from it, fan-out injects a scoped slice, quality-check checks against it). A subagent that spots architectural drift PROPOSES it in its summary; the orchestrator stages it as a `## Pending Amendment` — never edits ARCHITECTURE.md mid-loop. Same blast radius as the constitution (it shapes every future subagent), so same human-gated governance. See ADR 0013.
- **Writing style:** generated state artifacts (progress.txt, handoff) = caveman:ultra. User-facing conversation = caveman:full. Code, commits, PRs = normal prose.
