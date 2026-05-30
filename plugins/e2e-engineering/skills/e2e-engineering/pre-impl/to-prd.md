# to-prd — formal PRD → prd.json

Converts grill-with-docs notes (+ research / prototype / codebase-map findings) into the formal PRD and writes `prd.json` at the **Task root** (`.e2e-engineering/tasks/<id>/` in multi-Task mode, `.e2e-engineering/` single-Task legacy — established in SKILL.md Step 1). Write it THERE directly; never to base `.e2e-engineering/` then copy. Owns its OWN interview step — fill gaps directly, no double-interview with grill-with-docs. Provenance: mattpocock to-prd. Schema: [prd.json](../schemas/prd.json.md).

## What to do
1. Synthesize grill-with-docs notes + any research.md / prototype conclusions / codebase-map (sections 1-4) into a coherent product spec.
2. Interview ONLY to close remaining gaps (don't re-ask what grill-with-docs settled).
3. Write `prd.json`: task-level fields + `stories[]`. Set `taskType`, `baseBranch`.
4. For each story: id, title, description, `acceptanceCriteria[]`, `priority`, `sliceType` (tracer|schema|logic|api|ui), `depends_on` (leave for to-issues to finalize the DAG, or seed obvious edges), `status: todo`, `testCases: []` (to-issues authors these), notes.
5. **Testing-decisions** — capture, per story, what behaviors must be verified and their shape (feature = story-level journey, regression = cross-slice journey). These become the test-case `.md` docs that [to-issues](../impl/to-issues.md) authors and attaches.

## Refactor-shaped stories (taskType: refactor)
Do NOT force `As a user…`. A refactor story = **behavior-preservation statement + structural goal**. Capture old-code transformation (modified OR removed) as explicit acceptance criteria + migration-step ordering (introduce new → migrate callers → modify/remove old). e2e is the safety net — mandatory. See ADR 0012.

## Exit → HARD GATE 1
Present the PRD to the user. Require EXPLICIT consent before implementation. Do not proceed on silence. This is the highest-fidelity gate — refactors and features alike are high blast radius.

## Red flags (stop)
- Re-interviewing on questions grill-with-docs already resolved.
- Writing implementation detail into the PRD (PRD = what + acceptance, not how).
- Proceeding to implementation without explicit human approval.
- Omitting testing-decisions (downstream test-cases have nothing to derive from).
