# to-issues — PRD → vertical slices + DAG + test-cases

Splits the PRD into vertical slices, emits the `depends_on` DAG, authors test-case `.md` docs upfront, attaches `testCases[]` per story. Output is born `ready-for-agent` and SKIPS triage. Provenance: mattpocock to-issues + spec_kit DAG fan-out.

## What to do
0. **Pin integration (brownfield, if ARCHITECTURE.md exists).** Before slicing, read `ARCHITECTURE.md` sections 1-2 (layering + ownership rules). For each story, decide WHICH existing owner/seam it extends and record it in the story's `integration` field in prd.json (e.g. "extend EnrollmentResource — completion endpoints, no new class"). This is the one place the brownfield ownership decision is made — once, against the durable map — so N parallel subagents don't each guess it differently. No ARCHITECTURE.md → skip; fan-out + quality-check still apply what map-codebase surfaced.
1. **Slice** each PRD story into vertical slices ordered tracer → schema → logic → api → ui. A slice is shippable end-to-end through its layer, not a horizontal layer.
2. **Build the DAG** — express the ordering as `depends_on` edges, NOT a fixed per-iteration count. Each feature stays sequential along its chain (tracer before schema before logic…); independent features/branches have no edge between them so they fan out in parallel. Set `sliceType` per story.
3. **Author test-cases UPFRONT** from the PRD testing-decisions. One `.md` per behavior in `<Task root>/test-cases/` (`.e2e-engineering/tasks/<id>/test-cases/` multi-Task, `.e2e-engineering/test-cases/` single-Task legacy) — alongside this Task's prd.json, never at base when a Task root exists. Two shapes:
   - **feature** — story-level journey. Automated IN-SLICE by the slice subagent.
   - **regression** — app-wide journey spanning stories. Automated by the FINAL [e2e-loop](./e2e-loop.md) pass.
4. **Attach** — set each story's `testCases[]` to the ids of the cases it must satisfy. Each case is Automated (an E2E exists/will exist) or Manual (human walks it → human-QA script).
5. Set every story `status: todo`. These are born `ready-for-agent` — they do NOT pass through triage.

## Test-case `.md` format
```markdown
# TC-<id> — <behavior>  (shape: feature | regression)

## Preconditions
## Steps
1. <real-interface action: UI click / HTTP call — not internal poking>
## Expected
<observable outcome>

Disposition: Automated | Manual
Maps to story: <story-id>
```

## DAG correctness matters
Ralph flagged missing inter-story dependencies as a real gap. A wrong DAG = wrong ready set = broken parallelism or out-of-order builds. Verify: does every story whose work depends on another's output have that edge?

## Same-file collision (serialize when unsure)
Two stories with no `depends_on` edge land in the same ready set and fan out to parallel worktrees. If both write the SAME file (component, resource class, API-client block, i18n file), their branches diverge and the merge duplicates or clobbers — this is the failure that produced two `LessonSidebar`s and a duplicate `api.student` block. Estimate file overlap from blast-radius (codebase-map §1) + slice type (two ui slices on one page; two api slices on one resource). Overlap likely OR uncertain → add a `depends_on` edge to serialize them (safe default). Parallel is safe ONLY across disjoint file sets. This is a heuristic, not a guarantee — residual misses are caught by the fan-in merge-readiness check + merge conflict.

## Red flags (stop)
- Horizontal slices (a "schema for everything" story) instead of vertical ones.
- Emitting stories with no DAG edges when real dependencies exist.
- Skipping upfront test-cases (slices then have no testCases[] to satisfy).
- Routing forward-flow slices through triage (they're born ready-for-agent).
- Leaving two file-overlapping stories edge-free in the same ready set (serialize them).
- Skipping the `integration` pin when ARCHITECTURE.md exists (subagents then re-guess ownership).
