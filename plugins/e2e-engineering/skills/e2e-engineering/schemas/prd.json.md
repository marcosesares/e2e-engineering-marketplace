# Schema — prd.json

Structured state for one Task. Written and owned by orchestrator (sole writer). New task → overwrite fresh. Lives at **Task root**: `.e2e-engineering/tasks/<id>/prd.json` multi-Task, `.e2e-engineering/prd.json` single-Task legacy. Written there directly — never base-then-copy.

```json
{
  "project": "string — repo/product name",
  "description": "string — one-paragraph intent of THIS task",
  "taskType": "greenfield | feature | bugfix | refactor",
  "baseBranch": "string — branch slices fork from and merge back into",
  "stories": [
    {
      "id": "string — stable slug, referenced by depends_on and testCases",
      "title": "string",
      "description": "string — refactor-shaped allowed (behavior-preservation + structural goal), not forced 'As a user…'",
      "acceptanceCriteria": ["string", "..."],
      "priority": "number — lower = sooner within ready set",
      "sliceType": "tracer | schema | logic | api | ui",
      "depends_on": ["story-id", "..."],
      "status": "todo | done | blocked",
      "branch": "string — worktree branch for this slice",
      "testCases": ["test-case-id", "..."],
      "integration": "string — brownfield ownership/seam decision pinned by to-issues from ARCHITECTURE.md §1–§2. e.g. 'extend EnrollmentResource — completion endpoints, no new class'. Empty for greenfield / no ARCHITECTURE.md. Injected into slice sub-agent at fan-out.",
      "notes": "string — free, e.g. blocked reason, gap-check escalation"
    }
  ]
}
```

## Invariants
- **COMPLETE** = every story `status: "done"`. (Replaces Ralph's `passes: true`.)
- `status` enum: exactly three values. `blocked` only after debug escalation (3 strikes + systematic-debugging failed).
- `depends_on` edges encode tracer→schema→logic→api→ui ordering. Each feature sequential along chain; independent chains parallel.
- **Ready set** = stories whose `depends_on` all `done` AND own `status` is `todo`.
- Sub-agents NEVER write this file. Return summary; orchestrator writes `status` at fan-in.
- `testCases[]` ids point at `.md` test-case docs authored upfront by to-issues.
- `integration` set by to-issues (reading ARCHITECTURE.md §1–§2 via §Index offset/limit), not by sub-agent. Single place brownfield ownership decided — once, by orchestrator. See ADR 0013.
