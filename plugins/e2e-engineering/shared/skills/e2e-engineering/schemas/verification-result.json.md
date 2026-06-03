# Schema — verification-result.json

Evidence sidecar for GATE 5 (verification-before-completion). **STUBBED — pending automation.** Schema defined now; not yet written during flight. Lives at `tasks/<task-id>/manifests/<story-id>/verification-result.json` (or `manifests/_task/verification-result.json` for task-level verification).

```json
{
  "scope": "story-id | _task — story-scoped or task-level verification",
  "status": "passed | failed | stubbed",
  "checklist": [
    {
      "criterion": "string — acceptance criteria text",
      "verified": "boolean",
      "method": "automated | manual | self-review"
    }
  ],
  "notes": "string — caveman-ultra; gaps or deferred items"
}
```

## Invariants
- **Currently stubbed.** GATE 5 not automated. `status: stubbed` expected until Gate 5 implemented. Schema pinned now to avoid drift when automation lands.
- `scope: _task` = task-level cross-slice verification (post-DAG-drain). `scope: <story-id>` = per-slice (future).
- When automation lands: orchestrator writes this file at Gate 5; updates prd.json with `verificationManifestPath`.
- `checklist[]` maps 1:1 to PRD `acceptanceCriteria[]` for traceability.
